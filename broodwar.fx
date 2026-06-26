#include "ReShade.fxh"

// --- UI Controls ---
uniform float ColorSteps <
    ui_type = "slider";
    ui_min = 2.0; ui_max = 16.0; ui_step = 1.0;
    ui_label = "Color Depth (Lower = Retro)";
    ui_tooltip = "Controls how strictly colors are crushed into limited palettes.";
> = 6.0;

uniform float DitherIntensity <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Bayer Dither Strength";
    ui_tooltip = "Controls how visible the retro checkerboard pixel pattern is.";
> = 0.35;

uniform float ContrastBoost <
    ui_type = "slider";
    ui_min = 1.0; ui_max = 2.0; ui_step = 0.05;
    ui_label = "Brood War Contrast Boost";
    ui_tooltip = "Accentuates shadows to mirror the original StarCraft tile-set aesthetic.";
> = 1.25;

// --- Pixel Shader ---
float4 PS_StarCraftClassic(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // 1. Grab original game backbuffer color
    float4 baseColor = tex2D(ReShade::BackBuffer, texcoord);
    float3 color = baseColor.rgb;

    // 2. Apply a punchy contrast adjustment matching old PCX sprites
    color = pow(abs(color), ContrastBoost);

    // 3. Define a standard 4x4 Ordered Bayer Dithering Matrix
    // This replicates old-school 256-color software engine rendering patterns
    const float4x4 bayerMatrix = float4x4(
        0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
        12.0 / 16.0, 4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
        3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
        15.0 / 16.0, 7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
    );

    // Get screen pixel coordinates for the dither grid alignment
    int x = int(vpos.x) % 4;
    int y = int(vpos.y) % 4;
    float ditherValue = bayerMatrix[x][y] - 0.5; // Offset to center the noise shifting

    // 4. Inject the dithering noise into the raw pipeline before palette quantization
    color += ditherValue * (DitherIntensity / ColorSteps);

    // 5. Hard color quantization (force mathematical color banding)
    color = floor(color * ColorSteps) / ColorSteps;

    // 6. Push saturation slightly to emphasize distinct faction/team colors (like crisp red/blue sprites)
    float luma = dot(color, float3(0.299, 0.587, 0.114));
    color = lerp(luma, color, 1.2);

    return float4(color, baseColor.a);
}

// --- ReShade Technique Wrapper ---
technique StarCraftClassic
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_StarCraftClassic;
    }
}
