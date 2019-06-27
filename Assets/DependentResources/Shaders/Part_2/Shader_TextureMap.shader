// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/TexureMap" {
    Properties {
        _TintColor ("TintColor", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
    }
    //---------------------------------------------------------------------------------------------------
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            //---------------------------------------------------------------------------------------------------
            float4 _TintColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            //---------------------------------------------------------------------------------------------------
            struct CustomData {
                float4 position : POSITION;
                float2 uv: TEXCOORD0;
            };
            //---------------------------------------------------------------------------------------------------
            CustomData vert (CustomData data) {
                CustomData output;
                output.position = UnityObjectToClipPos( data.position );
                // output.uv = data.uv; // Use basic UV
                // output.uv = data.uv * _MainTex_ST.xy + _MainTex_ST.zw; // Enable tiling & offset, need WrapMode=Repeat in texture
                output.uv = TRANSFORM_TEX( data.uv, _MainTex ); // Enable tiling, the short way
                return output;
            }
            //---------------------------------------------------------------------------------------------------
            float4 frag (CustomData data) : SV_TARGET {
                // return float4(data.uv, 1, 1); // Use UV as color
                return tex2D(_MainTex, data.uv) * _TintColor; // Apply texture and tint color
            }

            ENDCG
        }
    }
}
