Shader "Custom/Specular" {
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
                output.worldPos = mul(unity_ObjectToWorld, data.position); // NEW
                return output;
            }
            //---------------------------------------------------------------------------------------------------
            float4 frag (CustomData data) : SV_TARGET {
                // TEST 1: Reflection direction visualization
                // data.normal = normalize( data.normal );
                // float3 lightDir = _WorldSpaceLightPos0.xyz;
                // float3 reflectionDir = reflect( -lightDir, data.normal );
                // return float4(reflectionDir * 0.5 + 0.5, 1);

                // TEST 2: Convert reflection direction to how much light come to camera (parallel=0, perpendicular = 1)
                // data.normal = normalize( data.normal );
                // float3 lightDir = _WorldSpaceLightPos0.xyz;
                // float3 reflectionDir = reflect( -lightDir, data.normal );
                // float3 viewDir = normalize(_WorldSpaceCameraPos - data.worldPos);
                // return DotClamped( viewDir, reflectionDir );

                // TEST 3: Control smoothness
                // data.normal = normalize( data.normal );
                // float3 lightDir = _WorldSpaceLightPos0.xyz;
                // float3 reflectionDir = reflect( -lightDir, data.normal );
                // float3 viewDir = normalize(_WorldSpaceCameraPos - data.worldPos);
                // return pow(
                //     DotClamped( viewDir, reflectionDir ),
                //     _Smoothness * 100
                // );

                // TEST 4: Blinn-Phong
                // Use a vector between light direction and view direction as reflection direction
                data.normal = normalize( data.normal );
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 viewDir = normalize(_WorldSpaceCameraPos - data.worldPos);
                float3 halfVector = normalize(lightDir + viewDir);
                return pow(
                    DotClamped( halfVector, data.normal ),
                    _Smoothness * 100
                );
            }

            ENDCG
        }
    }
}
