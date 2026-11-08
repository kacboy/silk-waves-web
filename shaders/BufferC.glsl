// Silk Waves (Shadertoy port), Buffer C. MIT License; notice in Common.
vec4 ribbon_vertex(int along, int line) { return texelFetch(iChannel0, ivec2(along, line), 0); }
vec4 crossing(int line, float x, int n) {
    int found = 0;
    vec4 a = ribbon_vertex(0, line);
    for (int i = 0; i < 127; ++i) {
        vec4 b = ribbon_vertex(i + 1, line);
        if ((a.x <= x) != (b.x <= x)) {
            if (found == n) {
                float t = (x - a.x) / (b.x - a.x);
                vec4 c = mix(a, b, t);
                return vec4(c.y, c.z, c.w, float(i) + t);
            }
            ++found;
        }
        a = b;
    }
    return vec4(-1e9, 0.0, 0.0, -1.0);
}
vec4 group_bounds(int g, float x) {
    vec2 bounds = vec2(1e9, -1e9);
    for (int line = 16 * g; line <= min(16 * g + 16, 127); ++line) {
        vec4 a = ribbon_vertex(0, line);
        for (int i = 0; i < 127; ++i) {
            vec4 b = ribbon_vertex(i + 1, line);
            if ((a.x <= x) != (b.x <= x)) {
                float y = mix(a.y, b.y, (x - a.x) / (b.x - a.x));
                bounds = vec2(min(bounds.x, y), max(bounds.y, y));
            }
            a = b;
        }
    }
    return vec4(bounds, 0.0, 0.0);
}
vec4 tile_flakes(ivec2 tile, int k, int size) {
    vec4 ids = vec4(-1.0);
    vec4 box = vec4(vec2(tile * size), vec2(tile * size + size));
    int found = 0;
    for (int id = 0; id < 2048; ++id) {
        vec4 rect = texelFetch(iChannel0, flake_texel(id, 0), 0);
        if (rect.x <= box.z && rect.z >= box.x && rect.y <= box.w && rect.w >= box.y) {
            int n = found - 4 * k;
            if (n >= 0) ids[n] = float(id);
            if (++found >= 4 * k + 4) break;
        }
    }
    return ids;
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    ivec2 texel = ivec2(fragCoord);
    int slots = crossing_slots(iResolution.xy), bins = bin_row(iResolution.xy);
    int size = tile_size(iResolution.xy);
    ivec2 tiles = (ivec2(iResolution.xy) + size - 1) / size;
    fragColor = vec4(0.0);
    if (texel.y < 128 * slots)
        fragColor = crossing(texel.y / slots, fragCoord.x, texel.y % slots);
    else if (texel.y < bins)
        fragColor = group_bounds(texel.y - 128 * slots, fragCoord.x);
    else if (texel.y < bins + tiles.y && texel.x < tiles.x * kBinTexels)
        fragColor = tile_flakes(ivec2(texel.x / kBinTexels, texel.y - bins), texel.x % kBinTexels, size);
}
