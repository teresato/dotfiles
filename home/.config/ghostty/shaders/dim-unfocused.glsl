// Dim unfocused windows so the focused one is obvious at a glance.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 color = texture(iChannel0, uv);

    if (iFocus == 0) {
        float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
        color.rgb = mix(vec3(luma), color.rgb, 0.25) * 0.45;
        color *= 0.775; // 0.8 -> 0.62 window opacity
    }

    fragColor = color;
}
