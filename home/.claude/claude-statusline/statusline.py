#!/usr/bin/env python3
"""Claude Code statusline script.

Reads JSON session data from stdin, displays a two-line status bar:
  Line 1: [Model] ▓▓▓▓░░░░░░ 42% | 😌 Chill | 📁  dir | 🌿  main +2 ~3 ?1
  Line 2: 15.2K in / 3.1K out | $0.42 (llm gateway) | ⏱️  3h 49m

Mood indicator (opt-in via CLAUDE_STATUSLINE_MOOD=true env var) shows session health
based on token-per-minute rate, duration, and context usage.

Uses gateway-reported cost (cost.total_cost_usd) and cumulative token counts.
Shows $0.00 at session start (before any API calls). Shows [no cost data] in red
if tokens are flowing but cost is not reported.

Git: branch, staged, modified, and untracked counts cached per-directory with 5s TTL.
Git caches stored under /tmp/claude-statusline/, auto-cleaned after 7 days.
"""

import hashlib
import json
import os
import random
import select
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import NamedTuple, Optional

CACHE_DIR = Path("/tmp/claude-statusline")
GIT_CACHE_DIR = CACHE_DIR / "git"
GIT_CACHE_MAX_AGE = 5
STALE_FILE_MAX_AGE = 7 * 24 * 60 * 60  # 7 days in seconds
GIT_TIMEOUT = 2  # seconds
STDIN_TIMEOUT = 5  # seconds

CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
DIM = "\033[2m"
RESET = "\033[0m"


class GitInfo(NamedTuple):
    branch: Optional[str]
    staged: int
    modified: int
    untracked: int


NO_GIT = GitInfo(branch=None, staged=0, modified=0, untracked=0)


def _deep_get(data, *keys, default=0):
    """Traverse nested dicts, returning default if any key is missing or None."""
    for key in keys:
        if not isinstance(data, dict):
            return default
        data = data.get(key)
        if data is None:
            return default
    return data


def _atomic_write(path, content):
    """Write content to path atomically via temp file + rename.

    On failure, cleans up the temp file silently. Callers should treat
    write failures as non-fatal (the statusline still renders, just
    without persisted state for that invocation).
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = None
    try:
        fd, tmp = tempfile.mkstemp(dir=path.parent, suffix=".tmp")
        tmp_path = Path(tmp)
        with open(fd, "w") as f:
            f.write(content)
        tmp_path.rename(path)
    except OSError:
        if tmp_path:
            try:
                tmp_path.unlink()
            except OSError:
                pass


def format_tokens(count):
    """Format token count: 523, 15.2K, 1.2M. Returns dim '-' for zero."""
    if not count:
        return f"{DIM}-{RESET}"
    if count < 1_000:
        return str(count)
    if count < 1_000_000:
        return f"{count / 1_000:.1f}K"
    return f"{count / 1_000_000:.1f}M"


def format_duration(duration_ms):
    """Format milliseconds as human-readable duration: 45s, 3m 12s, 2h 15m."""
    total_secs = duration_ms // 1_000
    hours, remainder = divmod(total_secs, 3_600)
    mins, secs = divmod(remainder, 60)
    if hours:
        return f"⏱️  {hours}h {mins}m"
    return f"⏱️  {mins}m {secs}s"


def bar_colour(pct):
    """Return ANSI colour based on context usage percentage."""
    if pct >= 90:
        return RED
    if pct >= 70:
        return YELLOW
    return GREEN


def get_mood(duration_ms, total_in, total_out, context_pct):
    """Derive Claude's mood from token rate, duration, and context usage.

    Opt-in via CLAUDE_STATUSLINE_MOOD=true env var. Uses tokens-per-minute as
    a proxy for activity — a long session with low token rate means the user is
    likely away (idle), while high rate + high duration + high context means
    the session is under pressure.
    """
    duration_min = max(duration_ms / 60_000, 0.1)
    total_tokens = total_in + total_out
    tokens_per_min = total_tokens / duration_min

    if context_pct >= 90:
        return "\U0001f975 Cooked"
    if duration_min > 10 and tokens_per_min < 50:
        return "\U0001f4a4 Idle"
    if context_pct >= 70 and duration_min > 60:
        return "\U0001f624 Grinding"
    if duration_min > 120 and tokens_per_min > 200:
        return "\U0001f975 Cooked"
    if duration_min > 60 and tokens_per_min > 200:
        return "\U0001f624 Grinding"
    if duration_min > 20 and tokens_per_min > 500:
        return "\U0001f525 Cooking"
    if duration_min > 10:
        return "\U0001f9e0 Focused"
    return "\U0001f60c Chill"


def get_session_data(data):
    """Read gateway-reported cost and cumulative token counts.

    Returns (total_in, total_out, cost_str).
    """
    gateway_cost = _deep_get(data, "cost", "total_cost_usd")
    total_in = _deep_get(data, "context_window", "total_input_tokens")
    total_out = _deep_get(data, "context_window", "total_output_tokens")

    if gateway_cost > 0:
        cost_str = f"{GREEN}${gateway_cost:.2f} (llm gateway){RESET}"
    elif total_in > 0 or total_out > 0:
        cost_str = f"{RED}[no cost data]{RESET}"
    else:
        cost_str = f"{GREEN}$0.00 (llm gateway){RESET}"

    return total_in, total_out, cost_str


def _cleanup_stale_files():
    """Remove stale git cache files older than 7 days.

    Only runs ~1 in 50 invocations to avoid unnecessary I/O on every render.
    """
    if random.randint(1, 50) != 1:
        return
    try:
        if not GIT_CACHE_DIR.exists():
            return
        now = time.time()
        for f in GIT_CACHE_DIR.iterdir():
            if f.suffix == ".cache" and (now - f.stat().st_mtime) > STALE_FILE_MAX_AGE:
                f.unlink(missing_ok=True)
    except OSError:
        pass


def _run_git(*args, cwd=None):
    """Run a git command, return stdout or empty string on failure."""
    try:
        return subprocess.check_output(
            ["git", *args], stderr=subprocess.DEVNULL, text=True,
            timeout=GIT_TIMEOUT, cwd=cwd,
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        return ""


def _git_cache_file(cwd):
    """Return a per-directory git cache file path using a hash of the full path."""
    dir_hash = hashlib.sha256(cwd.encode()).hexdigest()[:16]
    return GIT_CACHE_DIR / f"{dir_hash}.cache"


def _refresh_git_cache(cache_file, cwd):
    """Run git commands and write results to cache file."""
    if not _run_git("rev-parse", "--git-dir", cwd=cwd):
        _atomic_write(cache_file, "|||")
        return

    branch = _run_git("branch", "--show-current", cwd=cwd) or _run_git("rev-parse", "--short", "HEAD", cwd=cwd)
    staged_out = _run_git("diff", "--cached", "--numstat", cwd=cwd)
    modified_out = _run_git("diff", "--numstat", cwd=cwd)
    untracked_out = _run_git("ls-files", "--others", "--exclude-standard", cwd=cwd)
    staged = len(staged_out.splitlines()) if staged_out else 0
    modified = len(modified_out.splitlines()) if modified_out else 0
    untracked = len(untracked_out.splitlines()) if untracked_out else 0

    _atomic_write(cache_file, f"{branch}|{staged}|{modified}|{untracked}")


def get_git_info(cwd):
    """Get git branch, staged, modified, untracked counts with caching."""
    cache_file = _git_cache_file(cwd)
    try:
        if not cache_file.exists() or (time.time() - cache_file.stat().st_mtime) > GIT_CACHE_MAX_AGE:
            _refresh_git_cache(cache_file, cwd)

        parts = cache_file.read_text().strip().split("|")
        if len(parts) != 4 or not parts[0]:
            return NO_GIT
        return GitInfo(parts[0], int(parts[1]), int(parts[2]), int(parts[3]))
    except (OSError, ValueError):
        return NO_GIT


def format_git(cwd):
    """Format git info for display."""
    info = get_git_info(cwd)
    if info.branch is None:
        return ""

    if not info.staged and not info.modified and not info.untracked:
        return f"🌿  {info.branch} {GREEN}✓{RESET}"

    parts = [f"🌿  {info.branch}"]
    if info.staged:
        parts.append(f"{GREEN}+{info.staged}{RESET}")
    if info.modified:
        parts.append(f"{YELLOW}~{info.modified}{RESET}")
    if info.untracked:
        parts.append(f"{RED}?{info.untracked}{RESET}")
    return " ".join(parts)


def _read_stdin():
    """Read all of stdin with a timeout. Returns the data or empty string.

    Uses os.read on the raw file descriptor with select to avoid blocking
    indefinitely if the parent process doesn't close stdin promptly.
    """
    fd = sys.stdin.fileno()
    chunks = []
    while select.select([fd], [], [], STDIN_TIMEOUT)[0]:
        chunk = os.read(fd, 65536)
        if not chunk:
            break
        chunks.append(chunk)
    return b"".join(chunks).decode()


def main():
    raw = _read_stdin()
    if not raw:
        return

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        print("[statusline: invalid input]")
        return

    model = _deep_get(data, "model", "display_name", default="?")
    pct = int(_deep_get(data, "context_window", "used_percentage") or 0)
    cwd = _deep_get(data, "workspace", "current_dir", default="")

    bar_width = 10
    filled = pct * bar_width // 100
    colour = bar_colour(pct)
    bar = f"{colour}{'▓' * filled}{'░' * (bar_width - filled)}{RESET}"

    directory = Path(cwd).name if cwd else ""
    git_str = format_git(cwd) if cwd else ""
    total_in, total_out, cost_str = get_session_data(data)
    duration_ms = _deep_get(data, "cost", "total_duration_ms")

    line1_parts = [f"{CYAN}[{model}]{RESET} {bar} {pct}%"]
    if os.environ.get("CLAUDE_STATUSLINE_MOOD", "").lower() in ("1", "true"):
        line1_parts.append(get_mood(duration_ms, total_in, total_out, pct))
    if directory:
        line1_parts.append(f"📁  {directory}")
    if git_str:
        line1_parts.append(git_str)

    line2_parts = [
        f"{format_tokens(total_in)} in / {format_tokens(total_out)} out",
        cost_str,
        format_duration(duration_ms),
    ]

    print(" | ".join(line1_parts))
    print(" | ".join(line2_parts))

    _cleanup_stale_files()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        print(f"{RED}[statusline error]{RESET}")