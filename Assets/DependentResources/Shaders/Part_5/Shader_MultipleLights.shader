Shader "Custom/MultipleLights" {
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
            #pragma vertex vert
            #pragma fragment frag
            #include "SingleLight.cginc"
            ENDCG
        }
        //---------------------------------------------------------------------------------------------------
        Pass {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One // Additive Blending with 1st light
            ZWrite Off // No need to write to Z-buffer twice

            CGPROGRAM
            #pragma target 3.0
            #pragma multi_compile_fwdadd // compile different shader for each type of light + cookie
            #pragma vertex vert
            #pragma fragment frag
            #include "SingleLight.cginc"
            ENDCG
        }
    }
}
