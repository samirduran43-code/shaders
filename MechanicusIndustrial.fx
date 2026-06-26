#include "ReShade.fxh"

// 1. UI Options
uniform float SystemLoad <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "Machine Core Load / Output";
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

// 2. Pixel Shader Pass
float4 PS_MechanicusWidget(float4 position : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 baseColor = tex2D(ReShade::BackBuffer, texcoord);
    float2 pixelPos = texcoord * float2(BUFFER_WIDTH, BUFFER_HEIGHT);
    
    float time = CustomTimer * 0.001;

    // --- MACHINE CLOCK LOGIC ---
    float timeStep = floor(time * 8.0); 
    float randomVal = hash11(timeStep);
    
    // Stable, rigid positioning (No organic floating, just slight heavy mechanical engine vibrations)
    float vibration = step(0.92, hash11(floor(time * 24.0))) * 3.0;
    float2 widgetCenter = float2(BUFFER_WIDTH - 400.0 + vibration, 230.0);
    float boxRadius = 140.0;

    // Boundary check for performance optimization
    if (pixelPos.x > widgetCenter.x - boxRadius * 1.5 && pixelPos.x < widgetCenter.x + boxRadius * 1.5 &&
        pixelPos.y > widgetCenter.y - boxRadius * 1.8 && pixelPos.y < widgetCenter.y + boxRadius * 1.8)
    {
        // Color Palette: Heavy Amber / Industrial Monochromatic Orange
        float3 machineColor = float3(1.0, 0.55, 0.0); 
        
        // Overload flash logic
        if (SystemLoad > 0.85 && step(0.5, sin(time * 15.0)) > 0.0)
        {
            machineColor = float3(1.0, 0.2, 0.0); // Warning Red alert flash
        }

        float2 p = (pixelPos - widgetCenter) / boxRadius;
        float mask = 0.0;

        // --- LAYER A: THE COGWHEEL ENGINE (Upper Section) ---
        float2 pCog = p - float2(0.0, -0.2);
        float rCog = length(pCog);
        
        if (rCog < 0.8)
        {
            // Angular rotation setup
            float angle = time * 0.8;
            float cosA = cos(angle); float sinA = sin(angle);
            float2 rotP = float2(pCog.x * cosA - pCog.y * sinA, pCog.x * sinA + pCog.y * cosA);

            float theta = atan2(rotP.y, rotP.x);
            
            // Generate mechanical cog teeth using a square wave on the radial angle
            float teeth = step(0.0, sin(theta * 12.0)); // 12 industrial cog teeth
            float cogRadiusProfile = 0.45 + (teeth * 0.1); 
            
            // Solid cog body minus a cutout ring inside
            float cogBody = step(rCog, cogRadiusProfile) * step(0.28, rCog);
            
            // Internal cross brackets inside the cogwheel hub
            float crossBrackets = step(abs(rotP.x), 0.03) + step(abs(rotP.y), 0.03);
            crossBrackets *= step(rCog, 0.28);
            
            // Central mechanical axle pin
            float centerPin = step(abs(rCog - 0.12), 0.015);

            mask = max(mask, cogBody + crossBrackets + centerPin);
        }

        // --- LAYER B: INDUSTRIAL HAZARD STRIPES (Outer Frame) ---
        // Generates diagonal warning bars locked along the right widget flank
        if (p.x > 0.85 && p.x < 0.98 && abs(p.y) < 1.3)
        {
            float stripes = step(0.5, frac((p.x + p.y) * 4.0 - time * 1.5));
            mask = max(mask, stripes * 0.9);
        }

        // --- LAYER C: COMPUTATIONAL DATA BARS (Lower Section) ---
        // Replaces text boxes with 5 discrete, stepping equalizer telemetry modules
        float2 pBars = p - float2(0.0, 0.65);
        if (abs(pBars.x) < 0.75 && abs(pBars.y) < 0.25)
        {
            // Segment the horizontal landscape into 5 independent bars
            float barID = floor((pBars.x + 0.75) / 0.3);
            float barFraction = frac((pBars.x + 0.75) / 0.3);
            
            // Create padding space between data columns
            float columnMask = step(0.15, barFraction) * step(barFraction, 0.85);
            
            // Assign a unique procedural loading height to each bar linked to System Load
            float barHeightSeed = hash11(barID + timeStep * 0.25);
            float targetHeight = (barHeightSeed * 0.4 + 0.1) * (SystemLoad + 0.5);
            
            // Scale and draw vertical segments
            float normalizedY = (pBars.y + 0.25) / 0.5;
            float verticalFill = step(normalizedY, targetHeight);
            
            // Introduce a blocky pixelated filter to make it look like an old dash grid
            float segmentGrid = step(0.18, frac(normalizedY * 12.0));
            
            mask = max(mask, verticalFill * columnMask * segmentGrid);
        }

        // --- LAYER D: HEAVY RECTILINEAR CROSSHAIRS ---
        // Industrial crosshair ticks locking onto the center component
        float ticksX = step(abs(p.x), 0.005) * (step(abs(p.y + 0.2), 0.95) * step(0.65, abs(p.y + 0.2)));
        float ticksY = step(abs(p.y + 0.2), 0.005) * (step(abs(p.x), 0.95) * step(0.65, abs(p.x)));
        mask = max(mask, ticksX + ticksY);

        // --- GLOBAL CRT RETRO MONITOR SIMULATION ---
        // Microscopic high-density scanning grids across the amber display
        float scanline = sin(pixelPos.y * 2.0) * 0.2 + 0.8;
        
        // Random heavy asset rendering dropouts / frame stutters
        float loadGlitch = 1.0;
        if (randomVal > 0.94) loadGlitch = 0.3; // Sudden low voltage drop

        float3 finalColor = machineColor * mask * scanline * loadGlitch;
        return baseColor + float4(finalColor, 1.0);
    }

    return baseColor;
}

// Technique wrapper
technique MechanicusIndustrialWidget
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_MechanicusWidget;
    }
}
