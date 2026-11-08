SILK WAVES — FULLSCREEN STANDALONE WEBPAGE

Open SilkWaves.html in a modern Chrome, Edge, or Firefox browser.
The page runs locally without external libraries or network access.

The shader fills the viewport and follows your local month and time at launch.
Click anywhere on the background to cycle monthly palettes; use the upper-right
gear (hover or click) to choose rendering quality, pause, restart, or restore
calendar-based colors. The controls disappear when not hovered/focused.

Quality options: 540p, 720p, 1080p, 1440p, and up to 2160p (4K UHD).
The actual drawing buffer matches the window aspect ratio and is capped at
3840 pixels wide and 2160 pixels tall. 4K is very GPU-intensive and performance
is not guaranteed; start low and increase gradually.

The WebGL2 renderer uses smaller intermediate textures for Buffers A, B and C,
full resolution for Buffer D, and ping-pong feedback for A and D.
Requires WebGL2 and EXT_color_buffer_float.

MIT License, Copyright (c) 2026 the MaiCord authors. The original shader
license and credits are included in Common.glsl and embedded in the HTML.

Run python build.py in this directory to regenerate SilkWaves.html.

Lighting selector: Current time (default) follows the device clock; Day fixes the shader clock to noon; Night fixes it to midnight. All three preserve the chosen month.

OPTIMIZATION UPDATE
- Added 30/60 FPS cap. 30 FPS can substantially reduce GPU usage at 4K.
- No GPU draws while page is hidden, and only one redraw while paused.
- Time/date uniforms now calculated once per rendered frame.
- Live measured FPS display in settings (not a GPU timer).
- WebGL2 and original shader visuals preserved.

CLEAN BACKGROUND UPDATE
- Replaced click-anywhere month cycling with a Month dropdown (Automatic + January-December).
- Settings gear and panel fully transparent until top-right corner hover/focus; pointer leaving hides it again.
- Rendering and original artwork unchanged.

PALETTE AND DUSK UPDATE
- Month picker displays the actual top/bottom sky palette colors as gradient swatches.
- Automatic mode remains the initial selection and follows device date/time.
- Added Dusk (6 PM), a midpoint between noon and midnight, using the shader's existing dusk preset.
- Original Common and buffer GLSL remain unchanged; only UI and date uniform control updated.

Native / Full resolution: chooses browser viewport CSS pixels multiplied by devicePixelRatio, with no artificial 4K cap. Subject to browser/GPU size and memory limits. Changing screen resolution or resizing the window updates the buffer size.

Frame rate: Uncapped runs on every requestAnimationFrame callback. Browsers normally synchronize this to the monitor refresh rate, so it is not an unlimited/tearing FPS mode. Animation uses elapsed time; the original simulated cloth uses time-delta-adjusted 60 Hz steps.
