/*
    CRT_1999_GRIP.fx
    ReShade 3.8 compatible

    1999-style PC CRT effect for GRIP: Combat Racing

    Curvature:
      0.00  = flat
      +     = convex / barrel
      -     = concave / pincushion

    Designed to remain relatively subtle and preserve
    GRIP's sharp neon lighting.
*/

#include "ReShade.fxh"


// ============================================================
// SCREEN GEOMETRY
// ============================================================

uniform float Curvature <
    ui_type = "slider";
    ui_min = -0.30;
    ui_max = 0.30;
    ui_tooltip = "Negative = concave/pincushion, Positive = convex/barrel.";
> = 0.06;


uniform float Overscan <
    ui_type = "slider";
    ui_min = 0.950;
    ui_max = 1.100;
    ui_tooltip = "Zooms the image to compensate for CRT curvature.";
> = 1.010;


uniform float EdgeDarkening <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_tooltip = "Darkens the outer edges of the CRT glass.";
> = 0.12;


// ============================================================
// BRIGHTNESS / CONTRAST / COLOR
// ============================================================

uniform float Brightness <
    ui_type = "slider";
    ui_min = -0.30;
    ui_max = 0.30;
    ui_tooltip = "Overall brightness.";
> = 0.015;


uniform float Contrast <
    ui_type = "slider";
    ui_min = 0.50;
    ui_max = 1.50;
    ui_tooltip = "Overall image contrast.";
> = 1.06;


uniform float Saturation <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 2.0;
    ui_tooltip = "Color saturation.";
> = 1.03;


uniform float CRTWarmth <
    ui_type = "slider";
    ui_min = -1.0;
    ui_max = 1.0;
    ui_tooltip = "Slight warm/cool CRT phosphor tint.";
> = 0.04;


// ============================================================
// SCANLINES
// ============================================================

uniform float ScanlineStrength <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_tooltip = "Darkness of the horizontal scanlines.";
> = 0.09;


uniform float ScanlineSize <
    ui_type = "slider";
    ui_min = 1.0;
    ui_max = 4.0;
    ui_tooltip = "Vertical size of the scanline pattern.";
> = 2.0;


uniform float ScanlineSharpness <
    ui_type = "slider";
    ui_min = 1.0;
    ui_max = 16.0;
    ui_tooltip = "Sharpness of scanlines.";
> = 7.0;


// ============================================================
// PHOSPHOR / SHADOW MASK
// ============================================================

uniform float ShadowMask <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_tooltip = "RGB phosphor/shadow-mask visibility.";
> = 0.06;


uniform float PhosphorSize <
    ui_type = "slider";
    ui_min = 1.0;
    ui_max = 6.0;
    ui_tooltip = "Size of RGB phosphor groups.";
> = 2.0;


// ============================================================
// RGB CONVERGENCE
// ============================================================

uniform float RGBSeparation <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 3.0;
    ui_tooltip = "Simulates slight CRT RGB beam separation.";
> = 0.10;


// ============================================================
// CRT SOFTNESS
// ============================================================

uniform float Softness <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_tooltip = "Softens the image like an analog CRT.";
> = 0.05;


// ============================================================
// BLOOM
// ============================================================

uniform float BloomStrength <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_tooltip = "Glow around bright CRT highlights.";
> = 0.10;


uniform float BloomRadius <
    ui_type = "slider";
    ui_min = 0.5;
    ui_max = 4.0;
    ui_tooltip = "Size of CRT highlight glow.";
> = 1.25;


// ============================================================
// VIGNETTE
// ============================================================

uniform float VignetteStrength <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 1.0;
    ui_tooltip = "Darkens the corners of the CRT.";
> = 0.08;


uniform float VignetteRoundness <
    ui_type = "slider";
    ui_min = 0.5;
    ui_max = 2.0;
    ui_tooltip = "Shape of the CRT corner falloff.";
> = 1.15;


// ============================================================
// ANALOG NOISE
// ============================================================

uniform float NoiseStrength <
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 0.10;
    ui_tooltip = "Very subtle analog CRT noise.";
> = 0.008;


// ============================================================
// CURVED SCREEN UV
// ============================================================

float2 CRTCurve(float2 uv)
{
    float2 p = uv - 0.5;

    float aspect = ReShade::ScreenSize.x /
                   ReShade::ScreenSize.y;

    p.x = p.x * aspect;

    float r2 = dot(p, p);

    p = p * (1.0 + Curvature * r2);

    p.x = p.x / aspect;

    p = p / Overscan;

    return p + 0.5;
}


// ============================================================
// VIGNETTE
// ============================================================

float CRTVignette(float2 uv)
{
    float2 p = uv - 0.5;

    float aspect = ReShade::ScreenSize.x /
                   ReShade::ScreenSize.y;

    p.x = p.x * aspect;

    float distanceFromCenter = length(p);

    distanceFromCenter =
        saturate(distanceFromCenter * 1.55);

    distanceFromCenter =
        pow(distanceFromCenter, VignetteRoundness);

    return 1.0 -
           distanceFromCenter * VignetteStrength;
}


// ============================================================
// PHOSPHOR MASK
// ============================================================

float3 CRTPhosphor(float2 uv)
{
    float x =
        uv.x * ReShade::ScreenSize.x;

    float group =
        floor(x / PhosphorSize);

    float phase =
        group - floor(group / 3.0) * 3.0;

    float3 mask;

    if (phase < 1.0)
    {
        mask = float3(1.0, 0.86, 0.86);
    }
    else if (phase < 2.0)
    {
        mask = float3(0.86, 1.0, 0.86);
    }
    else
    {
        mask = float3(0.86, 0.86, 1.0);
    }

    return lerp(
        float3(1.0, 1.0, 1.0),
        mask,
        ShadowMask
    );
}


// ============================================================
// SIMPLE NOISE
// ============================================================

float CRTNoise(float2 uv)
{
    float n =
        sin(
            dot(
                uv * ReShade::ScreenSize.xy,
                float2(12.9898, 78.233)
            )
        );

    n = n * 43758.5453;

    return frac(n);
}


// ============================================================
// MAIN PIXEL SHADER
// ============================================================

float4 PS_CRT(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD
) : SV_Target
{
    // --------------------------------------------------------
    // CURVED CRT SCREEN
    // --------------------------------------------------------

    float2 uv = CRTCurve(texcoord);


    // Black outside the CRT surface
    if (uv.x < 0.0 ||
        uv.x > 1.0 ||
        uv.y < 0.0 ||
        uv.y > 1.0)
    {
        return float4(0.0, 0.0, 0.0, 1.0);
    }


    // --------------------------------------------------------
    // PIXEL SIZE
    // --------------------------------------------------------

    float2 pixelSize =
        1.0 / ReShade::ScreenSize.xy;


    // --------------------------------------------------------
    // RGB BEAM SEPARATION
    // --------------------------------------------------------

    float rgbOffset =
        RGBSeparation *
        pixelSize.x;


    float red =
        tex2D(
            ReShade::BackBuffer,
            saturate(
                uv + float2(rgbOffset, 0.0)
            )
        ).r;


    float green =
        tex2D(
            ReShade::BackBuffer,
            uv
        ).g;


    float blue =
        tex2D(
            ReShade::BackBuffer,
            saturate(
                uv - float2(rgbOffset, 0.0)
            )
        ).b;


    float3 color =
        float3(red, green, blue);


    // --------------------------------------------------------
    // CRT SOFTNESS
    // --------------------------------------------------------

    float3 softColor =
        tex2D(
            ReShade::BackBuffer,
            saturate(
                uv + float2(pixelSize.x, 0.0)
            )
        ).rgb;


    softColor +=
        tex2D(
            ReShade::BackBuffer,
            saturate(
                uv - float2(pixelSize.x, 0.0)
            )
        ).rgb;


    softColor +=
        tex2D(
            ReShade::BackBuffer,
            saturate(
                uv + float2(0.0, pixelSize.y)
            )
        ).rgb;


    softColor +=
        tex2D(
            ReShade::BackBuffer,
            saturate(
                uv - float2(0.0, pixelSize.y)
            )
        ).rgb;


    softColor *= 0.25;


    color =
        lerp(
            color,
            softColor,
            Softness
        );


    // --------------------------------------------------------
    // BRIGHTNESS
    // --------------------------------------------------------

    color += Brightness;


    // --------------------------------------------------------
    // CONTRAST
    // --------------------------------------------------------

    color =
        (color - 0.5) *
        Contrast +
        0.5;


    // --------------------------------------------------------
    // SATURATION
    // --------------------------------------------------------

    float luminance =
        dot(
            color,
            float3(
                0.299,
                0.587,
                0.114
            )
        );


    color =
        lerp(
            float3(
                luminance,
                luminance,
                luminance
            ),
            color,
            Saturation
        );


    // --------------------------------------------------------
    // CRT WARMTH
    // --------------------------------------------------------

    color.r +=
        CRTWarmth * 0.025;

    color.b -=
        CRTWarmth * 0.025;


    // --------------------------------------------------------
    // SCANLINES
    // --------------------------------------------------------

    float screenY =
        uv.y *
        ReShade::ScreenSize.y;


    float scanPosition =
        screenY / ScanlineSize;


    float scanLine =
        abs(
            frac(scanPosition) -
            0.5
        ) * 2.0;


    scanLine =
        pow(
            scanLine,
            ScanlineSharpness
        );


    float scanMultiplier =
        lerp(
            1.0 - ScanlineStrength,
            1.0,
            scanLine
        );


    color *= scanMultiplier;


    // --------------------------------------------------------
    // RGB PHOSPHOR MASK
    // --------------------------------------------------------

    color *=
        CRTPhosphor(uv);


    // --------------------------------------------------------
    // CRT BLOOM
    // --------------------------------------------------------

    float2 bloomOffset =
        pixelSize *
        BloomRadius;


    float3 bloom =
        tex2D(
            ReShade::BackBuffer,
            saturate(
                uv + float2(
                    bloomOffset.x,
                    0.0
                )
            )
        ).rgb;


    bloom +=
        tex2D(
            ReShade::BackBuffer,
            saturate(
                uv - float2(
                    bloomOffset.x,
                    0.0
                )
            )
        ).rgb;


    bloom +=
        tex2D(
            ReShade::BackBuffer,
            saturate(
                uv + float2(
                    0.0,
                    bloomOffset.y
                )
            )
        ).rgb;


    bloom +=
        tex2D(
            ReShade::BackBuffer,
            saturate(
                uv - float2(
                    0.0,
                    bloomOffset.y
                )
            )
        ).rgb;


    bloom *= 0.25;


    float bloomLuminance =
        dot(
            bloom,
            float3(
                0.299,
                0.587,
                0.114
            )
        );


    float bloomAmount =
        saturate(
            (bloomLuminance - 0.55) *
            2.0
        );


    color +=
        bloom *
        bloomAmount *
        BloomStrength;


    // --------------------------------------------------------
    // EDGE DARKENING
    // --------------------------------------------------------

    float2 edge =
        abs(uv - 0.5) * 2.0;


    float edgeAmount =
        max(
            edge.x,
            edge.y
        );


    edgeAmount =
        pow(
            saturate(edgeAmount),
            3.0
        );


    color *=
        1.0 -
        edgeAmount *
        EdgeDarkening;


    // --------------------------------------------------------
    // VIGNETTE
    // --------------------------------------------------------

    color *=
        CRTVignette(uv);


    // --------------------------------------------------------
    // ANALOG NOISE
    // --------------------------------------------------------

    float noise =
        CRTNoise(uv) -
        0.5;


    color +=
        noise *
        NoiseStrength;


    // --------------------------------------------------------
    // FINAL OUTPUT
    // --------------------------------------------------------

    color =
        saturate(color);


    return float4(
        color,
        1.0
    );
}


// ============================================================
// TECHNIQUE
// ============================================================

technique CRT_1999
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_CRT;
    }
}
