// Noosphere Visual Cortex Overlay for ReShade 3.8.2
// Simulates an Adeptus Mechanicus data-mesh HUD environment with complex, randomized data matrices.

#include "ReShade.fxh"

// --- Uniform UI Controls ---
uniform float DataGridIntensity <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "Aether Grid Opacity";
    ui_tooltip = "Adjusts the visibility of the calculated sub-orbital data grid lines.";
> = 0.35;

uniform float3 GridColor <
    ui_type = "color";
    ui_label = "Noosphere Frequency Color";
> = float3(0.0, 1.0, 0.4); // Electric Mechanicus Green

uniform float DataAberration <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 5.0;
    ui_label = "Telemetry Distortion";
    ui_tooltip = "Simulates signal degradation and data chromatic misalignment.";
> = 2.5;

uniform float DatagramSpeed <
    ui_type = "slider";
    ui_min = 0.1; ui_max = 5.0;
    ui_label = "Interface Sync Speed";
    ui_tooltip = "Controls how quickly the telemetry components refresh.";
> = 1.5;

// --- ReShade Built-In Timer (Returns time elapsed in milliseconds) ---
uniform float Timer < source = "timer"; >;

// --- Helper Pseudo-Random Noise Functions ---
float DatagramNoise(float2 co)
{
    return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}

float RandomValue(float x)
{
    return frac(sin(x) * 43758.5453);
}

// --- Pixel Shader Logic ---
float4 PS_NoosphereOverlay(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Convert timer from milliseconds to seconds and apply speed multiplier
    float timeSec = (Timer * 0.001) * DatagramSpeed;
    float steppedTime = floor(timeSec * 6.0); // Accelerated refresh frame-rate

    // 1. Fetch split channels to create a digital chromatic aberration effect
    float2 shift = BUFFER_PIXEL_SIZE * DataAberration;
    float colR = tex2D(ReShade::BackBuffer, texcoord - shift).r;
    float colG = tex2D(ReShade::BackBuffer, texcoord).g;
    float colB = tex2D(ReShade::BackBuffer, texcoord + shift).b;
    float3 baseColor = float3(colR, colG, colB);

    // 2. Generate mathematical data grid lines (Phosphor Scanlines & Hex Mesh hybrid)
    float2 gridCoord = texcoord * BUFFER_SCREEN_SIZE;
    
    // Horizontal scanline pattern
    float lineH = frac(gridCoord.y * 0.5);
    float pattern = smoothstep(0.1, 0.9, lineH);

    // Vertical ticker matrix pattern
    float lineV = frac(gridCoord.x * 0.02);
    if (lineV < 0.03) pattern += 0.4;

    // --- Aligned Coordinate Configuration ---
    float2 w1_Min = float2(0.010, 0.16);
    float2 w1_Max = w1_Min + float2(0.20, 0.15);

    float2 w2_Min = float2(0.010, w1_Max.y + 0.02); 
    float2 w2_Max = w2_Min + float2(0.20, 0.10);

    float uiElements = 0.0;

    // Widget 1: Complex Randomized Cryptographic Binary Grid
    if (texcoord.x > w1_Min.x && texcoord.x < w1_Max.x && texcoord.y > w1_Min.y && texcoord.y < w1_Max.y)
    {
        float2 datagramUV = (texcoord - w1_Min) / float2(0.20, 0.15);
        
        float borderThickness = 0.015;
        if (datagramUV.x < borderThickness || datagramUV.x > (1.0 - borderThickness) ||
            datagramUV.y < borderThickness || datagramUV.y > (1.0 - borderThickness))
        {
            uiElements = 0.8;
        }
        
        // Complex structural change: Increased density to 24x12 and added a secondary overlapping code pass
        float2 cellGrid = floor(datagramUV * float2(24.0, 12.0));
        
        // Seed cells with non-linear randomized timelines so blocks update independently rather than uniform blocks
        float cellSeed = DatagramNoise(cellGrid);
        float independentTime = floor(timeSec * (3.0 + cellSeed * 5.0));
        
        float coreNoise = DatagramNoise(cellGrid + float2(independentTime, -independentTime));
        float secondaryNoise = DatagramNoise(cellGrid * 1.5 - float2(independentTime * 0.5, independentTime));
        
        // Layering algorithms to synthesize fake machine code arrays (simulating runes/hex digits)
        if (coreNoise > 0.45 && datagramUV.y < 0.90 && datagramUV.y > 0.10 && datagramUV.x > 0.05 && datagramUV.x < 0.95)
        {
            // Horizontal bar sub-mask variant
            float microGlyph = step(0.3, frac(datagramUV.x * 48.0)) * step(0.2, frac(datagramUV.y * 24.0));
            uiElements = lerp(0.3, 0.75, coreNoise * secondaryNoise * microGlyph);
        }

        // Fast irregular warning interrupt strobe line moving across the grid data
        float syncSweep = frac(timeSec * 1.2);
        if (abs(datagramUV.y - syncSweep) < 0.015)
        {
            uiElements = 0.95;
        }
    }

    // Widget 2: Complex Randomized Vox Frequency Seismograph (Chaotic Atmospheric Audio)
    if (texcoord.x > w2_Min.x && texcoord.x < w2_Max.x && texcoord.y > w2_Min.y && texcoord.y < w2_Max.y)
    {
        float2 voxUV = (texcoord - w2_Min) / float2(0.20, 0.10);
        
        float cornerSize = 0.08;
        bool isCornerX = (voxUV.x < cornerSize || voxUV.x > (1.0 - cornerSize));
        bool isCornerY = (voxUV.y < cornerSize || voxUV.y > (1.0 - cornerSize));
        if ((isCornerX && voxUV.y < 0.04) || (isCornerX && voxUV.y > 0.96) ||
            (isCornerY && voxUV.x < 0.02) || (isCornerY && voxUV.x > 0.98))
        {
            uiElements = 0.7;
        }

        float waveCenter = 0.5;
        
        // Complex structural change: Scrapped standard orderly sines for randomized, jagged multi-frequency harmonics
        float stepX = floor(voxUV.x * 60.0) / 60.0; // Converts wave to high-density digital steps
        
        // Synthesizing randomized frequency noise variables utilizing fractional math
        float noiseFreq1 = sin(stepX * 45.0 + timeSec * 8.2) * RandomValue(floor(timeSec * 2.0) + 1.1);
        float noiseFreq2 = cos(stepX * 110.0 - timeSec * 14.7) * RandomValue(floor(timeSec * 5.0) + 3.4) * 0.4;
        float noiseFreq3 = sin(stepX * 12.0 + timeSec * 3.1) * 0.3;
        
        // Combine into a frantic spike profile that changes dramatically across random updates
        float dynamicAmplitude = 0.12 + 0.18 * RandomValue(steppedTime);
        float totalDisplacement = waveCenter + (noiseFreq1 + noiseFreq2 + noiseFreq3) * dynamicAmplitude;
        
        // Incorporate random sharp signal dropouts/burst spikes over time index parameters
        if(RandomValue(steppedTime + 7.2) > 0.75)
        {
            totalDisplacement += (DatagramNoise(float2(stepX, steppedTime)) - 0.5) * 0.35;
        }

        float traceDistance = abs(voxUV.y - totalDisplacement);
        
        // Sharp rendering boundaries to emphasize digital precision tracking spikes
        if (traceDistance < 0.022)
        {
            uiElements = 0.98; // Core active trace peak
        }
        else if (traceDistance < 0.065)
        {
            uiElements = max(uiElements, 0.35 * (1.0 - (traceDistance / 0.065))); // Proportional fading glow
        }
    }

    // 4. Vignette mask to keep the center of focus clear for tactical engagement
    float2 uvDist = texcoord - float2(0.5, 0.5);
    float vignette = dot(uvDist, uvDist);
    pattern += vignette * 1.5;

    // 5. Extract bright highlights to simulate floating glowing glyphs/blooms
    float luminance = dot(baseColor, float3(0.299, 0.587, 0.114));
    float3 dataGlow = smoothstep(0.6, 1.0, luminance) * GridColor * 0.5;

    // 6. Composite the Aether layers over the base environment map
    float3 finalOverlay = pattern * GridColor * DataGridIntensity;
    float3 finalUI = uiElements * GridColor;
    float3 result = baseColor + finalOverlay + dataGlow + finalUI;

    // Subtle desaturation of real-world tones to emphasize the digital aether overlay
    result = lerp(result, dot(result, float3(0.3, 0.59, 0.11)), 0.15);

    return float4(result, 1.0);
}

// --- Tech-Priest Logic Execution Pipeline ---
technique NoosphereVisualCortex <
    ui_tooltip = "Enables the Adeptus Mechanicus Noosphere HUD interface over physical reality.";
> {
    pass NoospherePass {
        VertexShader = PostProcessVS;
        PixelShader = PS_NoosphereOverlay;
    }
}
