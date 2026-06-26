#include "ReShade.fxh"

// 1. UI Options
uniform float Stability <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "Warp Stability (1 = Calm, 0 = Chaotic)";
> = 0.4;

uniform float CustomTimer < source = "timer"; >;

// Deterministic Pseudo-Random Generator
float hash11(float p)
{
    p = frac(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

// Procedural Cosine Color Palette Engine (Generates smooth, infinite sci-fi color curves)
float3 getCosPalette(float t, float3 a, float3 b, float3 c, float3 d)
{
    return a + b * cos(6.28318 * (c * t + d));
}

// 2. Mathematical 3D Line Drawing Helper
float drawLine(float2 p, float2 a, float2 b, float thickness)
{
    float2 pa = p - a, ba = b - a;
    float h = saturate(dot(pa, ba) / dot(ba, ba));
    return step(length(pa - ba * h), thickness);
}

// 3. Pixel Shader Pass
float4 PS_PsykerWidgetColorChaos(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 baseColor = tex2D(ReShade::BackBuffer, texcoord);
    float2 pixelPos = texcoord * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    
    float time = CustomTimer * 0.001;

    // --- RANDOM / CHAOTIC VARIABLES GENERATION ---
    float slowWave = sin(time * 0.5) * 0.5 + 0.5;
    float fastWave = cos(time * 2.7) * 0.5 + 0.5;
    
    float timeStep = floor(time * 8.0); // Changes random numbers 8 times a second
    float randomVal = hash11(timeStep);
    float randomVal2 = hash11(timeStep + 54.32);

    // Dynamic Color Cycling Logic
    // Calm mode restricts color to cool cyans/blues. Chaotic mode spins through the full color wheel.
    float colorTimeFactor = (time * 0.15) + (randomVal * 0.5 * (1.0 - Stability));
    
    // Custom Cosine Waveform Coefficients (Optimized for high-tech neon tones)
    float3 baseTint = float3(0.5, 0.5, 0.5);
    float3 ampTint  = float3(0.5, 0.5, 0.5);
    float3 freq     = float3(1.0, 1.0, 1.0);
    float3 phase    = float3(0.0, 0.33, 0.67); // Splits RGB spectrum for deep variation
    
    float4 DynamicWidgetColor = float4(getCosPalette(colorTimeFactor, baseTint, ampTint, freq, phase), 1.0);

    // 1. Oscillating Positioning (Hovering float + warp tremors)
    float hoverY = (sin(time * 1.5) * 15.0) + (randomVal * 8.0 * (1.0 - Stability));
    float hoverX = (cos(time * 0.9) * 10.0) + (randomVal2 * 8.0 * (1.0 - Stability));
    float2 widgetCenter = float2(BUFFER_WIDTH - 400.0 + hoverX, 200.0 + hoverY);
    
    float boxRadius = 120.0;

    // Only run expensive math if inside the active widget viewport boundary
    if (distance(pixelPos, widgetCenter) < boxRadius * 1.6)
    {
        // 2. Erratic Rotation Speed
        float targetSpin = time * 1.2 + (slowWave * 2.0) + (randomVal * 5.0 * (1.0 - Stability));
        float cosA = cos(targetSpin);
        float sinA = sin(targetSpin);

        // Horizontal Glitch Slice Tearing
        float glitchShift = 0.0;
        if (randomVal > 0.85 && Stability < 0.8)
        {
            float slice = step(0.3, randomVal2) * step(randomVal2, 0.5);
            glitchShift = (randomVal - 0.5) * 35.0 * slice;
        }

        // Establish coordinates
        float2 p = (pixelPos - widgetCenter) / boxRadius;
        p.x += glitchShift / boxRadius; 

        // Core 3D Vertices for our Psyker Pyramid Base (Rotated on Y-Axis)
        float3 v0 = float3(0.0,  0.8, 0.0);  // Apex Point
        float3 v1 = float3(cosA * -0.6 - sinA * -0.6, -0.6, sinA * -0.6 + cosA * -0.6);
        float3 v2 = float3(cosA *  0.6 - sinA * -0.6, -0.6, sinA *  0.6 + cosA * -0.6);
        float3 v3 = float3(cosA *  0.6 - sinA *  0.6, -0.6, sinA *  0.6 + cosA *  0.6);
        float3 v4 = float3(cosA * -0.6 - sinA *  0.6, -0.6, sinA * -0.6 + cosA *  0.6);

        // Project 3D vectors down to 2D flat screen
        float2 p0 = v0.xy; float2 p1 = v1.xy; float2 p2 = v2.xy; float2 p3 = v3.xy; float2 p4 = v4.xy;

        float lines = 0.0;
        float lineThick = 0.014;
        
        // Build structural lines
        lines = max(lines, drawLine(p, p0, p1, lineThick));
        lines = max(lines, drawLine(p, p0, p2, lineThick));
        lines = max(lines, drawLine(p, p0, p3, lineThick));
        lines = max(lines, drawLine(p, p0, p4, lineThick));
        lines = max(lines, drawLine(p, p1, p2, lineThick));
        lines = max(lines, drawLine(p, p2, p3, lineThick));
        lines = max(lines, drawLine(p, p3, p4, lineThick));
        lines = max(lines, drawLine(p, p4, p1, lineThick));

        // Incorporating the Astra Telepathica "Psyker Eye" inside center
        float r = length(p - float2(0.0, -0.1));
        float eyeShape = step(0.12, r) * step(r, 0.14) * step(abs(p.y + 0.1), 0.07);
        float pupil = step(length(p - float2(0.0, -0.1)), 0.04);
        
        float logoMask = saturate(lines + eyeShape + pupil);

        // 3. Brightness Flickering / Warp Surges
        float flicker = 1.0;
        if (randomVal2 > 0.75 && Stability < 0.9)
        {
            flicker = randomVal * 1.5;
            
            // Critical Surge: Force color to snap to a flash-burn crimson white during a bad glitch
            DynamicWidgetColor.rgb = lerp(DynamicWidgetColor.rgb, float3(1.0, 0.2, 0.1), randomVal);
        }

        // Active Signal Pulse Aura
        float pulse = sin(time * (4.0 + randomVal * 4.0)) * 0.5 + 0.5;
        logoMask += (step(0.85, 1.0 - r) * 0.18 * pulse);

        // Additive screen blend
        return baseColor + (DynamicWidgetColor * logoMask * flicker);
    }

    return baseColor;
}

// Technique definition
technique PsykerRainbowWidget
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_PsykerWidgetColorChaos;
    }
}
