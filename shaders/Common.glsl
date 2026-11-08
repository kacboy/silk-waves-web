// Silk Waves (Shadertoy port), Common.
//
// A silky ribbon and glitter inspired by the PS3 menu background: a simulated cloth ribbon whose folds glow over a
// monthly day or night sky, with spinning flakes that glint. A port of MaiCord's Silk Waves effect
// (https://github.com/maj113/MaiCord-plugins, effects/silk-waves; HOW-IT-WORKS.md there explains the maths).
// Our own implementation, matched against the original by eye and against recordings; no code, data or textures
// from anyone else, and the colours are our own.
// Inspired by linkev's PlayStation-3-XMB (MIT): https://github.com/linkev/PlayStation-3-XMB
//
// MIT License. Copyright (c) 2026 the MaiCord authors.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright
// notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Passes: Buffer A the simulation (cloth and flakes), Buffer B the ribbon's projected vertices and each flake's
// sprite, Buffer C where each ribbon line crosses each pixel column and which flakes touch each 32 px tile, Buffer D
// the ribbon added up per pixel (and a quarter-size glare source), Image the sky, the tone map, the glare and the
// flakes.

// ---- settings ---------------------------------------------------------------------------------------------------
#define MONTH    0     // 0 follows iDate; 1-12 picks a month
#define SKY      0     // 0 follows iDate's clock; 2 always day; 3 always night
#define SPEED    1.0   // wave speed (1: a wave about every 21 s)
#define WAVES    1.0   // wave brightness
#define GLITTER  1.0
#define GLARE    1.0

const float kPi = 3.14159265;

// ---- the clock and the cloth ------------------------------------------------------------------------------------
const float kStep = 2.0e-4, kWrap = 10.0, kFade = 0.0216, kStartClock = 0.8, kStartLag = 0.7982;
const float kRest = 0.306, kTension = 0.25, kDamping = 2.0e-4, kPush = 0.1, kPull = 0.04;
const vec2 kEdge = vec2(0.4, 0.2);
const int kMoodRow = 76, kFlakeRow = 77;

float frame_steps(float delta) { return clamp(delta * 60.0 * SPEED, 0.0, 8.0); }

vec3 driven_edge(int row, float t) {
    float tau = float(row) / 19.0 + t;
    return vec3(0.0, kEdge.x * (0.5 + 0.5 * sin(11.0 * tau)), kEdge.y * 0.5 * (1.0 + cos(15.0 * tau)));
}

// Four values in [0, 1) from a point (a PCG hash, Jarzynski and Olano 2020).
vec4 hash4(vec2 p) {
    uvec4 v = uvec4(floatBitsToUint(p.x), floatBitsToUint(p.y), floatBitsToUint(p.x + p.y), 0x9e3779b9u) * 1664525u + 1013904223u;
    v.x += v.y * v.w; v.y += v.z * v.x; v.z += v.x * v.y; v.w += v.y * v.z;
    v ^= v >> 16u;
    v.x += v.y * v.w; v.y += v.z * v.x; v.z += v.x * v.y; v.w += v.y * v.z;
    return vec4(v >> 8u) * (1.0 / 16777216.0);
}

// ---- the sky palette (ours): per month a day sky (top, bottom) and a night glow -------------------------------------
const vec3 kDaySky[24] = vec3[24](
    vec3(.851, .863, .886), vec3(.663, .682, .722), vec3(.91, .812, .416), vec3(.761, .604, .11),
    vec3(.651, .812, .384), vec3(.369, .604, .173), vec3(.941, .659, .745), vec3(.824, .4, .549),
    vec3(.373, .722, .455), vec3(.122, .478, .227), vec3(.745, .596, .878), vec3(.478, .322, .722),
    vec3(.282, .824, .769), vec3(.059, .549, .549), vec3(.306, .604, .902), vec3(.102, .247, .62),
    vec3(.831, .478, .878), vec3(.557, .173, .643), vec3(.949, .725, .29), vec3(.784, .471, .047),
    vec3(.725, .541, .333), vec3(.431, .29, .133), vec3(.933, .416, .322), vec3(.659, .149, .118));
const vec3 kNightGlow[12] = vec3[12](
    vec3(.353, .376, .439), vec3(.431, .353, .118), vec3(.243, .353, .133), vec3(.478, .267, .345),
    vec3(.118, .333, .188), vec3(.341, .251, .478), vec3(.063, .345, .353), vec3(.078, .243, .502),
    vec3(.369, .102, .431), vec3(.494, .306, .024), vec3(.259, .157, .039), vec3(.431, .118, .094));

vec3 hsv_of(vec3 c) {
    float high = max(c.r, max(c.g, c.b)), low = min(c.r, min(c.g, c.b)), range = high - low;
    float hue = 0.0;
    if (range > 1e-5)
        hue = high == c.r ? (c.g - c.b) / range : high == c.g ? 2.0 + (c.b - c.r) / range : 4.0 + (c.r - c.g) / range;
    return vec3(fract(hue / 6.0), high > 0.0 ? range / high : 0.0, high);
}
vec3 rgb_of(vec3 hsv) {
    vec3 k = clamp(abs(fract(hsv.x + vec3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
    return hsv.z * mix(vec3(1.0), k, hsv.y);
}
vec3 month_mix(vec3 a, vec3 b, float w) {
    vec3 x = hsv_of(a), y = hsv_of(b);
    y.x += roundEven(x.x - y.x);
    vec3 m = mix(x, y, w);
    m.x = fract(m.x);
    return rgb_of(m);
}

// ---- the time of day: four presets (night, dawn, day, dusk) -------------------------------------------------------
struct Mood {
    float sky; vec2 sun; float brightness, sheen, density, exposure, white, turn, flake, flare;
    vec3 scale, top, bottom, glow;
};
const vec4 kBrightness = vec4(0.9, 1.12, 0.7, 1.06), kSheen = vec4(0.52, 0.46, 0.64, 0.5);
const vec4 kDensity = vec4(1.76, 1.87, 1.87, 1.76), kExposure = vec4(1.41, 1.10, 1.05, 1.20);
const vec4 kWhite = vec4(1.0, 1.0, 0.9, 1.0), kTurn = vec4(10.0, 18.1, 18.1, 18.1);
const vec4 kFlakeSize = vec4(0.054, 0.054, 0.047, 0.047), kFlare = vec4(-1.834, -1.34, -1.34, -1.834);
const vec4 kScaleY = vec4(1.2, 1.275, 1.275, 1.2), kScaleZ = vec4(3.0, 2.89, 2.89, 3.0);

// date: iDate (year, month 0-11, day 1-31, seconds since midnight).
Mood mood(vec4 date) {
    Mood m;
    float h = SKY == 2 ? 12.0 : SKY == 3 ? 0.0 : date.w / 3600.0;
    float dawn = smoothstep(1.0, 5.0, h), day = smoothstep(7.0, 11.0, h), dusk = smoothstep(13.0, 17.0, h);
    float night = smoothstep(19.0, 23.0, h);
    vec4 w = vec4(1.0 - dawn + night, dawn * (1.0 - day), day * (1.0 - dusk), dusk * (1.0 - night));
    m.sky = 1.0 - smoothstep(0.0, 5.2, h) * (1.0 - smoothstep(18.5, 20.3, h));
    float x = h / 24.0, hour = 24.0 * (x * x * (3.0 - 2.0 * x) + 2.7 * x * (1.0 - x) * (1.0 - 2.0 * x));
    m.sun = vec2(pow(clamp(sin((hour - 5.5) * kPi / 13.0), 0.0, 1.0), 0.8), (hour - 6.0) / 12.0);
    m.brightness = dot(w, kBrightness);
    m.sheen = dot(w, kSheen);
    m.density = dot(w, kDensity);
    m.exposure = dot(w, kExposure) * 1.006;
    m.white = dot(w, kWhite);
    m.turn = dot(w, kTurn);
    m.flake = dot(w, kFlakeSize);
    m.flare = dot(w, kFlare);
    m.scale = vec3(3.2, dot(w, kScaleY), dot(w, kScaleZ));
    m.top = m.bottom = m.glow = vec3(0.0);
    return m;
}

// One of the month's colours (0 the day sky's top, 1 its bottom, 2 the night glow); from the 5th to the 30th it turns
// slowly toward the next month's.
vec3 month_colour(int which, vec4 date) {
    int month = MONTH - 1;
    float turn = 0.0;
    if (MONTH == 0) {
        month = clamp(int(date.y), 0, 11);
        turn = smoothstep(5.0, 30.0, date.z + date.w / 86400.0);
    }
    int next = month == 11 ? 0 : month + 1;
    vec3 now = which == 2 ? kNightGlow[month] : kDaySky[month * 2 + which];
    vec3 later = which == 2 ? kNightGlow[next] : kDaySky[next * 2 + which];
    return turn > 0.0 ? month_mix(now, later, turn) : now;
}

// Buffer A works the mood out once a frame into row 76 (texels 0-5); every later pass reads it there.
vec4 mood_texel(Mood m, int index, vec4 date) {
    return index == 0 ? vec4(m.brightness, m.sheen, m.density, m.exposure)
         : index == 1 ? vec4(m.white, m.turn, m.flake, m.flare)
         : index == 2 ? vec4(m.scale.yz, m.sky, m.sun.x)
         : vec4(month_colour(min(index, 5) - 3, date), index == 3 ? m.sun.y : 0.0);
}
Mood stored_mood(sampler2D state) {
    vec4 v0 = texelFetch(state, ivec2(0, kMoodRow), 0), v1 = texelFetch(state, ivec2(1, kMoodRow), 0);
    vec4 v2 = texelFetch(state, ivec2(2, kMoodRow), 0), v3 = texelFetch(state, ivec2(3, kMoodRow), 0);
    vec4 v4 = texelFetch(state, ivec2(4, kMoodRow), 0), v5 = texelFetch(state, ivec2(5, kMoodRow), 0);
    Mood m;
    m.brightness = v0.x; m.sheen = v0.y; m.density = v0.z; m.exposure = v0.w;
    m.white = v1.x; m.turn = v1.y; m.flake = v1.z; m.flare = v1.w;
    m.scale = vec3(3.2, v2.xy); m.sky = v2.z; m.sun = vec2(v2.w, v3.w);
    m.top = v3.xyz; m.bottom = v4.xyz; m.glow = v5.xyz;
    return m;
}

// ---- the deformation and the camera -------------------------------------------------------------------------------
const vec3 kBox = vec3(5.677, 1.0, 1.0);
const float kOriginY = -0.47;
const vec3 kAxis = vec3(-0.9942, 0.0868, 0.0654);
const vec3 kOffset = vec3(-8.2, -1.088, -8.4);
const float kFocalY = 2.00569, kFocalX = 2.00569 / (16.0 / 9.0);

vec4 bspline(float t) {
    float s = 1.0 - t, t2 = t * t;
    return vec4(s * s * s, 3.0 * t2 * t - 6.0 * t2 + 4.0, -3.0 * t2 * t + 3.0 * t2 + 3.0 * t + 1.0, t2 * t) / 6.0;
}
vec4 bspline_slope(float t) {
    float s = 1.0 - t;
    return vec4(-s * s, 3.0 * t * t - 4.0 * t, -3.0 * t * t + 2.0 * t + 1.0, t * t) * 0.5;
}
float lattice_height(float u, float T) {
    float bump = u - (sin(0.1 * T) + 0.2) / 1.2;
    return 0.24 * (1.0 + tanh(u - 0.5)) * (3.0 + sin(2.0 * T)) * sin(7.85 * u - 2.5 * T - 1.25)
         + 0.5 * sin(0.25 * T) + exp(-50.0 * bump * bump);
}
vec3 deform(vec3 g, float T, float fade, vec3 scale) {
    vec3 box = (g - vec3(0.0, kOriginY, 0.0)) / kBox;
    vec3 s = clamp(box, 0.0, 0.999) * vec3(8.0, 4.0, 4.0);
    vec3 cell = floor(s);
    vec4 bx = bspline(s.x - cell.x), bz = bspline(s.z - cell.z);
    vec2 ripple = vec2(0.0);
    for (int c = 0; c < 4; ++c) {
        float w = 6.28 * clamp(cell.z + float(c) - 1.0, 0.0, 3.0) * 0.25;
        ripple += bz[c] * sin(vec2(T + 100.0, T) - w) * 0.125;
    }
    vec2 shift = vec2(0.0);
    for (int a = 0; a < 4; ++a) {
        float u = clamp(cell.x + float(a) - 1.0, 0.0, 7.0) * 0.125;
        float height = mix(lattice_height(u, T + 100.0) + ripple.x, lattice_height(u, T) + ripple.y, fade);
        shift += bx[a] * vec2(kBox.x * (1.3 * u * u + 0.2 * u - 0.15), kBox.y * height + kOriginY);
    }
    return (box + vec3(shift, 0.0)) * scale;
}
vec3 control_point(vec3 node, float t, Mood m) {
    float x = node.x - m.flare, u = clamp(x * 0.2, 0.0, 1.0);
    float flare = x < 0.0 ? 0.3 : 1.3 - cos(x * kPi * 0.5) * (1.0 - u * u * (3.0 - 2.0 * u));
    vec3 p = deform(vec3(node.x, node.yz * flare), 10.0 * t, clamp(t / kFade, 0.0, 1.0), m.scale);
    float s = sin(radians(m.turn)), c = cos(radians(m.turn));
    return p * c + cross(kAxis, p) * s + kAxis * dot(kAxis, p) * (1.0 - c) + kOffset;
}

// The bicubic B-spline surface over the control points in `state` (16 x 16 patches; uv in patches): position and the
// two tangents, in camera space; `block` 38 is now, 57 a frame ago.
void surface(sampler2D state, vec2 uv, int block, out vec3 position, out vec3 along, out vec3 across) {
    ivec2 cell = min(ivec2(uv), 15);
    vec2 f = uv - vec2(cell);
    vec4 bu = bspline(f.x), bv = bspline(f.y), du = bspline_slope(f.x), dv = bspline_slope(f.y);
    position = along = across = vec3(0.0);
    for (int a = 0; a < 4; ++a) {
        vec3 row = vec3(0.0), row_slope = vec3(0.0);
        for (int b = 0; b < 4; ++b) {
            vec3 c = texelFetch(state, ivec2(cell.x + b, block + cell.y + a), 0).xyz;
            row += bu[b] * c;
            row_slope += du[b] * c;
        }
        position += bv[a] * row;
        along += bv[a] * row_slope;
        across += dv[a] * row;
    }
}

vec4 clip_of(vec3 p) { return vec4(kFocalX * p.x, kFocalY * p.y, -1.0002 * p.z - 0.2002, -p.z); }
// The 16:9 frame scaled to cover the window.
vec2 output_scale(vec2 res) {
    float stretch = 16.0 / 9.0 * res.y / res.x;
    return stretch >= 1.0 ? vec2(stretch, 1.0) : vec2(1.0, 1.0 / stretch);
}
vec2 frame_uv(vec2 uv, vec2 res) { return 0.5 + (uv - 0.5) / output_scale(res); }
// A camera-space point as a pixel (top-down, as the original's raster) and its depth w.
vec3 to_pixel(vec3 p, vec2 res) {
    vec4 c = clip_of(p);
    vec2 ndc = c.xy * output_scale(res) / c.w;
    return vec3((ndc.x * 0.5 + 0.5) * res.x, (0.5 - 0.5 * ndc.y) * res.y, c.w);
}
// The camera-space direction through a pixel (top-down).
vec3 pixel_ray(vec2 pixel, vec2 res) {
    vec2 ndc = vec2(pixel.x / res.x * 2.0 - 1.0, 1.0 - pixel.y / res.y * 2.0) / output_scale(res);
    return vec3(ndc.x / kFocalX, ndc.y / kFocalY, -1.0);
}

// ---- the sky and the tone map -----------------------------------------------------------------------------------
const float kBlack = 0.061;
vec3 tone(vec3 radiance, Mood m) {
    vec3 x = max(m.exposure * (radiance - kBlack), 0.0);
    return x * (1.0 + x / (m.white * m.white)) / (1.0 + x);
}
vec3 day_sky(vec3 top, vec3 bottom, vec2 uv, vec2 sun) {
    vec3 base = mix(top, bottom, smoothstep(0.0, 1.0, uv.y));
    vec2 spot = vec2(sun.y, 0.75 - 0.5 * sun.x) - uv;
    vec3 shown = min(sun.x * (base + 0.12 * exp(-dot(spot, spot) * 6.0)), 0.98);
    float white2 = 0.9 * 0.9;
    vec3 x = (sqrt((1.0 - shown) * (1.0 - shown) + 4.0 * shown / white2) - (1.0 - shown)) * white2 * 0.5;
    return x / (1.05 * 1.006) + kBlack;
}
vec3 night_sky(vec3 glow, vec2 uv) {
    vec3 bottom = (glow / (1.41 * 1.006) + kBlack) * 0.74;
    return mix(bottom * 0.13, bottom, pow(clamp(uv.y, 0.0, 1.0), 1.35)) * (0.95 + 0.1 * uv.x);
}
// uv: top-down, 0..1 over the 16:9 frame.
vec3 sky(vec2 uv, Mood m) {
    vec3 colour = vec3(0.0);
    if (m.sky < 1.0)
        colour = day_sky(m.top, m.bottom, uv, m.sun) * (1.0 - m.sky);
    if (m.sky > 0.0)
        colour += night_sky(m.glow, uv) * m.sky;
    return colour;
}

// ---- the ribbon's shading ---------------------------------------------------------------------------------------
float line_level(float k) { return k <= 0.375 ? 0.5 - 1.92 * max(k - 0.125, 0.0) : 0.02 * clamp((0.625 - k) * 4.0, 0.0, 1.0); }
float sheen_level(float u) {
    float x = (u - 0.058) / 0.0354;
    return u < 0.058 ? 0.99 * smoothstep(0.031, 0.058, u) : 0.99 * pow(1.0 + x * x, -1.53);
}
float rim(float n) { return min(1.0, min(n, 127.0 - n) * (10.0 / 127.0)); }

// ---- the flakes --------------------------------------------------------------------------------------------------
const float kTick = 0.0089, kDrag = 0.03, kKick = 0.225, kGravity = -6.8e-5, kSpin = 2.74 / 60.0;
const vec3 kBoundsLow = vec3(-10.0, -10.0, -12.0), kBoundsHigh = vec3(10.0, 10.0, 7.0);
const vec3 kEye = vec3(0.0, 0.0, 2.0), kLamp = vec3(4.2, 2.6, -7.6);
const vec4 kFocus = vec4(6.1, 7.4, 12.8, 16.9);

vec4 quaternion_product(vec4 a, vec4 b) {
    return vec4(a.w * b.xyz + b.w * a.xyz + cross(a.xyz, b.xyz), a.w * b.w - dot(a.xyz, b.xyz));
}
vec3 rotate(vec4 q, vec3 v) { return v + 2.0 * cross(q.xyz, cross(q.xyz, v) + q.w * v); }
vec3 film_tint(vec3 normal) {
    vec3 film = 0.5 + 0.5 * cos(2.0 * kPi * (length(normal.xy) * 1.7 + vec3(0.0, 0.33, 0.67)));
    return vec3(1.0, 0.89, 0.85) * mix(vec3(1.0), film * 1.4, 0.35);
}

// Buffer B's layout: the vertex table at (0..127, 0..127), each flake's sprite in six texels from x = 128.
const int kFlakeX = 128;
ivec2 flake_texel(int id, int item) { return ivec2(kFlakeX + (id & 63), (id >> 6) + 32 * item); }
// Buffer C's layout: crossings (two per line on a window 300 px tall or more, else one), then group bounds, then
// the tile bins (12 texels of 4 flake ids per tile).
int crossing_slots(vec2 res) { return res.y >= 300.0 ? 2 : 1; }
// A tile is about a 34th of the window's height (32 px at 1080p), and holds up to 48 flakes.
const int kBinTexels = 12;
int tile_size(vec2 res) { return max(kBinTexels, int(res.y / 34.0 + 0.5)); }
int bin_row(vec2 res) { return 128 * crossing_slots(res) + 8; }
