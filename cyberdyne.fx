#include "ReShade.fxh"

// 1. UI Options
uniform float WarpInstability <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "Warp Instability (0 = Quiet, 1 = Perils of the Warp)";
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

// Procedural Daemonic/Runic Script Generator
float drawWarpRunes(float2 p, float seed)
{
    float2 grid = floor(p * float2(5.0, 5.0));
    float h = hash11(grid.x + grid.y * 23.41 + floor(seed * 5.0));
    
    // Generates fractured, alien vertical/horizontal geometric cuts (resembling psychic runes)
    float verticalBar = step(0.4, frac(p.x * 5.0)) * step(frac(p.x * 5.0), 0.6);
    float horizontalBar = step(0.4, frac(p.y * 5.0)) * step(frac(p.y * 5.0), 0.6);
    return step(0.3, h) * saturate(verticalBar + horizontalBar) * step(frac(p.x * 5.0), 0.85);
}

// 2. Pixel Shader Pass
float4 PS_WarpPsykerWidget(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 baseColor = tex2D(ReShade::BackBuffer, texcoord);
    float2 pixelPos = texcoord * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    
    float time = CustomTimer * 0.001;

    // --- WARP INTERFERENCE CLOCKS ---
    float timeStep = floor(time * 15.0); 
    float randomVal = hash11(timeStep);
    float randomVal2 = hash11(timeStep + 42.71);

    // Chaotic screen position vibration based on instability level
    float vibration = WarpInstability * 12.0;
    float hoverY = (sin(time * 2.5) * 4.0) + (randomVal * vibration);
    float hoverX = (cos(time * 3.1) * 4.0) + (randomVal2 * vibration);
    
    float2 widgetCenter = float2(BUFFER_WIDTH - 400.0 + hoverX, 230.0 + hoverY);
    float boxRadius = 140.0;

    // Boundary check for performance optimization
    if (pixelPos.x > widgetCenter.x - boxRadius * 1.5 && pixelPos.x < widgetCenter.x + boxRadius * 1.5 &&
        pixelPos.y > widgetCenter.y - boxRadius * 1.8 && pixelPos.y < widgetCenter.y + boxRadius * 1.8)
    {
        // Color Engine: Shifts between a glowing psychic violet and an unholy, corrupted warp-fire green
        float3 psykerColor = lerp(float3(0.5, 0.1, 0.9), float3(0.1, 0.9, 0.4), sin(time * 0.8) * 0.5 + 0.5);
        
        // Sudden high-frequency color bleeding if the warp breaks loose
        if (randomVal > 0.82 * (1.0 - WarpInstability))
        {
            psykerColor = lerp(psykerColor, float3(1.0, 0.0, 0.2), randomVal2); // Flashes blood red
        }

        float2 p = (pixelPos - widgetCenter) / boxRadius;

        // Visual distortion: Bends local coordinates to make the logo look like it's warping in space
        p.x += (sin(p.y * 10.0 + time * 5.0) * 0.04) * WarpInstability;

        float mask = 0.0;

        // --- LAYER A: THE COGNITIVE RECTOR (8-Point Forbidden Wheel) ---
        float2 pLogo = p - float2(0.0, -0.2);
        float rLogo = length(pLogo);
        
        if (rLogo < 0.85)
        {
            // Compute rotation for intersecting star beams
            float angle = time * 0.6;
            float cosA = cos(angle); float sinA = sin(angle);
            float2 rotP = float2(pLogo.x * cosA - pLogo.y * sinA, pLogo.x * sinA + pLogo.y * cosA);

            // Generate 8 directional rays stretching outward from center
            float rayAngle = atan2(rotP.y, rotP.x);
            float rays = step(0.94, cos(rayAngle * 8.0)); // 8 crisp points
            float rayMask = rays * step(rLogo, 0.7) * step(0.15, rLogo);
            mask = max(mask, rayMask);

            // Intersecting focusing ocular rings
            float innerEyeRing = step(abs(rLogo - 0.45), 0.012) + step(abs(rLogo - 0.2), 0.008);
            mask = max(mask, innerEyeRing);
            
            // Central telepathic iris focal node
            float corePoint = step(rLogo, 0.05);
            mask = max(mask, corePoint);
        }

        // --- LAYER B: PSYCHIC RESONANCE MONITOR (EKG Pulse Line) ---
        // A sweeping telemetry wave centered behind the wheel
        float2 pWave = p - float2(0.0, -0.2);
        if (abs(pWave.x) < 0.85 && abs(pWave.y) < 0.45)
        {
            // Base sine frequency spiked violently by pseudo-random variables
            float distortionSpike = (sin(pWave.x * 50.0) * hash11(floor(pWave.x * 10.0) + timeStep)) * WarpInstability * 0.3;
            float ekgLine = sin(pWave.x * 6.0 - time * 8.0) * 0.25 + distortionSpike;
            
            // Build line thickness profile
            float waveDraw = step(abs(pWave.y - ekgLine), 0.015);
            mask = max(mask, waveDraw * 0.35); // Soft backdrop presence
        }

        // --- LAYER C: UNSTABLE RUNIC DATA READOUT (Lower Window) ---
        float2 pText = p - float2(0.0, 0.65);
        if (abs(pText.x) < 0.75 && abs(pText.y) < 0.22)
        {
            float2 textUV = (pText + float2(0.75, 0.22)) / float2(1.5, 0.44);
            
            // Glitch text frame shifting horizontally independently
            float textScroll = time * 0.25;
            float2 scriptUV = textUV + float2(textScroll, 0.0);
            
            float runeMask = drawWarpRunes(scriptUV, timeStep * 0.12);
            
            // Gothic framing borders enclosing the script
            float borderLines = step(0.96, 1.0 - abs(pText.y)) * step(abs(pText.x), 0.74);
            mask = max(mask, runeMask * 0.9 + borderLines * 0.5);
        }

        // --- LAYER D: OCULAR HUD COMPASS BRACKETS ---
        // Circular curved framing elements framing the entire asset
        float rBrack = length(p);
        float circleFrame = step(abs(rBrack - 0.94), 0.01) * step(0.2, abs(frac(atan2(p.y, p.x) * 0.63)));
        mask = max(mask, circleFrame * 0.6);

        // --- GLOBAL INTERFERENCE EFFECT ---
        float glitchFlicker = 1.0;
        if (randomVal2 > 0.88 - (WarpInstability * 0.1))
        {
            glitchFlicker = randomVal * 1.6;
        }

        // Add soft, volatile organic background haze inside widget window
        float backHaze = smoothstep(1.0, 0.0, length(p)) * 0.15;

        float3 finalColor = psykerColor * (mask + backHaze) * glitchFlicker;
        return baseColor + float4(finalColor, 1.0);
    }

    return baseColor;
}

// Technique wrapper
technique WarpPsykerWidget
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_WarpPsykerWidget;
    }
}
