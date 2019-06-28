// Upgraded version of Reflection_BoxProjection
Shader "Custom/Reflection_Blend" {
    Properties {
        _TintColor ("Tint", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" {}
        [Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.1
    }
    //---------------------------------------------------------------------------------------------------
    SubShader {
        Pass {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma target 3.0
            #pragma multi_compile _ SHADOWS_SCREEN
            #pragma multi_compile _ VERTEXLIGHT_ON
            #pragma vertex vert
            #pragma fragment frag
            #define FORWARD_BASE_PASS
            #include "SingleLight_Reflection_Blend.cginc"
            ENDCG
        }
        //---------------------------------------------------------------------------------------------------
        Pass {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            ZWrite Off

            CGPROGRAM
            #pragma target 3.0
            #pragma multi_compile_fwdadd_fullshadows
            #pragma vertex vert
            #pragma fragment frag
            #include "SingleLight_Reflection_Blend.cginc"
            ENDCG
        }
        //---------------------------------------------------------------------------------------------------
        Pass {
            Tags { "LightMode" = "ShadowCaster" }
            
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #include "../Part_7/Shadow.cginc"
            ENDCG
        }
    }
}
