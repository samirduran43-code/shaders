#include "ReShade.fxh"

// --- Uniform UI Tweakables (Parameters Config) ---
uniform float3 WidgetColor < ui_type = "color"; ui_label = "Data Tint"; > = float3(0.0, 1.0, 0.86);
uniform float ScanlineIntensity < ui_type = "slider"; ui_min = 0.0; ui_max = 1.0; ui_label = "Line Opacity"; > = 0.25;
uniform float DeformationAmount < ui_type = "slider"; ui_min = 0.0; ui_max = 0.5; ui_label = "Instability"; > = 0.15;

uniform float LoopInterval_A <
    ui_type = "slider";
    ui_min = 0.5; ui_max = 5.0;
    ui_label = "Spike Interval (a Seconds)";
> = 2.0;

uniform int MaxSpikes_N <
    ui_type = "slider";
    ui_min = 1; ui_max = 8;
    ui_label = "Spike Density (n Count)";
> = 4;

uniform float Timer < source = "timer"; >;

texture NoosphereTex : COLOR;
sampler NoosphereSampler { Texture = NoosphereTex; };

// --- Deterministic Pseudo-Random Hash Functions ---
float Hash11(float p) { return frac(sin(p * 127.1) * 43758.5453); }
float Hash22(float2 p) { return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }

// Generates an independent 2D point based on an iteration seed index
float2 GetRandomLocation(float seed, int index)
{
    float x = Hash11(seed + float(index) * 15.43);
    float y = Hash11(seed + float(index) * 73.91 + 4.2);
    return float2(x, y);
}

float Noise2D(float2 p) {
    float2 i = floor(p), f = frac(p), u = f * f * (3.0 - 2.0 * f);
    return lerp(lerp(Hash22(i), Hash22(i + float2(1,0)), u.x), lerp(Hash22(i + float2(0,1)), Hash22(i + float2(1,1)), u.x), u.y);
}

float DrawSeg(float2 p, float2 a, float2 b) {
    float2 pa = p - a, ba = b - a;
    return smoothstep(0.02, 0.005, length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0)));
}

float GetChar(int idx, float2 uv) {
    float s = 0.0;
    if(idx == 0) { s += DrawSeg(uv, float2(0.1, 0.1), float2(0.1, 0.9)) + DrawSeg(uv, float2(0.1, 0.5), float2(0.8, 0.9)) + DrawSeg(uv, float2(0.1, 0.5), float2(0.8, 0.1)); }
    else if(idx == 1 || idx == 7) { s += DrawSeg(uv, float2(0.1, 0.1), float2(0.9, 0.1)) + DrawSeg(uv, float2(0.9, 0.1), float2(0.9, 0.9)) + DrawSeg(uv, float2(0.9, 0.9), float2(0.1, 0.9)) + DrawSeg(uv, float2(0.1, 0.9), float2(0.1, 0.1)); }
    else if(idx == 2) { s += DrawSeg(uv, float2(0.1, 0.1), float2(0.1, 0.9)) + DrawSeg(uv, float2(0.1, 0.9), float2(0.9, 0.9)); }
    else if(idx == 3) { s += DrawSeg(uv, float2(0.1, 0.1), float2(0.1, 0.9)) + DrawSeg(uv, float2(0.9, 0.1), float2(0.9, 0.9)) + DrawSeg(uv, float2(0.9, 0.1), float2(0.1, 0.9)); }
    else if(idx == 4 || idx == 6) { s += DrawSeg(uv, float2(0.1, 0.9), float2(0.9, 0.9)) + DrawSeg(uv, float2(0.5, 0.1), float2(0.5, 0.9)); }
    else if(idx == 5) { s += DrawSeg(uv, float2(0.1, 0.1), float2(0.1, 0.9)) + DrawSeg(uv, float2(0.1, 0.9), float2(0.9, 0.9)) + DrawSeg(uv, float2(0.9, 0.9), float2(0.9, 0.1)) + DrawSeg(uv, float2(0.1, 0.5), float2(0.9, 0.5)); }
    else if(idx == 8) { s += DrawSeg(uv, float2(0.1, 0.1), float2(0.1, 0.9)) + DrawSeg(uv, float2(0.1, 0.9), float2(0.9, 0.9)) + DrawSeg(uv, float2(0.9, 0.9), float2(0.9, 0.5)) + DrawSeg(uv, float2(0.9, 0.5), float2(0.1, 0.5)); }
    return saturate(s);
}

float4 PS_NoosphereWidget(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target {
    float tTot = Timer * 0.001;
    
    if (uv.x < 0.80 || uv.y < 0.80) return tex2D(NoosphereSampler, uv);
    float2 wUV = (uv - 0.80) / 0.20;

    // =========================================================================
    // MODULO-DRIVEN INDEPENDENT MULTI-SPIKE ENGINE
    // =========================================================================
    // Explicit requested modulo function tracking time loops
    float timeRemainder = tTot % LoopInterval_A;
    float currentLoopID = floor(tTot / LoopInterval_A);
    
    // An independent base seed unique to this exact time block
    float loopSeed = Hash11(currentLoopID * 23.41);
    
    // Shockwave decay tracking: Instantly flares at 0 seconds, fades fast over 0.25 seconds
    float spikeLifeEnvelope = max(0.0, 1.0 - (timeRemainder / 0.25));

    float overallSpikeMask = 0.0;
    float2 coordinateTearOffset = float2(0.0, 0.0);

    // Unrolled execution loop generating exactly 'n' independent random positions
    for (int i = 0; i < 8; i++)
    {
        // Safety guard for old ReShade compilers requiring static loop limits
        if (i >= MaxSpikes_N) break;

        // Fetch completely separate X, Y coordinates for this loop pass iteration
        float2 targetLoc = GetRandomLocation(loopSeed, i);
        
        // Calculate distance from current screen pixel to this unique spike center
        float distToSpike = length(wUV - targetLoc);
        
        // Render local lightning-like flares centered exactly over the random point
        float pointFlare = smoothstep(0.04, 0.001, distToSpike) * spikeLifeEnvelope;
        overallSpikeMask = max(overallSpikeMask, pointFlare);
        
        // Generate random vector offset directions for spatial tearing relative to this point
        if (distToSpike < 0.05)
        {
            float tearDirection = Hash11(loopSeed + float(i) * 31.7);
            coordinateTearOffset += float2(tearDirection - 0.5, 0.0) * 0.03 * spikeLifeEnvelope;
        }
    }
    // =========================================================================

    float2 finalSampleUV = uv + coordinateTearOffset;
    float4 bCol = tex2D(NoosphereSampler, finalSampleUV);
    float2 pOff = float2(1.0 / BUFFER_WIDTH, 1.0 / BUFFER_HEIGHT);
    
    float bL = dot(bCol.rgb, float3(0.299, 0.587, 0.114));
    float rL = dot(tex2D(NoosphereSampler, finalSampleUV + float2(pOff.x, 0)).rgb, float3(0.299, 0.587, 0.114));
    float dL = dot(tex2D(NoosphereSampler, finalSampleUV + float2(0, pOff.y)).rgb, float3(0.299, 0.587, 0.114));
    float eVal = smoothstep(0.05, 0.25, abs(bL - rL) + abs(bL - dL));
    float cGrid = lerp(1.0, sin(wUV.y * BUFFER_HEIGHT * 0.2) * sin(wUV.x * BUFFER_WIDTH * 0.2) * 0.25 + 0.75, ScanlineIntensity);

    float2 p = (wUV - 0.5) * 2.0; p.x *= (BUFFER_WIDTH / BUFFER_HEIGHT);
    float tRad = 0.42 + (Noise2D(float2(cos(atan2(p.y, p.x)), sin(atan2(p.y, p.x))) * 3.0 + (tTot * 4.0)) * DeformationAmount) + (overallSpikeMask * 0.15);

    float sMsk = 0.0; float3 sFB = float3(0,0,0);
    if (length(p) < tRad && wUV.y > 0.18) {
        float3 n = normalize(float3(p.x, p.y, sqrt(max(0.0, tRad * tRad - dot(p,p)))));
        float sT = floor((tTot * 4.0) * 3.0) / 3.0, cT = cos(sT * 0.2), sT_ = sin(sT * 0.2);
        float3 rN = float3(n.x * cT - n.z * sT_, n.y, n.x * sT_ + n.z * cT);
        float lat = (frac(rN.y * 5.0 + (tTot * 4.0) * 0.2) > 0.85 || frac(rN.x * 5.0 - (tTot * 4.0) * 0.1) > 0.85) ? 1.0 : 0.0;
        sFB = (lat + pow(1.0 - dot(n, float3(0,0,1)), 2.5) * 2.0 + Hash22(wUV + frac(tTot * 4.0)) * 0.35) * WidgetColor;
        sMsk = 1.0;
    }

    float tMsk = 0.0;
    if (wUV.y >= 0.05 && wUV.y <= 0.15 && wUV.x >= 0.06 && wUV.x <= 0.94) {
        float tProg = (wUV.x - 0.06) / 0.88, cIdx = tProg * 9.0;
        float2 lUV = float2(frac(cIdx), (wUV.y - 0.05) / 0.10); lUV.x = (lUV.x - 0.15) / 0.70;
        if(lUV.x >= 0.0 && lUV.x <= 1.0) tMsk = GetChar(floor(cIdx), lUV);
    }
    
    if (overallSpikeMask > 0.3 && wUV.y < 0.20) tMsk = (Hash22(wUV * tTot) > 0.5) ? 1.0 : 0.0;

    float3 mixO = lerp((bL * WidgetColor + eVal * WidgetColor * 1.8) * cGrid, sFB, sMsk * 0.90);
    mixO = lerp(mixO, WidgetColor * 2.0, tMsk);
    
    // Inject the independent multi-spike bursts directly over the composited buffer
    float3 burstEnergy = float3(1.0, 1.0, 1.0) * overallSpikeMask * 2.5;
    return float4(mixO + burstEnergy, 1.0);
}

technique Noosphere_Widget_Overlay {
    pass { VertexShader = PostProcessVS; PixelShader = PS_NoosphereWidget; }
}
