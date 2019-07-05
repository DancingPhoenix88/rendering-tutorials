Shader "Custom/Camera/Bloom" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
    }
    //---------------------------------------------------------------------------------------------------
    CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex, _SourceTex;
        float4 _MainTex_TexelSize;
        half4 _Filter;
        half _Intensity;
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
        //---------------------------------------------------------------------------------------------------
        half3 Sample (float2 uv) {
            return tex2D(_MainTex, uv).rgb;
        }
        //---------------------------------------------------------------------------------------------------
        half3 SampleBox (float2 uv, float delta) {
            float4 o = _MainTex_TexelSize.xyxy * float2(-delta, delta).xxyy;
            half3 s =
            Sample(uv + o.xy) + Sample(uv + o.zy) +
            Sample(uv + o.xw) + Sample(uv + o.zw);
            return s * 0.25f;
        }
        //---------------------------------------------------------------------------------------------------
        half3 Prefilter (half3 c) {
            half brightness = max(c.r, max(c.g, c.b));
            half soft = brightness - _Filter.y;
            soft = clamp(soft, 0, _Filter.z);
            soft = soft * soft * _Filter.w;
            half contribution = max(soft, brightness - _Filter.x);
            contribution /= max(brightness, 0.00001);
            return c * contribution;
        }
    ENDCG
    //---------------------------------------------------------------------------------------------------
    SubShader {
        Cull Off
        ZTest Always
        ZWrite Off
        //---------------------------------------------------------------------------------------------------
        Pass { // Prefilter
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half4 frag (Interpolators i) : SV_Target {
                return half4(Prefilter(SampleBox(i.uv, 1)), 1);
            }
            ENDCG
        }
        //---------------------------------------------------------------------------------------------------
        Pass { // Downsample
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half4 frag (Interpolators i) : SV_Target {
                return half4(SampleBox(i.uv, 1), 1);
            }
            ENDCG
        }
        //---------------------------------------------------------------------------------------------------
        Pass { // Upsample
            Blend One One // Additive blend 2 textures
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half4 frag (Interpolators i) : SV_Target {
                return half4(SampleBox(i.uv, 0.5), 1);
            }
            ENDCG
        }
        //---------------------------------------------------------------------------------------------------
        Pass { // Apply bloom
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half4 frag (Interpolators i) : SV_Target {
                half4 c = tex2D( _SourceTex, i.uv );
                c.rgb += _Intensity * SampleBox(i.uv, 0.5);
                return c;
            }
            ENDCG
        }
        //---------------------------------------------------------------------------------------------------
        Pass { // Debug bloom (Render final upscaled texture without blending)
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            half4 frag (Interpolators i) : SV_Target {
                return half4(_Intensity * SampleBox(i.uv, 0.5), 1);
            }
            ENDCG
        }
    }
}