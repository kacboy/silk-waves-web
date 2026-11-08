// Silk Waves (Shadertoy port), Buffer B. MIT License; notice in Common.
vec4 ribbon_vertex(ivec2 grid) {
    vec2 uv = vec2(grid >> 3) + vec2(grid & 7) * (16.0 / 127.0);
    vec3 p, along, across;
    surface(iChannel0, uv, 38, p, along, across);
    vec4 clip = clip_of(p);
    vec3 scale = vec3(kFocalX, kFocalY, -1.0002);
    vec3 normal = cross(across * scale, along * scale);
    float distance_ = length(clip.xyz);
    float facing = abs(dot(clip.xyz, normal)) / distance_;
    Mood m = stored_mood(iChannel0);
    float k = facing / distance_ * m.density;
    float cosine = facing / max(length(normal), 1e-12);
    vec3 pixel = to_pixel(p, iResolution.xy);
    return vec4(pixel.xy, k, cosine * k);
}
vec4 flake_item(int id, int item) {
    ivec2 slot = ivec2(id & 63, id >> 6);
    vec4 place = texelFetch(iChannel0, slot + ivec2(0, kFlakeRow), 0);
    vec4 motion = texelFetch(iChannel0, slot + ivec2(0, kFlakeRow + 32), 0);
    vec4 q = normalize(texelFetch(iChannel0, slot + ivec2(0, kFlakeRow + 64), 0));
    vec3 p = place.xyz, toward = kEye - p;
    float d = length(toward);
    vec3 eye = toward / d;
    float near_ = clamp((d - kFocus.y) / (kFocus.x - kFocus.y), 0.0, 1.0), far_ = clamp((d - kFocus.z) / (kFocus.w - kFocus.z), 0.0, 1.0);
    float near_blur = pow(near_, 2.5), far_blur = pow(far_, 1.8);
    Mood m = stored_mood(iChannel0);
    float size = mix(mix(m.flake, 0.077, near_blur), 0.87, far_blur);
    float angle = 2.0 * atan(size / d) / 0.925;
    float facing_camera = clamp((d - kFocus.z + 0.4) / 0.2, 0.0, 1.0);
    vec4 turned = normalize(mix(q, vec4(0.0, 0.0, 0.0, 1.0), clamp(angle * 13.2 + near_blur * 0.72 + facing_camera, 0.0, 1.0)));
    vec3 face = rotate(q, vec3(0.0, 0.0, 1.0));
    float age = place.w;
    vec3 edge = clamp(5.0 * min(p - kBoundsLow, kBoundsHigh - p), 0.0, 1.0);
    vec3 fade = edge * edge * (3.0 - 2.0 * edge);
    float shell = 1.0 + clamp((d - kFocus.z + 0.2) / 0.2, 0.0, 1.0) - clamp((d - kFocus.z + 0.6) / 0.2, 0.0, 1.0);
    float common_ = min(age, 0.02) * 50.0 * (1.0 - max(age - 0.94, 0.0) / 0.06) * shell
                  * (1.0 - clamp(far_ * angle * 13.9, 0.0, 1.0)) * (1.0 - clamp(near_ * angle * 6.24, 0.0, 1.0)) * fade.x * fade.y * fade.z;
    float sprite_alpha = (1.0 - pow(clamp(1.0 - abs(dot(eye, rotate(turned, vec3(0.0, 0.0, 1.0)))), 0.0, 1.0), 4.0 / 3.0)) * common_;
    float halo_alpha = (1.0 - pow(clamp(1.0 - abs(eye.z), 0.0, 1.0), 4.0 / 3.0)) * common_;
    float highlight = pow(abs(dot(face, normalize(normalize(kLamp - p) + eye))), 35.0);
    float side = size * kFocalY * output_scale(iResolution.xy).y * 0.5 * iResolution.y / max(d, 0.1);
    float grow = max(2.0 / max(side, 1e-4), 1.0);
    float sprite_size = size * grow, sprite_gain = sprite_alpha / (grow * grow) * GLITTER;
    float halo_size = size * 5.4 * highlight;
    vec3 halo = halo_alpha * (1.0 - exp(-0.039 * highlight * 75.0 * film_tint(face))) * 0.16 * GLITTER;
    bool alive = motion.w != 0.0;
    bool sprite_on = alive && sprite_gain > 0.1 / 255.0, halo_on = alive && max(halo.r, max(halo.g, halo.b)) > 0.1 / 255.0;
    if (item == 1) return vec4(p, sprite_size);
    if (item == 2) return turned;
    if (item == 3) return vec4(face, sprite_on ? sprite_gain : 0.0);
    if (item == 4) return vec4(halo, halo_on ? halo_size : 0.0);
    if (item == 5) return vec4(clamp(near_blur + far_blur, 0.0, 1.0), mix(0.85, 3.8, near_blur), 0.0, 0.0);
    vec4 rect = vec4(1e9, 1e9, -1e9, -1e9);
    vec3 x_axis = rotate(turned, vec3(1.0, 0.0, 0.0)), y_axis = rotate(turned, vec3(0.0, 1.0, 0.0));
    for (int corner = 0; corner < 8; ++corner) {
        vec2 c = vec2(corner & 1, (corner >> 1) & 1) - 0.5;
        bool halo_corner = corner >= 4;
        if (halo_corner ? !halo_on : !sprite_on) continue;
        vec3 point = halo_corner ? p + halo_size * vec3(c, 0.0) : p + sprite_size * (c.x * x_axis + c.y * y_axis);
        vec3 pixel = to_pixel(point - kEye, iResolution.xy);
        if (pixel.z < 0.1) return vec4(1e9, 1e9, -1e9, -1e9);
        rect = vec4(min(rect.xy, pixel.xy), max(rect.zw, pixel.xy));
    }
    return rect;
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    ivec2 texel = ivec2(fragCoord);
    fragColor = vec4(0.0);
    if (texel.x < 128 && texel.y < 128) fragColor = ribbon_vertex(texel);
    else if (texel.x >= kFlakeX && texel.x < kFlakeX + 64 && texel.y < 192)
        fragColor = flake_item((texel.x - kFlakeX) + 64 * (texel.y & 31), texel.y >> 5);
}
