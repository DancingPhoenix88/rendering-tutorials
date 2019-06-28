Shader "Custom/DiffuseSpecular" {
    Properties {
        _TintColor ("Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" {}
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
    }
    //---------------------------------------------------------------------------------------------------
    SubShader {
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityStandardBRDF.cginc"
            //---------------------------------------------------------------------------------------------------
            float4 _TintColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Smoothness;
            //---------------------------------------------------------------------------------------------------
            struct CustomData {
                float4 position : POSITION;
                float3 normal: NORMAL;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };
            //---------------------------------------------------------------------------------------------------
            CustomData vert (CustomData data) {
                CustomData output;
                output.position = UnityObjectToClipPos( data.position );
                output.normal = UnityObjectToWorldNormal( data.normal );
                output.uv = TRANSFORM_TEX( data.uv, _MainTex );
                output.worldPos = mul(unity_ObjectToWorld, data.position);
                return output;
            }
            //---------------------------------------------------------------------------------------------------
            float4 frag (CustomData data) : SV_TARGET {
                // TEST 1: diffuse + specular
                data.normal = normalize( data.normal );
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
