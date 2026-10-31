---
name: conventional-commits
description: Write commit messages, PR titles, and PR descriptions that follow Conventional Commits 1.0.0. Use whenever creating a git commit or opening or editing a pull request, in any repository.
---

# Conventional Commits

Follow https://www.conventionalcommits.org/en/v1.0.0/ for every commit and PR.

## Format

```
<type>[(scope)][!]: <description>

[body]

[footers]
```

- **type**: one of the list below, in lowercase.
- **scope**: optional noun for the affected area, such as `feat(nvim):`. Reuse scopes from `git log`.
- **description**: imperative mood, lowercase start, no trailing period.
- **body**: optional, one blank line after the subject. Explain what and why, not how.
- **footers**: optional, one blank line after the body, as `Token: value`. Spell a breaking change footer exactly `BREAKING CHANGE:`.

| Type | Use for | Version bump |
| --- | --- | --- |
| `feat` | New user-facing capability | minor |
| `fix` | Bug fix | patch |
| `docs` | Documentation only | none |
| `style` | Formatting with no behaviour change | none |
| `refactor` | Code change that is neither a fix nor a feature | none |
| `perf` | Performance improvement | none |
| `test` | Adding or correcting tests | none |
| `build` | Build system or dependencies | none |
| `ci` | CI configuration | none |
| `chore` | Maintenance that fits nothing above | none |
| `revert` | Reverts an earlier commit | none |

Mark any breaking change with `!` after the type or scope, a `BREAKING CHANGE:` footer, or both. It is a major bump whatever the type.

## Commits

1. Read the staged diff and recent `git log`, then pick the type by what the change does for the user, not by which files it touches.
2. Split unrelated changes into separate commits. If a commit needs two types, it is two commits.
3. Never bypass the check with `--no-verify`. If the `commit-msg` hook rejects a message, fix the message.

## Pull requests

- Write the title in the same format as a commit subject. Squash merges use it as the commit message, and CI checks it.
- Fill in the repo's `.github/pull_request_template.md` if it has one. Otherwise, the body covers what changed, why, and any breaking changes.
