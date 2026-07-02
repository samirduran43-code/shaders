/*-----------------------------------------------------------------------------------------------------
    Multi-Group Color Isolator & Palette Snapper (Strict ReShade 3.8.2 Specification)
-----------------------------------------------------------------------------------------------------*/

// --- Textures & Samplers ---

texture ReShade_BackBufferTex : COLOR;

sampler ReShade_BackBufferSRGB
{
    Texture = ReShade_BackBufferTex;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

// --- UI Uniform Inputs: SLOT A ---

uniform int TargetColor_A <
    ui_type = "combo";
    ui_label = "[Slot A] Isolate Color";
    ui_items = "Red/Orange\0Yellow\0Green\0Cyan/Blue\0Magenta/Purple\0Custom Picker\0Disabled\0";
> = 0;

uniform float3 CustomColorPicker_A <
    ui_type = "color";
    ui_label = "[Slot A] Custom Color";
> = float3(1.0, 0.0, 0.0);

uniform float HueTolerance_A <
    ui_type = "slider";
    ui_label = "[Slot A] Range Tolerance";
    ui_min = 0.0; ui_max = 0.5; ui_step = 0.01;
> = 0.08;

// --- UI Uniform Inputs: SLOT B ---

uniform int TargetColor_B <
    ui_type = "combo";
    ui_label = "[Slot B] Isolate Color";
    ui_items = "Red/Orange\0Yellow\0Green\0Cyan/Blue\0Magenta/Purple\0Custom Picker\0Disabled\0";
> = 2; // Default to Green

uniform float3 CustomColorPicker_B <
    ui_type = "color";
    ui_label = "[Slot B] Custom Color";
> = float3(0.0, 1.0, 0.0);

uniform float HueTolerance_B <
    ui_type = "slider";
    ui_label = "[Slot B] Range Tolerance";
    ui_min = 0.0; ui_max = 0.5; ui_step = 0.01;
> = 0.08;

// --- UI Uniform Inputs: SLOT C ---

uniform int TargetColor_C <
    ui_type = "combo";
    ui_label = "[Slot C] Isolate Color";
    ui_items = "Red/Orange\0Yellow\0Green\0Cyan/Blue\0Magenta/Purple\0Custom Picker\0Disabled\0";
> = 3; // Default to Cyan/Blue

uniform float3 CustomColorPicker_C <
    ui_type = "color";
    ui_label = "[Slot C] Custom Color";
> = float3(0.0, 0.0, 1.0);

uniform float HueTolerance_C <
    ui_type = "slider";
    ui_label = "[Slot C] Range Tolerance";
    ui_min = 0.0; ui_max = 0.5; ui_step = 0.01;
> = 0.08;

// --- Global Adjustments ---

uniform float BackgroundDesaturation <
    ui_type = "slider";
    ui_label = "Background Desaturate";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_tooltip = "How much to desaturate colors that do not match any active slot.";
> = 0.85;

// --- Color Conversion Functions ---

float3 RGBtoHSV_382(float3 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 HSVtoRGB_382(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

// --- Dynamic Slot Evaluation Macro-Logic ---

void EvaluateSlot(int targetMode, float3 customColor, float tolerance, float3 currentHSV, inout float finalMask, inout float3 finalColorAccum)
{
    if (targetMode == 6) return; // Mode 6 is "Disabled"

    float targetHue = 0.0;
    float3 outputPaletteColor = float3(0.0, 0.0, 0.0);

    if (targetMode == 0)
    {
        targetHue = 0.02;
        outputPaletteColor = float3(0.95, 0.26, 0.21);
    }
    else if (targetMode == 1)
    {
        targetHue = 0.16;
        outputPaletteColor = float3(1.0, 0.85, 0.0);
    }
    else if (targetMode == 2)
    {
        targetHue = 0.38;
        outputPaletteColor = float3(0.18, 0.80, 0.44);
    }
    else if (targetMode == 3)
    {
        targetHue = 0.62;
        outputPaletteColor = float3(0.11, 0.63, 0.95);
    }
    else if (targetMode == 4)
    {
        targetHue = 0.82;
        outputPaletteColor = float3(0.61, 0.15, 0.69);
    }
    else if (targetMode == 5)
    {
        float3 customHSV = RGBtoHSV_382(customColor);
        targetHue = customHSV.x;
        outputPaletteColor = customColor;
    }

    // Circular Hue distance
    float hueDiff = abs(currentHSV.x - targetHue);
    if (hueDiff > 0.5) 
    {
        hueDiff = 1.0 - hueDiff;
    }

    // Mask generation
    float currentMask = smoothstep(tolerance, tolerance * 0.5, hueDiff);
    currentMask *= smoothstep(0.1, 0.2, currentHSV.y); // Saturation bounds
    currentMask *= smoothstep(0.1, 0.15, currentHSV.z); // Value bounds

    if (currentMask > 0.0)
    {
        float3 isolatedHSV = RGBtoHSV_382(outputPaletteColor);
        float3 mappedColor = HSVtoRGB_382(float3(isolatedHSV.x, isolatedHSV.y, currentHSV.z));
        
        // Blend overlapping slots smoothly based on mask strength
        float blendWeight = currentMask / (finalMask + currentMask + 1e-5);
        finalColorAccum = lerp(finalColorAccum, mappedColor, blendWeight);
        finalMask = max(finalMask, currentMask);
    }
}

// --- Vertex Shader ---

void VS_ColorIsolator(in uint id : SV_VertexID, out float4 vpos : SV_Position, out float2 texcoord : TEXCOORD)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;
    vpos = float4(texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
}

// --- Pixel Shader ---

float4 PS_ColorIsolator(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float3 color = tex2D(ReShade_BackBufferSRGB, texcoord).rgb;
    float3 hsv = RGBtoHSV_382(color);

    float combinedMask = 0.0;
    float3 combinedIsolateColor = color;

    // Process all 3 color isolation channels independently
    EvaluateSlot(TargetColor_A, CustomColorPicker_A, HueTolerance_A, hsv, combinedMask, combinedIsolateColor);
    EvaluateSlot(TargetColor_B, CustomColorPicker_B, HueTolerance_B, hsv, combinedMask, combinedIsolateColor);
    EvaluateSlot(TargetColor_C, CustomColorPicker_C, HueTolerance_C, hsv, combinedMask, combinedIsolateColor);

    // Build the fallback background out of desaturated data
    float grayValue = dot(color, float3(0.299, 0.587, 0.114));
    float3 desaturatedColor = lerp(color, float3(grayValue, grayValue, grayValue), BackgroundDesaturation);

    // Final composition pass
    return float4(lerp(desaturatedColor, combinedIsolateColor, combinedMask), 1.0);
}

// --- Technique Block ---

technique MultiColorIsolator382
{
    pass
    {
        VertexShader = VS_ColorIsolator;
        PixelShader = PS_ColorIsolator;
    }
}
