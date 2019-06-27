// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Flat" {
    // Exposed parameters in Inspector
    Properties {
        _TintColor ("TintColor", Color) = (1, 1, 1, 1) // no semi-colon (;)
    }
    //---------------------------------------------------------------------------------------------------
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            //---------------------------------------------------------------------------------------------------
            // parameters
            float4 _TintColor;
            struct CustomData {
                float4 position : POSITION;
                float3 objectSpacePosition: TEXCOORD0;
            }; // semi-colon is required, or next lines will be considered as 'redifinition'
            //---------------------------------------------------------------------------------------------------
            // alter vertices
            CustomData vert (CustomData data) {
                CustomData output;
                output.objectSpacePosition = data.position.xyz;
                // output.position = data.position; // raw Object-space vertex -> distort based on screen size, doesn't change when moving around
                output.position = UnityObjectToClipPos( data.position ); // project to Camera-space
                return output;
            }
            //---------------------------------------------------------------------------------------------------
            // alter pixel/fragment color
            float4 frag (CustomData data) : SV_TARGET {
                // return float4( 0, 0, 0, 0 ); // black
                // return float4( 1, 1, 0, 1 ); // yellow
                // return _TintColor; // color from Inspector
                // return float4(data.objectSpacePosition, 1); // use Object-space position as color
                // return float4(data.objectSpacePosition + 0.5, 1); // use Object-space position as color, add 0.5 to convert [-0.5, 0.5] => [0, 1]
                return float4(data.objectSpacePosition + 0.5, 1) * _TintColor; // add Tint
            }

            ENDCG
        }
    }
}
