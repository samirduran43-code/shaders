# Advanced ReShade Shader Suite

A high-performance collection of post-processing shaders for ReShade that rewrite game rendering pipelines in real-time without hurting frame rates.

---

## 🔥 Key Features

* **5×4 Affine Matrix Architecture:** Moves beyond simple 3×3 RGB color swaps to introduce per-channel translation offsets and custom luminance tracking.
* **Smart Luma Masking:** Uses dual-threshold parameters (`LumaMaskMin`/`LumaMaskMax`) to confine heavy color filters to specific brightness brackets.
* **Zero Performance Cost:** Runs mathematical calculations uniformly across the screen texture, requiring virtually zero GPU overhead.
* **Safety Clamping:** Built-in code blocks prevent color bleeding, artifacting, and white-out flashes during bright gameplay events.

---

## 🎨 Included Shaders & Presets

### 1. `SmartColorMatrix.fx` (Collection 1)
Features flagship atmospheric styles and a dedicated multi-pass selective masking loop:
* **Thermal Infrared:** Simulated military tracking vision using inverted cool palettes.
* **Selective Red Noir:** Drops the entire scene to grayscale while dynamically preserving deep reds.
* **Game Boy DMG:** Simulates a retro 4-bit handheld monochrome green matrix screen.
* **Cyberpunk Neon:** A vaporwave-heavy look that pushes colors into electric magenta and purple.
* *Includes: Cinematic Cross-Process, Noir Film, Wasteland Green, Cyberpunk Blue/Amber, Gothic Horror, Solarized Inversion, and Vaporwave Pastel.*

### 2. `SmartColorMatrixV2.fx` (Collection 2)
A completely separate, standalone companion file featuring 12 fresh visual presets:
* **Vintage Polaroid:** Mid-century film aesthetic with washed-out, warm highlights.
* **Blood Moon Horror:** Aggressive, high-contrast crimson rendering for survival titles.
* **Deep Sea Abyss:** Submerges the image into deep cobalt blues and muted aqua tones.
* **Golden Hour Sun:** Bathes game environments in intense warm sunset glows.
* *Includes: Toxic Swamp, Cyberpunk Green/Purple, Chroma Inversion, War Film, Monochrome Copper, Retrowave Sunset, Alien Atmosphere, and Frozen Tundra.*

### 3. Screen & Camera Transformers (`Master4.7zip` & Utilities)
Advanced geometry and screen-space utility shaders that drastically warp pixel data:
* **Police Lights Simulator:** Timed frequency loops that flash red and blue reflections over the frame.
* **Artistic Filters:** ComicPass and Kuwahara scripts that turn 3D scenes into comic books or oil paintings.
* **Motion Focus:** Limits peripheral vision and blurs edges automatically during fast camera turns.

---

## 🛠️ Quick Installation

1. Copy your `.fx` file into your game's shader folder: `...\reshade-shaders\Shaders\`
2. Boot your game and open the ReShade overlay (**Home** key by default).
3. Check the shader name to enable it, and use the **Gameplay Preset Profile** dropdown menu to switch styles instantly.

<img width="3046" height="1050" alt="image" src="https://github.com/user-attachments/assets/270410e5-b3ae-4dbb-a793-1a1bf06a96ab" />


£ NEW!!! vampire mode

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/77769bb5-782a-40f0-b29a-1b98c0277a50" />




£ example of masking
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/0c61c0ea-abe7-428c-8120-bcde79662a4d" />




# shaders and UI
useful  shader for reshade

originally developed for warhammer 40k inquisitor but use with any reshade install
-use DownsampleSSAO for better look and Colors or ColorMatrix

new ! noosphere work in progress (first 1.0 ver published in noo.fx)
<img width="2304" height="648" alt="image" src="https://github.com/user-attachments/assets/7a1f4f98-6b05-4adc-b105-e268341ca8a8" />

![til](./cog.gif)


NEW! astra and cog
<img width="2304" height="648" alt="image" src="https://github.com/user-attachments/assets/c9791ae0-451a-4b34-87d3-83676ff7e2eb" />



industrial:
<img width="2304" height="648" alt="image" src="https://github.com/user-attachments/assets/4a94198f-0720-4139-a076-061c529ad329" />

(psyker.fx - animated)
<img width="461" height="309" alt="image" src="https://github.com/user-attachments/assets/624b6fbe-f476-491c-bf57-221c032cfdf6" />

discojesus gif

![til](./discojesus.gif)


inq2shader:
<img width="2304" height="648" alt="showshader" src="https://github.com/user-attachments/assets/ecbd53bd-47f6-4cf5-a376-b624d95cf49d" />

blue thermal (instead of standard red)
<img width="2304" height="648" alt="image" src="https://github.com/user-attachments/assets/24085dea-d446-478a-a495-97672fbc5693" />

blue thermal enemies:
<img width="2304" height="648" alt="image" src="https://github.com/user-attachments/assets/0d5dadcd-5d68-4039-8a9d-2360ca1ad0d6" />


correct color matrix for blue thermal:


[ColorMatrix.fx]
<img width="2304" height="648" alt="image" src="https://github.com/user-attachments/assets/220fbb0d-06ce-4c74-8e16-06c175af1032" />
