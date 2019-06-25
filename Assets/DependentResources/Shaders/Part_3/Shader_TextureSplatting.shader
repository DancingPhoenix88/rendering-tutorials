// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Shader_TextureSplatting" {
    Properties {
        _MainTex ("Splat Map", 2D) = "white" {}
        [NoScaleOffset] _Texture1 ("Texture 1", 2D) = "white" {}
        [NoScaleOffset] _Texture2 ("Texture 2", 2D) = "white" {}
        [NoScaleOffset] _Texture3 ("Texture 3", 2D) = "white" {}
        [NoScaleOffset] _Texture4 ("Texture 4", 2D) = "white" {}
    }
    //---------------------------------------------------------------------------------------------------
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            //---------------------------------------------------------------------------------------------------
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Texture1, _Texture2, _Texture3, _Texture4;
            //---------------------------------------------------------------------------------------------------
            struct CustomData {
                float4 position : POSITION;
                float4 uv: TEXCOORD0;
            };
            //---------------------------------------------------------------------------------------------------
            CustomData vert (CustomData data) {
                CustomData output;
                output.position = UnityObjectToClipPos( data.position );
                output.uv.zw = data.uv;                             // Disable Tiling & Offset for Splat Map
                output.uv.xy = TRANSFORM_TEX( data.uv, _MainTex );  // Enable Tiling & Offset for other textures
                return output;
            }
            //---------------------------------------------------------------------------------------------------
            float4 frag (CustomData data) : SV_TARGET {
                float4 splat = tex2D(_MainTex, data.uv.zw);
                return tex2D(_Texture1, data.uv.xy) * splat.r
                    + tex2D(_Texture2, data.uv.xy) * splat.g
                    + tex2D(_Texture3, data.uv.xy) * splat.b
                    + tex2D(_Texture4, data.uv.xy) * (1 - splat.r - splat.g - splat.b)
                ;
            }

            ENDCG
        }
    }
}
