#if !defined(MY_SHADOWS_INCLUDED)
    #define MY_SHADOWS_INCLUDED
    
    #include "UnityCG.cginc"
    #if defined(SHADOWS_CUBE)
        struct CustomData {
            float4 position : POSITION;
            float3 lightVec : TEXCOORD0;
        };
        //---------------------------------------------------------------------------------------------------
        CustomData vert (CustomData data) {
            CustomData output;
            output.position = UnityObjectToClipPos(data.position);
            output.lightVec = mul(unity_ObjectToWorld, data.position).xyz - _LightPositionRange.xyz;
            return output;
        }
        //---------------------------------------------------------------------------------------------------
        float4 frag (CustomData data) : SV_TARGET {
            float depth = length(data.lightVec) + unity_LightShadowBias.x;
            depth *= _LightPositionRange.w;
            return UnityEncodeCubeShadowDepth(depth);
        }
    #else
        //---------------------------------------------------------------------------------------------------
        struct CustomData {
            float4 position : POSITION;
            float3 normal : NORMAL;
        };
        //---------------------------------------------------------------------------------------------------
        float4 vert (CustomData data) : SV_POSITION {
            // TEST 1: Basic shadow
            // return UnityObjectToClipPos(data.position);

            // TEST 2: Support bias
            // float4 position = UnityObjectToClipPos(data.position);
            // return UnityApplyLinearShadowBias(position);

            // TEST 3: Support bias + normal bias
            float4 position = UnityClipSpaceShadowCasterPos(data.position.xyz, data.normal);
            return UnityApplyLinearShadowBias(position);
        }
        //---------------------------------------------------------------------------------------------------
        half4 frag () : SV_TARGET {
            return 0;
        }
    #endif
#endif