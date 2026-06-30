// Color Dimension Expansion Shader for ReShade
// Maps RGB to a 9D Polynomial Space before projecting back to 3D

#include "ReShade.fxh"

// --- UI Controls ---
uniform float TuningIntensity <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0;
    ui_label = "Effect Intensity";
    ui_tooltip = "Blends between the original image and the dimension-expanded output.";
> = 1.0;

uniform float3 RedWeights_Linear <
    ui_type = "slider";
    ui_min = -2.0; ui_max = 2.0;
    ui_label = "Red Channel: Linear Weights (RGB)";
> = float3(1.0, 0.0, 0.0);

uniform float3 RedWeights_Polynomial <
    ui_type = "slider";
    ui_min = -2.0; ui_max = 2.0;
    ui_label = "Red Channel: Poly Weights (R², G², B²)";
> = float3(0.0, 0.0, 0.0);

uniform float3 RedWeights_Interaction <
    ui_type = "slider";
    ui_min = -2.0; ui_max = 2.0;
    ui_label = "Red Channel: Interaction (RG, GB, BR)";
> = float3(0.0, 0.0, 0.0);

uniform float3 GreenWeights_Linear <
    ui_type = "slider";
    ui_min = -2.0; ui_max = 2.0;
    ui_label = "Green Channel: Linear Weights (RGB)";
> = float3(0.0, 1.0, 0.0);

uniform float3 GreenWeights_Polynomial <
    ui_type = "slider";
    ui_min = -2.0; ui_max = 2.0;
    ui_label = "Green Channel: Poly Weights (R², G², B²)";
> = float3(0.0, 0.0, 0.0);

uniform float3 GreenWeights_Interaction <
    ui_type = "slider";
    ui_min = -2.0; ui_max = 2.0;
    ui_label = "Green Channel: Interaction (RG, GB, BR)";
> = float3(0.0, 0.0, 0.0);

uniform float3 BlueWeights_Linear <
    ui_type = "slider";
    ui_min = -2.0; ui_max = 2.0;
    ui_label = "Blue Channel: Linear Weights (RGB)";
> = float3(0.0, 0.0, 1.0);

uniform float3 BlueWeights_Polynomial <
    ui_type = "slider";
    ui_min = -2.0; ui_max = 2.0;
    ui_label = "Blue Channel: Poly Weights (R², G², B²)";
> = float3(0.0, 0.0, 0.0);

uniform float3 BlueWeights_Interaction <
    ui_type = "slider";
    ui_min = -2.0; ui_max = 2.0;
    ui_label = "Blue Channel: Interaction (RG, GB, BR)";
> = float3(0.0, 0.0, 0.0);


// --- Pixel Shader ---
float4 PS_DimensionExpansion(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float4 originalColor = tex2D(ReShade::BackBuffer, texcoord);
    float3 rgb = originalColor.rgb;

    // 1. Map 3D RGB into 9D Polynomial Space
    // Dim 1-3: Linear components
    float3 linearDim = rgb; 
    // Dim 4-6: Pure polynomial squares
    float3 polyDim   = rgb * rgb; 
    // Dim 7-9: Cross-channel interaction terms
    float3 interactDim = float3(rgb.r * rgb.g, rgb.g * rgb.b, rgb.b * rgb.r); 

    // 2. Project 9D space back down to 3D RGB using dot products (matrix multiplication)
    float3 expandedRGB;
    
    expandedRGB.r = dot(linearDim, RedWeights_Linear) + 
                    dot(polyDim, RedWeights_Polynomial) + 
                    dot(interactDim, RedWeights_Interaction);
                    
    expandedRGB.g = dot(linearDim, GreenWeights_Linear) + 
                    dot(polyDim, GreenWeights_Polynomial) + 
                    dot(interactDim, GreenWeights_Interaction);
                    
    expandedRGB.b = dot(linearDim, BlueWeights_Linear) + 
                    dot(polyDim, BlueWeights_Polynomial) + 
                    dot(interactDim, BlueWeights_Interaction);

    // 3. Clamp colors to valid ranges and mix based on intensity
    expandedRGB = saturate(expandedRGB);
    float3 finalColor = lerp(rgb, expandedRGB, TuningIntensity);

    return float4(finalColor, originalColor.a);
}

// --- Techniques ---
technique ColorDimensionExpansion
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_DimensionExpansion;
    }
}
