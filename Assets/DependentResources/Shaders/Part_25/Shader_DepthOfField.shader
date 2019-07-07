Shader "Custom/Camera/DepthOfField" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }
    //---------------------------------------------------------------------------------------------------
    CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex, _CameraDepthTexture, _CoCTex, _DoFTex;
        float4 _MainTex_TexelSize;
        float _FocusDistance, _FocusRange, _BokehRadius;
        //---------------------------------------------------------------------------------------------------
        struct VertexData {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };
        //---------------------------------------------------------------------------------------------------
        struct Interpolators {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
        };
        //---------------------------------------------------------------------------------------------------
        Interpolators vert (VertexData v) {
            Interpolators i;
            i.pos = UnityObjectToClipPos(v.vertex);
            i.uv = v.uv;
            return i;
        }
    ENDCG
    //---------------------------------------------------------------------------------------------------
    SubShader {
        Cull Off
        ZTest Always
        ZWrite Off
        //---------------------------------------------------------------------------------------------------
        Pass { // Circle of Confusion
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half frag (Interpolators i) : SV_Target {
                half depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                depth = LinearEyeDepth(depth);
                float coc = (depth - _FocusDistance) / _FocusRange;
                coc = clamp(coc, -1, 1);

                // if (coc < 0) {
                //     return coc * half4(-1, 0, 0, -1); // need to return half4
                // }
                // return coc;
                // Black = in focus
                // White = too far from the camera
                // Red   = too close to the camera

                return coc * _BokehRadius;
            }
            ENDCG
        }
        //---------------------------------------------------------------------------------------------------
        Pass { // Pre-Filter
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half4 frag (Interpolators i) : SV_Target {
                float4 o = _MainTex_TexelSize.xyxy * float2(-0.5, 0.5).xxyy;
                half coc0 = tex2D(_CoCTex, i.uv + o.xy).r;
                half coc1 = tex2D(_CoCTex, i.uv + o.zy).r;
                half coc2 = tex2D(_CoCTex, i.uv + o.xw).r;
                half coc3 = tex2D(_CoCTex, i.uv + o.zw).r;
                half cocMin = min(min(min(coc0, coc1), coc2), coc3);
                half cocMax = max(max(max(coc0, coc1), coc2), coc3);
                half coc = cocMax >= -cocMin ? cocMax : cocMin;
                return half4(tex2D(_MainTex, i.uv).rgb, coc);
            }
            ENDCG
        }
        //---------------------------------------------------------------------------------------------------
        Pass { // Bokeh
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define BOKEH_KERNEL_MEDIUM
            // From https://github.com/Unity-Technologies/PostProcessing/
            // blob/v2/PostProcessing/Shaders/Builtins/DiskKernels.hlsl
            #if defined(BOKEH_KERNEL_SMALL)
            static const int kernelSampleCount = 16;
            static const float2 kernel[kernelSampleCount] = {
                float2(0, 0),
                float2(0.54545456, 0),
                float2(0.16855472, 0.5187581),
                float2(-0.44128203, 0.3206101),
                float2(-0.44128197, -0.3206102),
                float2(0.1685548, -0.5187581),
                float2(1, 0),
                float2(0.809017, 0.58778524),
                float2(0.30901697, 0.95105654),
                float2(-0.30901703, 0.9510565),
                float2(-0.80901706, 0.5877852),
                float2(-1, 0),
                float2(-0.80901694, -0.58778536),
                float2(-0.30901664, -0.9510566),
                float2(0.30901712, -0.9510565),
                float2(0.80901694, -0.5877853),
            };
            #elif defined (BOKEH_KERNEL_MEDIUM)
            static const int kernelSampleCount = 22;
            static const float2 kernel[kernelSampleCount] = {
                float2(0, 0),
                float2(0.53333336, 0),
                float2(0.3325279, 0.4169768),
                float2(-0.11867785, 0.5199616),
                float2(-0.48051673, 0.2314047),
                float2(-0.48051673, -0.23140468),
                float2(-0.11867763, -0.51996166),
                float2(0.33252785, -0.4169769),
                float2(1, 0),
                float2(0.90096885, 0.43388376),
                float2(0.6234898, 0.7818315),
                float2(0.22252098, 0.9749279),
                float2(-0.22252095, 0.9749279),
                float2(-0.62349, 0.7818314),
                float2(-0.90096885, 0.43388382),
                float2(-1, 0),
                float2(-0.90096885, -0.43388376),
                float2(-0.6234896, -0.7818316),
                float2(-0.22252055, -0.974928),
                float2(0.2225215, -0.9749278),
                float2(0.6234897, -0.7818316),
                float2(0.90096885, -0.43388376),
            };
            #endif
            //---------------------------------------------------------------------------------------------------
            half Weigh (half coc, half radius) {
                return saturate((coc - radius + 2) / 2);
            }
            //---------------------------------------------------------------------------------------------------
            half4 frag (Interpolators i) : SV_Target {
                half3 color = 0;
                half weight = 0;
                for (int k = 0; k < kernelSampleCount; k++) {
                    float2 o = kernel[k] * _BokehRadius;
                    half radius = length(o);
                    o *= _MainTex_TexelSize.xy;
                    half4 s = tex2D(_MainTex, i.uv + o);
                    half sw = Weigh(abs(s.a), radius);
                    color += s.rgb * sw;
                    weight += sw;
                }
                color *= 1.0 / weight;
                return half4(color, 1);
            }
            ENDCG
        }
        //---------------------------------------------------------------------------------------------------
        Pass { // Post-Filter
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half4 frag (Interpolators i) : SV_Target {
                float4 o = _MainTex_TexelSize.xyxy * float2(-0.5, 0.5).xxyy;
                half4 s =
                    tex2D(_MainTex, i.uv + o.xy) +
                    tex2D(_MainTex, i.uv + o.zy) +
                    tex2D(_MainTex, i.uv + o.xw) +
                    tex2D(_MainTex, i.uv + o.zw);
                return s * 0.25;
            }
            ENDCG
        }
        //---------------------------------------------------------------------------------------------------
        Pass { // Combine
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half4 frag (Interpolators i) : SV_Target {
                half4 source = tex2D(_MainTex, i.uv);
                half coc = tex2D(_CoCTex, i.uv).r;
                half4 dof = tex2D(_DoFTex, i.uv);
                half dofStrength = smoothstep(0.1, 1, abs(coc));
                half3 color = lerp(source.rgb, dof.rgb, dofStrength);
                return half4(color, source.a);
            }
            ENDCG
        }
    }
}