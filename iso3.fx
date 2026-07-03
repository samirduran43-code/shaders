/*-----------------------------------------------------------------------------------------------------
    6-Channel Color Isolator & Palette Snapper (Strict ReShade 3.8.2 Specification - Yellow-Green Eyes Default)
-----------------------------------------------------------------------------------------------------*/

// --- Textures & Samplers ---
texture ReShade_BackBufferTex : COLOR;
sampler ReShade_BackBufferSRGB { Texture = ReShade_BackBufferTex; MinFilter = LINEAR; MagFilter = LINEAR; MipFilter = LINEAR; };

// --- UI Uniform Inputs ---

// Slot A: Olive-Green Base (Pre-configured)
uniform int TargetColor_A < ui_type = "combo"; ui_label = "[Slot A] Mode"; ui_items = "Red/Orange\0Yellow\0Green\0Cyan/Blue\0Magenta/Purple\0Custom Pickers Only\0Disabled\0"; > = 5; // Custom Pickers Only
uniform float3 InputPicker_A < ui_type = "drag"; ui_label = "[Slot A] Input Color (Target)"; ui_min = 0.0; ui_max = 1.0; > = float3(0.45, 0.65, 0.25);
uniform float3 OutputPicker_A < ui_type = "drag"; ui_label = "[Slot A] Output Color (Palette)"; ui_min = 0.0; ui_max = 1.0; > = float3(0.20, 0.85, 0.40);
uniform float HueTolerance_A < ui_type = "slider"; ui_label = "[Slot A] Range Tolerance"; ui_min = 0.0; ui_max = 0.5; > = 0.06;

// Slot B: Gold Iris Ring (Pre-configured)
uniform int TargetColor_B < ui_type = "combo"; ui_label = "[Slot B] Mode"; ui_items = "Red/Orange\0Yellow\0Green\0Cyan/Blue\0Magenta/Purple\0Custom Pickers Only\0Disabled\0"; > = 5; // Custom Pickers Only
uniform float3 InputPicker_B < ui_type = "drag"; ui_label = "[Slot B] Input Color (Target)"; ui_min = 0.0; ui_max = 1.0; > = float3(0.75, 0.70, 0.15);
uniform float3 OutputPicker_B < ui_type = "drag"; ui_label = "[Slot B] Output Color (Palette)"; ui_min = 0.0; ui_max = 1.0; > = float3(0.95, 0.75, 0.10);
uniform float HueTolerance_B < ui_type = "slider"; ui_label = "[Slot B] Range Tolerance"; ui_min = 0.0; ui_max = 0.5; > = 0.05;

// Slot C (Disabled by default)
uniform int TargetColor_C < ui_type = "combo"; ui_label = "[Slot C] Mode"; ui_items = "Red/Orange\0Yellow\0Green\0Cyan/Blue\0Magenta/Purple\0Custom Pickers Only\0Disabled\0"; > = 6;
uniform float3 InputPicker_C < ui_type = "drag"; ui_label = "[Slot C] Input Color (Target)"; ui_min = 0.0; ui_max = 1.0; > = float3(0.0, 1.0, 0.0);
uniform float3 OutputPicker_C < ui_type = "drag"; ui_label = "[Slot C] Output Color (Palette)"; ui_min = 0.0; ui_max = 1.0; > = float3(0.18, 0.80, 0.44);
uniform float HueTolerance_C < ui_type = "slider"; ui_label = "[Slot C] Range Tolerance"; ui_min = 0.0; ui_max = 0.5; > = 0.08;

// Slot D (Disabled by default)
uniform int TargetColor_D < ui_type = "combo"; ui_label = "[Slot D] Mode"; ui_items = "Red/Orange\0Yellow\0Green\0Cyan/Blue\0Magenta/Purple\0Custom Pickers Only\0Disabled\0"; > = 6;
uniform float3 InputPicker_D < ui_type = "drag"; ui_label = "[Slot D] Input Color (Target)"; ui_min = 0.0; ui_max = 1.0; > = float3(0.0, 1.0, 1.0);
uniform float3 OutputPicker_D < ui_type = "drag"; ui_label = "[Slot D] Output Color (Palette)"; ui_min = 0.0; ui_max = 1.0; > = float3(0.11, 0.63, 0.95);
uniform float HueTolerance_D < ui_type = "slider"; ui_label = "[Slot D] Range Tolerance"; ui_min = 0.0; ui_max = 0.5; > = 0.08;

// Slot E (Disabled by default)
uniform int TargetColor_E < ui_type = "combo"; ui_label = "[Slot E] Mode"; ui_items = "Red/Orange\0Yellow\0Green\0Cyan/Blue\0Magenta/Purple\0Custom Pickers Only\0Disabled\0"; > = 6;
uniform float3 InputPicker_E < ui_type = "drag"; ui_label = "[Slot E] Input Color (Target)"; ui_min = 0.0; ui_max = 1.0; > = float3(0.5, 0.0, 0.5);
uniform float3 OutputPicker_E < ui_type = "drag"; ui_label = "[Slot E] Output Color (Palette)"; ui_min = 0.0; ui_max = 1.0; > = float3(0.61, 0.15, 0.69);
uniform float HueTolerance_E < ui_type = "slider"; ui_label = "[Slot E] Range Tolerance"; ui_min = 0.0; ui_max = 0.5; > = 0.08;

// Slot F (Disabled by default)
uniform int TargetColor_F < ui_type = "combo"; ui_label = "[Slot F] Mode"; ui_items = "Red/Orange\0Yellow\0Green\0Cyan/Blue\0Magenta/Purple\0Custom Pickers Only\0Disabled\0"; > = 6;
uniform float3 InputPicker_F < ui_type = "drag"; ui_label = "[Slot F] Input Color (Target)"; ui_min = 0.0; ui_max = 1.0; > = float3(1.0, 1.0, 1.0);
uniform float3 OutputPicker_F < ui_type = "drag"; ui_label = "[Slot F] Output Color (Palette)"; ui_min = 0.0; ui_max = 1.0; > = float3(1.0, 1.0, 1.0);
uniform float HueTolerance_F < ui_type = "slider"; ui_label = "[Slot F] Range Tolerance"; ui_min = 0.0; ui_max = 0.5; > = 0.08;

// Global Adjustments (Pre-configured background drop)
uniform float BackgroundDesaturation < ui_type = "slider"; ui_label = "Background Desaturate"; ui_min = 0.0; ui_max = 1.0; > = 0.55;

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

void EvaluateSlot(int targetMode, float3 inputPicker, float3 outputPicker, float tolerance, float3 currentHSV, inout float finalMask, inout float3 finalColorAccum)
{
    if (targetMode == 6) return;

    float targetHue = 0.0;
    float3 outputPaletteColor = float3(0.0, 0.0, 0.0);

    if (targetMode == 0) { targetHue = 0.02; outputPaletteColor = float3(0.95, 0.26, 0.21); }
    else if (targetMode == 1) { targetHue = 0.16; outputPaletteColor = float3(1.0, 0.85, 0.0); }
    else if (targetMode == 2) { targetHue = 0.38; outputPaletteColor = float3(0.18, 0.80, 0.44); }
    else if (targetMode == 3) { targetHue = 0.62; outputPaletteColor = float3(0.11, 0.63, 0.95); }
    else if (targetMode == 4) { targetHue = 0.82; outputPaletteColor = float3(0.61, 0.15, 0.69); }
    else if (targetMode == 5)
    {
        float3 customHSV = RGBtoHSV_382(inputPicker);
        targetHue = customHSV.x;
        outputPaletteColor = outputPicker;
    }

    float hueDiff = abs(currentHSV.x - targetHue);
    if (hueDiff > 0.5) 
    {
        hueDiff = 1.0 - hueDiff;
    }

    float currentMask = smoothstep(tolerance, tolerance * 0.5, hueDiff);
    currentMask *= smoothstep(0.1, 0.2, currentHSV.y); 
    currentMask *= smoothstep(0.1, 0.15, currentHSV.z); 

    if (currentMask > 0.0)
    {
        float3 isolatedHSV = RGBtoHSV_382(outputPaletteColor);
        float3 mappedColor = HSVtoRGB_382(float3(isolatedHSV.x, isolatedHSV.y, currentHSV.z));
        
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

    // Run parallel pass evaluation
    EvaluateSlot(TargetColor_A, InputPicker_A, OutputPicker_A, HueTolerance_A, hsv, combinedMask, combinedIsolateColor);
    EvaluateSlot(TargetColor_B, InputPicker_B, OutputPicker_B, HueTolerance_B, hsv, combinedMask, combinedIsolateColor);
    EvaluateSlot(TargetColor_C, InputPicker_C, OutputPicker_C, HueTolerance_C, hsv, combinedMask, combinedIsolateColor);
    EvaluateSlot(TargetColor_D, InputPicker_D, OutputPicker_D, HueTolerance_D, hsv, combinedMask, combinedIsolateColor);
    EvaluateSlot(TargetColor_E, InputPicker_E, OutputPicker_E, HueTolerance_E, hsv, combinedMask, combinedIsolateColor);
    EvaluateSlot(TargetColor_F, InputPicker_F, OutputPicker_F, HueTolerance_F, hsv, combinedMask, combinedIsolateColor);

    float grayValue = dot(color, float3(0.299, 0.587, 0.114));
    float3 desaturatedColor = lerp(color, float3(grayValue, grayValue, grayValue), BackgroundDesaturation);

    return float4(lerp(desaturatedColor, combinedIsolateColor, combinedMask), 1.0);
}

// --- Technique Block ---

technique SixChannelColorIsolatorDefault
{
    pass
    {
        VertexShader = VS_ColorIsolator;
        PixelShader = PS_ColorIsolator;
    }
}
