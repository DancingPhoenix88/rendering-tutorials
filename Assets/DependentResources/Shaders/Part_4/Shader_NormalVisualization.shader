// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/NormalVisualization" {
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            //---------------------------------------------------------------------------------------------------
            struct CustomData {
                float4 position : POSITION;
                float3 normal: NORMAL;
            };
            //---------------------------------------------------------------------------------------------------
            CustomData vert (CustomData data) {
                CustomData output;
                output.position = UnityObjectToClipPos( data.position );

                // TEST 1: Keep normal vector in Object-space
                // output.normal = data.normal;
                
                // TEST 2: Transform to World-space (scale with transform -> WRONG)
                // output.normal = mul( (float3x3)unity_ObjectToWorld, data.normal );

                // TEST 3: Transform to World-space (inverse scale with transform to keep normal angle = 90 degrees)
                // unity_WorldToObject = inverse( unity_ObjectToWorld ) = S^-1 * R^-1
                // transpose( S^-1 * R^-1 ) = transpose( S^-1 ) * transpose( R^-1 ) = transpose( S^-1 ) * R
                // => we only invert the scaling factor
                // output.normal = mul( transpose((float3x3)unity_WorldToObject), data.normal );

                // TEST 3b: Using built-in functions
                output.normal = UnityObjectToWorldNormal( data.normal );
                return output;
            }
            //---------------------------------------------------------------------------------------------------
            float4 frag (CustomData data) : SV_TARGET {
                data.normal = normalize( data.normal ); // re-normalize for interpolated fragment (can skip for better performance)
                return float4(data.normal * 0.5 + 0.5, 1);
            }

            ENDCG
        }
    }
}
