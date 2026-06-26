#include "ReShade.fxh"

// 1. UI Options in ReShade Settings Panel
uniform float4 BaseTechColor <
    ui_type = "color";
    ui_label = "Astra Interface Color";
> = float4(1.0, 0.0, 0.0, 1.0); // FIXED: Changed default vector initialization to full red

uniform float SignalFrequency <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "Warp Signal Pulse Rate";
> = 0.5;

uniform float HoloGhosting <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "Holo Ghosting Jitter";
> = 0.5;

uniform float CustomTimer < source = "timer"; >;

// Deterministic Pseudo-Random Generator
float hash11(float p)
{
    p = frac(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

// Procedural Number Generator for the Latitude Readout
float drawDigitalNumber(float2 uv, float digitValue)
{
    float2 f = frac(uv);
    float val = floor(digitValue);
    int num = int(val - (floor(val / 10.0) * 10.0));
    
    float top      = step(0.2, f.x) * step(f.x, 0.8) * step(abs(f.y - 0.85), 0.06);
    float middle   = step(0.2, f.x) * step(f.x, 0.8) * step(abs(f.y - 0.50), 0.06);
    float bottom   = step(0.2, f.x) * step(f.x, 0.8) * step(abs(f.y - 0.15), 0.06);
    float topLeft  = step(abs(f.x - 0.2), 0.06) * step(0.5, f.y) * step(f.y, 0.85);
    float topRight = step(abs(f.x - 0.8), 0.06) * step(0.5, f.y) * step(f.y, 0.85);
    float botLeft  = step(abs(f.x - 0.2), 0.06) * step(0.15, f.y) * step(f.y, 0.5);
    float botRight = step(abs(f.x - 0.8), 0.06) * step(0.15, f.y) * step(f.y, 0.5);
    
    float mask = 0.0;
    if (num == 0) mask = top + bottom + topLeft + topRight + botLeft + botRight;
    if (num == 1) mask = topRight + botRight;
    if (num == 2) mask = top + middle + bottom + topRight + botLeft;
    if (num == 3) mask = top + middle + bottom + topRight + botRight;
    if (num == 4) mask = middle + topLeft + topRight + botRight;
    if (num == 5) mask = top + middle + bottom + topLeft + botRight;
    if (num == 6) mask = top + middle + bottom + topLeft + botLeft + botRight;
    if (num == 7) mask = top + topRight + botRight;
    if (num == 8) mask = top + middle + bottom + topLeft + topRight + botLeft + botRight;
    if (num == 9) mask = top + middle + bottom + topLeft + topRight + botRight;
    
    return mask;
}

// Sub-Shader Geometry Evaluator
float calculateWidgetMask(float2 p, float time, float fastClock, float randomVal, float numScrambler, float SignalFrequency)
{
    float mask = 0.0;

    // --- LAYER A: TRIPLE-RING NESTED ORBITAL COMPASS ---
    float2 pCore = p - float2(0.0, -0.22);
    float rCore = length(pCore);
    float theta = atan2(pCore.y, pCore.x);

    if (rCore < 0.85)
    {
        float rotTheta1 = theta + time * 0.3;
        float ring1 = step(abs(rCore - 0.76), 0.012);
        float slots1 = step(0.35, frac(rotTheta1 * 1.27)); 
        mask = max(mask, ring1 * slots1);

        float rotTheta2 = theta - time * 0.7;
        float ring2 = step(abs(rCore - 0.58), 0.006);
        float ticks2 = step(0.75, frac(rotTheta2 * 7.95)) * step(abs(rCore - 0.58), 0.03);
        mask = max(mask, ring2 + ticks2);

        float ring3 = step(abs(rCore - 0.32), 0.015);
        float innerDots = step(0.85, sin(theta * 4.0)) * step(abs(rCore - 0.32), 0.04);
        mask = max(mask, ring3 * (1.0 - innerDots));
        
        mask = max(mask, step(rCore, 0.04));
    }

    // --- LAYER B: SONAR VECTOR RADAR SWEEP ---
    if (rCore < 0.76)
    {
        float sweepLine = frac(time * 0.25) * 6.28318 - 3.14159;
        float angularDistance = theta - sweepLine;
        
        if (angularDistance < -3.14159) angularDistance += 6.28318;
        if (angularDistance > 3.14159)  angularDistance -= 6.28318;
        
        if (angularDistance < 0.0)
        {
            float trailGlow = saturate(1.0 + (angularDistance * 1.5));
            mask = max(mask, trailGlow * 0.18);
        }
        
        float leadingEdge = step(abs(angularDistance), 0.015);
        mask = max(mask, leadingEdge * 0.6);
    }

    // --- LAYER C: CYCLIC DISTORTION EXPANDING SHOCKWAVES ---
    float pulseSpeed = (SignalFrequency * 2.0 + 1.0) * time;
    float waveDistance = frac(pulseSpeed * 0.5) * 0.85;
    float expandingWave = step(abs(rCore - waveDistance), 0.018) * smoothstep(0.85, 0.1, waveDistance);
    mask = max(mask, expandingWave * 0.4);

    // --- LAYER D: INTERLOCKING DATA BAR TRACKERS ---
    if (rCore > 0.80 && rCore < 0.84)
    {
        float arcSegments = step(0.4, frac(theta * 0.95)) * step(abs(theta), 2.2);
        mask = max(mask, arcSegments * 0.7);
    }

    // --- LAYER E: 4-DIGIT DIGITAL LATITUDE READOUT ---
    float2 pReadout = p - float2(0.0, 0.72);
    if (abs(pReadout.x) < 0.50 && abs(pReadout.y) < 0.12)
    {
        float digitID = floor((pReadout.x + 0.50) / 0.25);
        float2 cellUV = float2(frac((pReadout.x + 0.50) / 0.25), (pReadout.y + 0.12) / 0.24);
        
        float gridBorderMask = step(0.12, cellUV.x) * step(cellUV.x, 0.88);
        float numericSeed = hash11(digitID * 43.19 + numScrambler) * 10.0;
        float displayMask = drawDigitalNumber(cellUV, numericSeed);
        
        float outerFrameLineY = step(abs(pReadout.y), 0.12) * step(0.10, abs(pReadout.y));
        float outerFrameLineX = step(abs(pReadout.x), 0.50) * step(0.48, abs(pReadout.x));
        
        mask = max(mask, (displayMask * gridBorderMask) + saturate(outerFrameLineY + outerFrameLineX) * 0.4);
    }

    // --- LAYER F: TACTICAL BRACKETS CORNERS ---
    float2 absP = abs(p);
    float brackets = step(0.93, max(absP.x, absP.y * 0.72)) * step(max(absP.x, absP.y * 0.72), 0.97);
    float bracketCut = step(0.74, min(absP.x, absP.y * 0.72));
    mask = max(mask, brackets * bracketCut * 0.6);

    return mask;
}

// 2. Pixel Shader Pass
float4 PS_WarpNexusMonitor(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 baseColor = tex2D(ReShade::BackBuffer, texcoord);
    float2 pixelPos = texcoord * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    
    float time = CustomTimer * 0.001;

    // --- SYSTEMS OPERATIONAL TIMERS ---
    float fastClock   = floor(time * 12.0);
    float numScrambler = floor(time * 4.0); 
    float randomVal   = hash11(fastClock);
    float randomVal2  = hash11(fastClock + 14.3);

    // Primary drifting coordinates
    float hoverY = sin(time * 0.9) * 4.0;
    float hoverX = cos(time * 0.6) * 5.0;
    float2 widgetCenter = float2(BUFFER_WIDTH - 650.0 + hoverX, 230.0 + hoverY);
    float boxRadius = 140.0;

    // Viewport box clipping limits
    if (pixelPos.x > widgetCenter.x - boxRadius * 1.7 && pixelPos.x < widgetCenter.x + boxRadius * 1.7 &&
        pixelPos.y > widgetCenter.y - boxRadius * 2.1 && pixelPos.y < widgetCenter.y + boxRadius * 2.8)
    {
        float2 p = (pixelPos - widgetCenter) / boxRadius;

        // --- HOLO GHOSTING JITTER ENGINE ---
        float jitterStep = step(0.75, randomVal) * (randomVal2 - 0.5) * 0.18 * HoloGhosting;
        
        float2 mainP = p;
        float2 ghostP = p + float2(jitterStep, 0.0);

        // Evaluate masks
        float mainMask  = calculateWidgetMask(mainP, time, fastClock, randomVal, numScrambler, SignalFrequency);
        float ghostMask = calculateWidgetMask(ghostP, time, fastClock, randomVal, numScrambler, SignalFrequency);

        // Color Processing Engine
        float3 baseColorOut = BaseTechColor.rgb;
        if (randomVal > 0.93) baseColorOut = saturate(baseColorOut + float3(0.0, 0.4, 0.4)); // Flare shifts red slightly to orange warning parameters

        float3 mainColor  = baseColorOut;
        float3 ghostColor = baseColorOut * float3(1.0, 0.2, 0.3) * 0.55; // Red-shifted ghost layer

        // Composite main display with shadow phantom overlay layers
        float3 finalMaskColor = (mainColor * mainMask) + (ghostColor * ghostMask * step(0.01, abs(jitterStep)));

        // Screen scanlines filter profile
        float scanline = sin(pixelPos.y * 2.5) * 0.15 + 0.85;
        float flicker = 0.95 + (hash11(time * 30.0) * 0.05);

        return baseColor + float4(finalMaskColor * scanline * flicker, 1.0);
    }

    return baseColor;
}

// 3. Technique Wrapper Setup
technique WarpNexusMonitorAssembly
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_WarpNexusMonitor;
    }
}
