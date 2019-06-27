Shader "Custom/TextureWithBinormal" {
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

    CGINCLUDE
    #define BINORMAL_PER_FRAGMENT // uncommen to see the differences (not so much)
    ENDCG

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
                float3 normal: NORMAL;
                float4 tangent: TANGENT;
                #if !defined(BINORMAL_PER_FRAGMENT)
                float3 binormal: TEXCOORD1;
                #endif
                float3 worldPos : TEXCOORD2;
            };
            //---------------------------------------------------------------------------------------------------
            float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
                return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
            }
            //---------------------------------------------------------------------------------------------------
            CustomData vert (CustomData data) {
                CustomData output;
                output.position = UnityObjectToClipPos( data.position );
                output.normal = UnityObjectToWorldNormal( data.normal );
                output.tangent = float4(UnityObjectToWorldDir(data.tangent.xyz), data.tangent.w);

                #if !defined(BINORMAL_PER_FRAGMENT)
                output.binormal = CreateBinormal(output.normal, output.tangent.xyz, output.tangent.w);
                #endif

                output.worldPos = mul(unity_ObjectToWorld, data.position);
                output.uv.xy = TRANSFORM_TEX( data.uv, _MainTex );
                output.uv.zw = TRANSFORM_TEX( data.uv, _DetailTex );
                return output;
            }
            //---------------------------------------------------------------------------------------------------
            void InitializeFragmentNormal(inout CustomData data) {
                float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, data.uv.xy), _BumpScale);
                float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, data.uv.zw), _DetailBumpScale);
                float3 tangentSpaceNormal = BlendNormals( mainNormal, detailNormal );
                #if defined(BINORMAL_PER_FRAGMENT)
                float3 binormal = CreateBinormal( data.normal, data.tangent.xyz, data.tangent.w );
                #else
                float3 binormal = data.binormal;
                #endif
                data.normal = normalize(
                    tangentSpaceNormal.x * data.tangent +
                    tangentSpaceNormal.y * binormal +
                    tangentSpaceNormal.z * data.normal
                );
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
