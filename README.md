# Silk Waves Web

**A browser-based recreation of the PlayStation 3 XMB animated background.**

Silk Waves Web recreates the iconic flowing silk ribbons, soft lighting, and floating particles of the PlayStation 3's XrossMediaBar (XMB) background using WebGL2 and GLSL.

The project preserves the minimalist aesthetic of the original experience—without the menus, icons, or interface elements.

Everything is rendered in real time on your GPU. No background videos, external rendering services, or additional frameworks are required.

[![Silk Waves Web Preview](preview.png)](https://kacboy.com/xmb)
*Experience the classic PS3 XMB background in your browser, without the menus.*

## Features

- **Classic XMB aesthetic** — Flowing silk ribbons, dynamic lighting, and shimmering particles.
- **Real-time GPU rendering** — Powered by WebGL2 and GLSL.
- **Seasonal color palettes** — Twelve monthly palettes that transition throughout the year.
- **Dynamic lighting** — Automatically adjusts to your local time, with manual day, dusk, and night options.
- **Native resolution support** — Render at your display's resolution, including 4K and higher where supported.
- **Adjustable frame rate** — Select a frame-rate limit or use uncapped rendering.
- **Minimal interface** — Settings remain hidden until needed.
- **Single-file deployment** — The complete experience can run from one HTML file.
- **Responsive fullscreen layout** — Adapts to different display sizes and aspect ratios.

## Getting Started

No installation is required to use the standalone webpage.

1. Download the latest `index.html` from this repository.
2. Open it in a modern browser such as Chrome, Edge, or Firefox with WebGL2 support.
3. Enjoy the animation.

Press **F11** to enter browser fullscreen mode.

Move your cursor to the upper-right corner to reveal the settings panel.

### Controls

| Setting | Description |
|---|---|
| Month | Follow the calendar automatically or select one of 12 monthly palettes |
| Time of day | Current time, Day, Dusk, or Night |
| Resolution | Choose a fixed resolution or use Native / Full Resolution |
| Frame rate | Limit rendering FPS or select Uncapped |
| Pause / Resume | Temporarily pause the animation |
| Restart | Reset the simulation to its initial state |

By default, the background follows your computer's current date and local time.

## How It Works

Unlike a prerecorded video, Silk Waves generates its animation using GPU shaders.

The effect consists of several rendering passes:

| Shader | Purpose |
|---|---|
| `common.glsl` | Shared math, lighting, palettes, and simulation functions |
| `buffer-a.glsl` | Cloth physics and particle simulation |
| `buffer-b.glsl` | Ribbon geometry, projection, and particle sprites |
| `buffer-c.glsl` | Ribbon intersections and particle visibility |
| `buffer-d.glsl` | Ribbon lighting and glare |
| `image.glsl` | Final image composition, tone mapping, and particles |

The cloth simulation continuously evolves, producing smooth, organic wave movement rather than replaying a fixed animation loop.

### Project Structure

```text
silk-waves-web/
├── index.html
├── runner.js
├── build.py
├── shaders/
│   ├── common.glsl
│   ├── buffer-a.glsl
│   ├── buffer-b.glsl
│   ├── buffer-c.glsl
│   ├── buffer-d.glsl
│   └── image.glsl
├── README.md
└── LICENSE
```

## Building from Source

The standalone HTML contains the shader code and JavaScript renderer required to run the animation.

The repository also includes the individual source files for easier modification and development.

To rebuild the webpage, run:

```bash
python build.py
```

The build script assembles the source into a standalone HTML webpage.

*Note: Check the build script's configured input and output paths before rebuilding.*

## Performance

Silk Waves is GPU-intensive, particularly at high resolutions.

For the best experience:

- Use a browser with hardware acceleration enabled.
- Start at 1080p if you're unsure of your GPU's capabilities.
- Increase the resolution for sharper output on powerful hardware.
- Lower the frame rate or resolution to reduce GPU usage and power consumption.

Native resolution and uncapped FPS are available, but actual performance depends on your graphics hardware, browser, and display.

## Customization

The shader includes configurable values for wave speed, brightness, glitter, glare, seasonal colors, and lighting.

These settings can be modified in the GLSL source to create different variations while retaining the original animation style.

The monthly palettes are defined in `common.glsl`.

## Credits

Silk Waves Web is based on **Silk Waves**, a GLSL recreation of the classic PlayStation 3 XMB background.

The shader implementation credits the MaiCord authors and draws inspiration from:

- **MaiCord Silk Waves** — [MaiCord Plugins](https://github.com/maj113/MaiCord-plugins)
- **PlayStation-3-XMB** — [linkev/PlayStation-3-XMB](https://github.com/linkev/PlayStation-3-XMB)
- **Shadertoy** — The original environment used to showcase the shader: [Silk Waves](https://www.shadertoy.com/view/N3yXWy)

Special thanks to the developers and community members who have studied and recreated the visual effects of the PlayStation 3's XMB interface.

## License

This project incorporates shader code released under the **MIT License**.

Copyright © 2026 the MaiCord authors.

See [LICENSE](LICENSE) for the full license text and applicable attribution.

PlayStation, PS3, and XrossMediaBar are trademarks of Sony Interactive Entertainment or their respective owners.

This is an independent fan recreation and is not affiliated with or endorsed by Sony Interactive Entertainment.

---

*Inspired by one of the most memorable console interfaces of its generation.*
