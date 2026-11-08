// Silk Waves (Shadertoy port), Image. MIT License; notice in Common.
vec3 glow(vec2 uv, ivec2 size) {
    vec2 texel = 1.0 / vec2(size), region = vec2(size) / iResolution.xy;
    vec3 near = vec3(0.0), far = vec3(0.0);
    for (int i = 0; i < 9; ++i) {
        vec2 offset = i == 0 ? vec2(0.0)
                    : i < 5 ? vec2((i & 1) != 0 ? 1.06 : -1.06, (i & 2) != 0 ? 1.06 : -1.06)
                    : vec2(i == 5 ? 4.0 : i == 6 ? -4.0 : 0.0, i == 7 ? 4.0 : i == 8 ? -4.0 : 0.0);
        vec2 tap = clamp(uv + offset * texel, 0.5 * texel, 1.0 - 0.5 * texel);
        vec3 v = texture(iChannel3, vec2(tap.x, 1.0 - tap.y) * region).yzw;
        if (i < 5) near += v; else far += v;
    }
    return near * 0.25 + far * 0.1;
}
vec3 flake(int id, vec3 ray) {
    vec4 place = texelFetch(iChannel1, flake_texel(id, 1), 0);
    vec4 normal = texelFetch(iChannel1, flake_texel(id, 3), 0);
    vec4 halo = texelFetch(iChannel1, flake_texel(id, 4), 0);
    vec3 p = place.xyz, colour = vec3(0.0);
    if (normal.w > 0.0) {
        vec4 turned = texelFetch(iChannel1, flake_texel(id, 2), 0);
        vec3 n = rotate(turned, vec3(0.0, 0.0, 1.0));
        float facing = dot(ray, n);
        if (abs(facing) > 1e-9) {
            vec3 hit = kEye + ray * (dot(p - kEye, n) / facing) - p;
            vec2 uv = vec2(dot(hit, rotate(turned, vec3(1.0, 0.0, 0.0))), dot(hit, rotate(turned, vec3(0.0, 1.0, 0.0)))) / place.w + 0.5;
            if (all(greaterThanEqual(uv, vec2(0.0))) && all(lessThan(uv, vec2(1.0)))) {
                vec2 disc_ = texelFetch(iChannel1, flake_texel(id, 5), 0).xy;
                float r = length(uv * 2.0 - 1.0);
                float width = 0.05 + 0.63 * disc_.x;
                float t = clamp((r - 0.5 + width) / (2.0 * width), 0.0, 1.0);
                float disc = 1.0 - t * t * (3.0 - 2.0 * t);
                float profile = mix(disc, 1.0 - exp(-disc_.y * disc), disc_.x);
                vec3 point = hit + p, face = normalize(normal.xyz), lamp = normalize(kLamp - point);
                float highlight = pow(abs(dot(face, normalize(lamp + normalize(kEye - point)))), 35.0);
                vec3 light = abs(dot(face, lamp)) * 8.0 + highlight * 75.0 * film_tint(face);
                colour += profile * normal.w * (1.0 - exp(-0.039 * light));
            }
        }
    }
    if (halo.w > 0.0) {
        vec2 uv = ((kEye + ray * ((p.z - kEye.z) / ray.z)).xy - p.xy) / halo.w + 0.5;
        if (all(greaterThanEqual(uv, vec2(0.0))) && all(lessThan(uv, vec2(1.0))))
            colour += halo.rgb * exp(-4.4 * min(length(uv * 2.0 - 1.0), 1.0));
    }
    return colour;
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 pixel = vec2(fragCoord.x, iResolution.y - fragCoord.y), uv = pixel / iResolution.xy;
    Mood m = stored_mood(iChannel0);
    ivec2 size = max((ivec2(iResolution.xy) * 25 + 50) / 100, ivec2(1));
    vec3 radiance = sky(frame_uv(uv, iResolution.xy), m) + texelFetch(iChannel3, ivec2(fragCoord), 0).x;
    vec3 colour = clamp(tone(radiance, m), 0.0, 1.0) + glow(uv, size) * GLARE + (hash4(floor(fragCoord)).x - 0.5) / 255.0;
    ivec2 tile = ivec2(pixel) / tile_size(iResolution.xy);
    int bins = bin_row(iResolution.xy);
    vec3 ray = pixel_ray(pixel, iResolution.xy);
    for (int k = 0; k < kBinTexels; ++k) {
        vec4 ids = texelFetch(iChannel2, ivec2(tile.x * kBinTexels + k, bins + tile.y), 0);
        if (ids.x < 0.0) break;
        for (int j = 0; j < 4; ++j)
            if (ids[j] >= 0.0)
                colour += flake(int(ids[j]), ray);
    }
    fragColor = vec4(colour, 1.0);
}
