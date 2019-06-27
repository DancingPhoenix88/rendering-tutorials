Shader "Custom/Diffuse" {
    Properties {
        _TintColor ("Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" {}
    }
    SubShader {
        Pass {
            Tags { "LightMode" = "ForwardBase" } // NEW

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #include "UnityCG.cginc" below file includes this one already
            #include "UnityStandardBRDF.cginc"
            //---------------------------------------------------------------------------------------------------
            float4 _TintColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            //---------------------------------------------------------------------------------------------------
            struct CustomData {
                float4 position : POSITION;
                float3 normal: NORMAL;
                float2 uv : TEXCOORD0;
            };
            //---------------------------------------------------------------------------------------------------
            CustomData vert (CustomData data) {
                CustomData output;
                output.position = UnityObjectToClipPos( data.position );
                output.normal = UnityObjectToWorldNormal( data.normal );
                output.uv = TRANSFORM_TEX( data.uv, _MainTex );
                return output;
            }
            //---------------------------------------------------------------------------------------------------
            float4 frag (CustomData data) : SV_TARGET {
                data.normal = normalize( data.normal );

                // TEST 1: un-clamped, light from (0, 1, 0)
                // return dot(float3(0, 1, 0), data.normal);

                // TEST 2: clamped to [0, 1]
                // return saturate(dot(float3(0, 1, 0), data.normal));

                // TEST 3: clamped using function from "UnityStandardBRDF.cginc"
                // return DotClamped(float3(0, 1, 0), data.normal);

                // TEST 4: Color = light direction (parallel = 0, perpendicular = 1)
                // float3 lightDir = _WorldSpaceLightPos0.xyz;
                // return DotClamped(lightDir, data.normal);

                // TEST 5: Color = light direction * color
                // float3 lightDir = _WorldSpaceLightPos0.xyz;
                // float3 lightColor = _LightColor0.rgb;
                // float3 diffuse = lightColor * DotClamped(lightDir, data.normal);
                // return float4(diffuse, 1);

                // TEST 6: Color = texture * tint * lightColor * light direction
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;
                float3 albedo = tex2D( _MainTex, data.uv ).rgb * _TintColor.rgb;
                float3 diffuse = albedo * lightColor * DotClamped(lightDir, data.normal);
                return float4(diffuse, 1);
            }

            ENDCG
        }
    }
}
