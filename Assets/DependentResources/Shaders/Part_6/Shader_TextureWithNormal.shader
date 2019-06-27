// Upgraded version of 'DiffuseSpecular'
Shader "Custom/TextureWithNormal" {
    Properties {
        _TintColor ("Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1
    }
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
            sampler2D _MainTex, _NormalMap;
            float4 _MainTex_ST;
            float _Smoothness;
            float _BumpScale;
            //---------------------------------------------------------------------------------------------------
            struct CustomData {
                float4 position : POSITION;
                float2 uv : TEXCOORD0; // same UV for both _MainTex and _NormalMap
                float3 normal: TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };
            //---------------------------------------------------------------------------------------------------
            CustomData vert (CustomData data) {
                CustomData output;
                output.position = UnityObjectToClipPos( data.position );
                output.normal = UnityObjectToWorldNormal( data.normal );
                output.worldPos = mul(unity_ObjectToWorld, data.position);
                output.uv = TRANSFORM_TEX( data.uv, _MainTex );
                return output;
            }
            //---------------------------------------------------------------------------------------------------
            void InitializeFragmentNormal(inout CustomData data) {
                data.normal = UnpackScaleNormal(tex2D(_NormalMap, data.uv), _BumpScale);
                data.normal = data.normal.xzy;
                data.normal = normalize(data.normal);
            }
            //---------------------------------------------------------------------------------------------------
            float4 frag (CustomData data) : SV_TARGET {
                InitializeFragmentNormal(data);
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;
                float3 albedo = tex2D( _MainTex, data.uv ).rgb * _TintColor.rgb;
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
