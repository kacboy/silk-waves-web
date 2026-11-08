// Silk Waves (Shadertoy port), Buffer D. MIT License; notice in Common.
vec4 crossing(int line, int slot, int slots, int column) { return texelFetch(iChannel0, ivec2(column, line * slots + slot), 0); }
float strip_light(vec4 a, vec4 b, float y, float strip, Mood m) {
    if (y < min(a.x, b.x) || y >= max(a.x, b.x)) return 0.0;
    float t = (y - a.x) / (b.x - a.x);
    vec4 c = mix(a, b, t);
    return rim(c.w) * rim(strip + t) * (m.brightness * c.y * line_level(c.y) + m.sheen * c.y * sheen_level(c.z));
}
float ribbon_light(vec2 fragCoord, Mood m) {
    int column = int(fragCoord.x), slots = crossing_slots(iResolution.xy);
    float y = iResolution.y - fragCoord.y;
    float light = 0.0;
    for (int g = 0; g < 8; ++g) {
        vec2 bounds = texelFetch(iChannel0, ivec2(column, 128 * slots + g), 0).xy;
        if (y < bounds.x || y > bounds.y) continue;
        for (int strip = 16 * g; strip < min(16 * g + 16, 127); ++strip) {
            vec4 a0 = crossing(strip, 0, slots, column), b0 = crossing(strip + 1, 0, slots, column);
            vec4 a1 = vec4(0.0, 0.0, 0.0, -1.0), b1 = a1;
            if (slots == 2) {
                a1 = crossing(strip, 1, slots, column);
                b1 = crossing(strip + 1, 1, slots, column);
            }
            int na = int(a0.w >= 0.0) + int(a1.w >= 0.0), nb = int(b0.w >= 0.0) + int(b1.w >= 0.0);
            float s = float(strip);
            if (na == nb) {
                if (na >= 1 && abs(a0.w - b0.w) < 16.0) light += strip_light(a0, b0, y, s, m);
                if (na == 2 && abs(a1.w - b1.w) < 16.0) light += strip_light(a1, b1, y, s, m);
            } else if (na == 1 && nb == 2) {
                vec4 b = abs(a0.w - b0.w) <= abs(a0.w - b1.w) ? b0 : b1;
                if (abs(a0.w - b.w) < 16.0) light += strip_light(a0, b, y, s, m);
            } else if (na == 2 && nb == 1) {
                vec4 a = abs(a0.w - b0.w) <= abs(a1.w - b0.w) ? a0 : a1;
                if (abs(a.w - b0.w) < 16.0) light += strip_light(a, b0, y, s, m);
            }
        }
    }
    return light * mix(0.847, 0.925, fragCoord.x / iResolution.x) * WAVES;
}
vec3 glare(vec2 fragCoord, ivec2 size, Mood m) {
    vec2 uv = vec2(fragCoord.x, float(size.y) - fragCoord.y) / vec2(size);
    vec2 texel = 1.0 / iResolution.xy;
    vec3 base = sky(frame_uv(uv, iResolution.xy), m);
    vec3 sum = vec3(0.0);
    for (int y = -2; y <= 1; ++y)
        for (int x = -2; x <= 1; ++x) {
            vec2 tap = uv + (vec2(x, y) * 2.0 + 1.0) * texel;
            float light = texture(iChannel1, vec2(tap.x, 1.0 - tap.y)).x;
            sum += max(tone(base + light, m) - 1.0, 0.0);
        }
    return sum / 16.0;
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    Mood m = stored_mood(iChannel2);
    ivec2 size = max((ivec2(iResolution.xy) * 25 + 50) / 100, ivec2(1));
    fragColor = vec4(ribbon_light(fragCoord, m), 0.0, 0.0, 0.0);
    if (int(fragCoord.x) < size.x && int(fragCoord.y) < size.y)
        fragColor.yzw = glare(fragCoord, size, m);
}
