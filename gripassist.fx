/*
    GRIP FOCUS WIDGET
    ReShade 3.8 compatible

    Designed for:
        5760 x 1080
        32:9 / triple-screen style ultrawide

    Concept:
        A restrained sci-fi focus instrument on the LEFT side.
        It reacts to:
          - scene luminance
          - local visual contrast
          - frame time
          - elapsed ReShade/game time
          - deterministic pseudo-random cycles

    No game memory / telemetry required.

    Suggested preset:
        Panel Width       0.115
        Panel Height      0.78
        Panel X           0.018
        Panel Y           0.11
        Opacity            0.72
        Cycle Seconds      7.0
        Geometry Density   1.0
*/

texture2D GripBackBuffer : COLOR;

sampler2D GripBackSampler
{
    Texture = GripBackBuffer;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MagFilter = LINEAR;
    MinFilter = LINEAR;
    MipFilter = LINEAR;
};


// ------------------------------------------------------------
// USER CONTROLS
// ------------------------------------------------------------

uniform bool EnableWidget <
    ui_label = "Enable Focus Widget";
    ui_type = "input";
    ui_category = "GENERAL";
> = true;

uniform float PanelWidth <
    ui_label = "Panel Width";
    ui_type = "slider";
    ui_min = 0.06;
    ui_max = 0.22;
    ui_step = 0.005;
    ui_category = "LAYOUT";
> = 0.115;

uniform float PanelHeight <
    ui_label = "Panel Height";
    ui_type = "slider";
    ui_min = 0.40;
    ui_max = 0.95;
    ui_step = 0.01;
    ui_category = "LAYOUT";
> = 0.78;

uniform float PanelX <
    ui_label = "Panel X";
    ui_type = "slider";
    ui_min = 0.005;
    ui_max = 0.08;
    ui_step = 0.005;
    ui_category = "LAYOUT";
> = 0.018;

uniform float PanelY <
    ui_label = "Panel Y";
    ui_type = "slider";
    ui_min = 0.02;
    ui_max = 0.40;
    ui_step = 0.01;
    ui_category = "LAYOUT";
> = 0.11;

uniform float WidgetOpacity <
    ui_label = "Widget Opacity";
    ui_type = "slider";
    ui_min = 0.10;
    ui_max = 1.0;
    ui_step = 0.01;
    ui_category = "STYLE";
> = 0.72;

uniform float GeometryDensity <
    ui_label = "Geometry Density";
    ui_type = "slider";
    ui_min = 0.35;
    ui_max = 2.0;
    ui_step = 0.05;
    ui_category = "STYLE";
> = 1.0;

uniform float CycleSeconds <
    ui_label = "Random Cycle";
    ui_type = "slider";
    ui_min = 2.0;
    ui_max = 20.0;
    ui_step = 0.5;
    ui_units = "sec";
    ui_category = "RANDOMIZATION";
> = 7.0;

uniform float RandomSeed <
    ui_label = "Random Seed";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 100.0;
    ui_step = 1.0;
    ui_category = "RANDOMIZATION";
> = 17.0;

uniform float3 WidgetColor <
    ui_label = "Widget Color";
    ui_type = "color";
    ui_category = "STYLE";
> = float3(0.10, 0.85, 1.0);

uniform float Glow <
    ui_label = "Glow";
    ui_type = "slider";
    ui_min = 0.0;
    ui_max = 3.0;
    ui_step = 0.05;
    ui_category = "STYLE";
> = 1.15;


// ------------------------------------------------------------
// REFRAME / TIMING
// ------------------------------------------------------------

uniform float Timer <
    source = "timer";
    hidden = true;
>;

uniform float FrameTime <
    source = "frametime";
    hidden = true;
>;

uniform int FrameCount <
    source = "framecount";
    hidden = true;
>;


// ------------------------------------------------------------
// CONSTANTS
// ------------------------------------------------------------

#define PI 3.14159265359
#define TWO_PI 6.28318530718


// ------------------------------------------------------------
// RANDOM / MATH
// ------------------------------------------------------------

float Hash11(float p)
{
    p = frac(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

float Hash21(float2 p)
{
    float3 p3 = frac(float3(p.x, p.y, p.x) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

float RandCycle(float salt)
{
    float cycle = floor(Timer / max(CycleSeconds, 0.1));

    return Hash11(
        cycle +
        RandomSeed * 17.31 +
        salt * 91.17
    );
}

float Luma(float3 c)
{
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}


// ------------------------------------------------------------
// BASIC SDF SHAPES
// ------------------------------------------------------------

float Ring(float2 p, float radius, float thickness)
{
    return abs(length(p) - radius) - thickness;
}

float LineSegment(float2 p, float2 a, float2 b, float thickness)
{
    float2 pa = p - a;
    float2 ba = b - a;

    float h = saturate(dot(pa, ba) / dot(ba, ba));

    return length(pa - ba * h) - thickness;
}

float AngularLine(float2 p, float angle, float lengthValue, float thickness)
{
    float2 dir = float2(cos(angle), sin(angle));

    return LineSegment(
        p,
        float2(0.0, 0.0),
        dir * lengthValue,
        thickness
    );
}

float GlowLine(float d, float width)
{
    return 1.0 - smoothstep(
        0.0,
        width,
        max(d, 0.0)
    );
}


// ------------------------------------------------------------
// SCENE CONTEXT
// ------------------------------------------------------------

float SceneLuminance()
{
    float2 c = float2(0.50, 0.50);

    float3 a = tex2D(GripBackSampler, c).rgb;
    float3 b = tex2D(GripBackSampler, c + float2(0.06, 0.0)).rgb;
    float3 d = tex2D(GripBackSampler, c + float2(-0.06, 0.0)).rgb;
    float3 e = tex2D(GripBackSampler, c + float2(0.0, 0.06)).rgb;
    float3 f = tex2D(GripBackSampler, c + float2(0.0, -0.06)).rgb;

    return saturate(
        (
            Luma(a) +
            Luma(b) +
            Luma(d) +
            Luma(e) +
            Luma(f)
        ) / 5.0
    );
}

float SceneContrast()
{
    float2 c = float2(0.50, 0.50);

    float center = Luma(
        tex2D(GripBackSampler, c).rgb
    );

    float left = Luma(
        tex2D(GripBackSampler, c + float2(-0.08, 0.0)).rgb
    );

    float right = Luma(
        tex2D(GripBackSampler, c + float2(0.08, 0.0)).rgb
    );

    float up = Luma(
        tex2D(GripBackSampler, c + float2(0.0, -0.08)).rgb
    );

    float down = Luma(
        tex2D(GripBackSampler, c + float2(0.0, 0.08)).rgb
    );

    float edge =
        abs(center - left) +
        abs(center - right) +
        abs(center - up) +
        abs(center - down);

    return saturate(edge * 2.5);
}


// ------------------------------------------------------------
// WIDGET
// ------------------------------------------------------------

float3 DrawWidget(
    float2 screenUV,
    float3 originalColor
)
{
    float2 panelMin = float2(
        PanelX,
        PanelY
    );

    float2 panelMax = panelMin + float2(
        PanelWidth,
        PanelHeight
    );

    float2 inside =
        step(panelMin, screenUV) *
        step(screenUV, panelMax);

    float panelMask = inside.x * inside.y;

    if (panelMask <= 0.0)
        return originalColor;


    // --------------------------------------------------------
    // LOCAL PANEL COORDINATES
    // --------------------------------------------------------

    float2 uv =
        (screenUV - panelMin) /
        (panelMax - panelMin);

    float2 p = uv * 2.0 - 1.0;

    // Make geometry more circular despite 32:9 display.
    p.x *= PanelWidth / PanelHeight;


    // --------------------------------------------------------
    // RANDOM STATE
    // --------------------------------------------------------

    float r0 = RandCycle(1.0);
    float r1 = RandCycle(7.0);
    float r2 = RandCycle(19.0);
    float r3 = RandCycle(43.0);

    float cyclePhase =
        frac(Timer / max(CycleSeconds, 0.1));

    float angle =
        Timer * (0.0007 + r0 * 0.0018);


    // --------------------------------------------------------
    // CONTEXT
    // --------------------------------------------------------

    float luminance = SceneLuminance();
    float contrast = SceneContrast();

    // Frame-time-derived activity indicator.
    // This is NOT actual game speed.
    float frameActivity =
        saturate((FrameTime - 8.0) / 16.0);

    float visualEnergy =
        saturate(
            luminance * 0.45 +
            contrast * 0.40 +
            frameActivity * 0.15
        );


    // --------------------------------------------------------
    // COLOR
    // --------------------------------------------------------

    float3 col = WidgetColor;

    float pulse =
        0.75 +
        0.25 * sin(Timer * 0.0025);

    float brightness =
        0.55 +
        visualEnergy * 0.65;

    col *= brightness * pulse;


    // --------------------------------------------------------
    // PANEL BACKGROUND
    // --------------------------------------------------------

    float panelFadeX =
        smoothstep(0.0, 0.08, uv.x) *
        (1.0 - smoothstep(0.91, 1.0, uv.x));

    float panelFadeY =
        smoothstep(0.0, 0.05, uv.y) *
        (1.0 - smoothstep(0.94, 1.0, uv.y));

    float panelAlpha =
        panelFadeX *
        panelFadeY *
        WidgetOpacity *
        0.38;

    float3 result =
        lerp(
            originalColor,
            originalColor * 0.10 + col * 0.025,
            panelAlpha
        );


    // --------------------------------------------------------
    // PANEL BORDER
    // --------------------------------------------------------

    float border =
        1.0 -
        smoothstep(
            0.0,
            0.012,
            min(
                min(uv.x, 1.0 - uv.x),
                min(uv.y, 1.0 - uv.y)
            )
        );

    // Thin vertical spine.
    float spine =
        1.0 -
        smoothstep(
            0.0,
            0.0025,
            abs(uv.x - 0.10)
        );

    result +=
        col *
        (border * 0.18 + spine * 0.12) *
        WidgetOpacity;


    // --------------------------------------------------------
    // PRIMARY ORBIT
    // --------------------------------------------------------

    float2 center =
        float2(
            0.55,
            -0.25
        );

    float2 q = p - center;

    float orbitSize =
        0.27 +
        r1 * 0.06;

    float ring1 =
        Ring(
            q,
            orbitSize,
            0.006
        );

    float ring2 =
        Ring(
            q,
            orbitSize * 0.72,
            0.0035
        );

    float ringGlow =
        GlowLine(ring1, 0.018) +
        GlowLine(ring2, 0.012);

    result +=
        col *
        ringGlow *
        Glow *
        0.42;


    // --------------------------------------------------------
    // RANDOM RADIAL VECTORS
    // --------------------------------------------------------

    float radial1 =
        AngularLine(
            q,
            angle + r2 * TWO_PI,
            orbitSize,
            0.004
        );

    float radial2 =
        AngularLine(
            q,
            angle * -0.71 + r3 * TWO_PI,
            orbitSize * 0.78,
            0.003
        );

    result +=
        col *
        (
            GlowLine(radial1, 0.014) +
            GlowLine(radial2, 0.010)
        ) *
        Glow *
        0.55;


    // --------------------------------------------------------
    // ROTATING SENSOR ARC
    // --------------------------------------------------------

    float a =
        atan2(q.y, q.x);

    float radius =
        length(q);

    float arcStart =
        -PI * 0.8 +
        cyclePhase * TWO_PI;

    float arcEnd =
        arcStart +
        PI * (0.35 + contrast * 0.5);

    // Wrap angle into a usable 0..2PI interval.
    float aa =
        frac((a + PI) / TWO_PI);

    float ss =
        frac((arcStart + PI) / TWO_PI);

    float ee =
        frac((arcEnd + PI) / TWO_PI);

    float arcMask;

    if (ss < ee)
        arcMask =
            step(ss, aa) *
            step(aa, ee);
    else
        arcMask =
            step(ss, aa) +
            step(aa, ee);

    float arcRadius =
        abs(radius - (orbitSize * 1.13));

    float arc =
        arcMask *
        (1.0 - smoothstep(
            0.0,
            0.018,
            arcRadius
        ));

    result +=
        col *
        arc *
        (0.35 + visualEnergy * 0.65) *
        Glow;


    // --------------------------------------------------------
    // CONTEXT BAR ARRAY
    // --------------------------------------------------------

    // Three vertical data bars.
    float barArea =
        step(0.16, uv.x) *
        step(uv.x, 0.84) *
        step(0.60, uv.y) *
        step(uv.y, 0.87);

    float localX = frac((uv.x - 0.16) / 0.18);

    float barIndex =
        floor((uv.x - 0.16) / 0.18);

    float barRandom =
        Hash11(
            barIndex +
            floor(Timer / max(CycleSeconds, 0.1)) * 3.7
        );

    float barValue;

    if (barIndex < 1.0)
        barValue = luminance;

    else if (barIndex < 2.0)
        barValue = contrast;

    else
        barValue = frameActivity;


    float barShape =
        step(0.0, localX) *
        step(localX, 0.65) *
        step(
            1.0 - barValue,
            uv.y
        );

    barShape *=
        1.0 -
        smoothstep(
            0.0,
            0.015,
            abs(localX - 0.32)
        );


    result +=
        col *
        barShape *
        (0.35 + barRandom * 0.35) *
        Glow;


    // --------------------------------------------------------
    // HORIZONTAL SCAN LINES
    // --------------------------------------------------------

    float scan =
        abs(
            frac(
                uv.y * 24.0 +
                Timer * 0.0008
            ) - 0.5
        );

    scan =
        1.0 -
        smoothstep(
            0.44,
            0.50,
            scan
        );

    scan *=
        0.025 +
        visualEnergy * 0.055;

    result += col * scan;


    // --------------------------------------------------------
    // RANDOM TICKS
    // --------------------------------------------------------

    float tickX =
        frac(uv.x * 18.0);

    float tickY =
        frac(uv.y * 42.0);

    float ticks =
        step(0.88, tickX) *
        step(0.30, tickY);

    float tickRandom =
        Hash21(
            floor(uv * float2(18.0, 42.0)) +
            floor(Timer / max(CycleSeconds, 0.1))
        );

    ticks *= step(0.63, tickRandom);

    result +=
        col *
        ticks *
        0.18 *
        GeometryDensity;


    // --------------------------------------------------------
    // FOCUS PULSE
    // --------------------------------------------------------

    float focusWave =
        frac(
            cyclePhase +
            length(q) * 1.4
        );

    float focusRing =
        1.0 -
        smoothstep(
            0.0,
            0.025,
            abs(focusWave - 0.5)
        );

    result +=
        col *
        focusRing *
        0.045 *
        visualEnergy;


    // --------------------------------------------------------
    // EDGE ACCENT
    // --------------------------------------------------------

    float edgeAccent =
        smoothstep(
            0.78,
            1.0,
            visualEnergy
        );

    result +=
        col *
        edgeAccent *
        0.025;


    return result;
}


// ------------------------------------------------------------
// VERTEX SHADER
// ------------------------------------------------------------

struct GripVSOut
{
    float4 pos : SV_Position;
    float2 texcoord : TEXCOORD0;
};

GripVSOut GripPostProcessVS(uint id : SV_VertexID)
{
    GripVSOut output;

    float2 pos;

    if (id == 0)
        pos = float2(-1.0, 1.0);

    else if (id == 1)
        pos = float2(3.0, 1.0);

    else
        pos = float2(-1.0, -3.0);

    output.pos = float4(pos, 0.0, 1.0);

    output.texcoord =
        pos * float2(0.5, -0.5) +
        0.5;

    return output;
}


// ------------------------------------------------------------
// PIXEL SHADER
// ------------------------------------------------------------

float4 GripFocusPS(
    float4 position : SV_Position,
    float2 texcoord : TEXCOORD0
) : SV_Target
{
    float4 source =
        tex2D(
            GripBackSampler,
            texcoord
        );

    if (!EnableWidget)
        return source;

    float3 output =
        DrawWidget(
            texcoord,
            source.rgb
        );

    return float4(
        saturate(output),
        source.a
    );
}


// ------------------------------------------------------------
// TECHNIQUE
// ------------------------------------------------------------

technique GRIP_FOCUS_WIDGET
<
    ui_label = "GRIP Focus Widget";
    ui_tooltip =
        "Context-reactive geometric focus instrument designed for 5760x1080 ultrawide.";
>
{
    pass
    {
        VertexShader = GripPostProcessVS;
        PixelShader = GripFocusPS;
    }
}
