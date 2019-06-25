// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Shader_TextureWithDetail" {
    Properties {
        _TintColor ("TintColor", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
        _DetailTex ("Texture", 2D) = "gray" {}
        _Contrast ("Contrast", float) = 2
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
            sampler2D _MainTex, _DetailTex;
            float4 _MainTex_ST, _DetailTex_ST;
            float _Contrast;
            //---------------------------------------------------------------------------------------------------
            struct CustomData {
                float4 position : POSITION;
                float4 uv: TEXCOORD0; // float2 => float4 to store DetailTexture's UV
            };
            //---------------------------------------------------------------------------------------------------
            CustomData vert (CustomData data) {
                CustomData output;
                output.position = UnityObjectToClipPos( data.position );
                output.uv.xy = TRANSFORM_TEX( data.uv, _MainTex );
                output.uv.zw = TRANSFORM_TEX( data.uv, _DetailTex ); // use uv.zw to store DetailTexture' UV
                return output;
            }
            //---------------------------------------------------------------------------------------------------
            float4 frag (CustomData data) : SV_TARGET {
                float4 color = tex2D(_MainTex, data.uv.xy) * _TintColor;
                color *= tex2D(_DetailTex, data.uv.zw) * _Contrast;
                return color;
            }

            ENDCG
        }
    }
}
