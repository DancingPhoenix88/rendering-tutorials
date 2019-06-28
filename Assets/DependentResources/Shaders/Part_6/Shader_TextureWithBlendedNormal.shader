Shader "Custom/TextureWithBlendedNormal" {
    Properties {
        _TintColor ("Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1
        _DetailTex ("Detail Texture", 2D) = "gray" {}
        [NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
        _DetailBumpScale ("Detail Bump Scale", Float) = 1
    }
    //---------------------------------------------------------------------------------------------------
    SubShader {
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityStandardBRDF.cginc"
            #include "UnityStandardUtils.cginc"
            //---------------------------------------------------------------------------------------------------
            float4 _TintColor;
            sampler2D _MainTex, _NormalMap, _DetailTex, _DetailNormalMap;
            float4 _MainTex_ST, _DetailTex_ST;
            float _Smoothness;
            float _BumpScale, _DetailBumpScale;
            //---------------------------------------------------------------------------------------------------
            struct CustomData {
                float4 position : POSITION;
                float4 uv : TEXCOORD0; // xy=MainTex, zw=DetailTex
                float3 normal: TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };
            //---------------------------------------------------------------------------------------------------
            CustomData vert (CustomData data) {
                CustomData output;
                output.position = UnityObjectToClipPos( data.position );
                output.normal = UnityObjectToWorldNormal( data.normal );
                output.worldPos = mul(unity_ObjectToWorld, data.position);
                output.uv.xy = TRANSFORM_TEX( data.uv, _MainTex );
                output.uv.zw = TRANSFORM_TEX( data.uv, _DetailTex );
                return output;
            }
            //---------------------------------------------------------------------------------------------------
            void InitializeFragmentNormal(inout CustomData data) {
                float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, data.uv.xy), _BumpScale);
                float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, data.uv.zw), _DetailBumpScale);
                data.normal = BlendNormals( mainNormal, detailNormal );
                data.normal = data.normal.xzy;
            }
            //---------------------------------------------------------------------------------------------------
            float4 frag (CustomData data) : SV_TARGET {
                InitializeFragmentNormal(data);
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;
                float3 albedo = tex2D( _MainTex, data.uv.xy ).rgb * _TintColor.rgb * tex2D(_DetailTex, data.uv.zw);
                float3 diffuse = albedo * lightColor * DotClamped(lightDir, data.normal);
                float3 viewDir = normalize(_WorldSpaceCameraPos - data.worldPos);
                float3 halfVector = normalize(lightDir + viewDir);
                float3 specular = pow(
                    DotClamped( halfVector, data.normal ),
                    _Smoothness * 100
                );
                return float4( diffuse + specular, 1 );
            }

            ENDCG
        }
    }
}
