Shader "Custom/MultipleLights_SphericalHarmonic" {
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
            #pragma multi_compile _ VERTEXLIGHT_ON
            #pragma vertex vert
            #pragma fragment frag
            #define FORWARD_BASE_PASS // Activate spherical harmonic
            #include "SingleLight_SphericalHarmonic.cginc"
            ENDCG
        }
        //---------------------------------------------------------------------------------------------------
        Pass {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            ZWrite Off

            CGPROGRAM
            #pragma target 3.0
            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag
            #include "SingleLight_SphericalHarmonic.cginc"
            ENDCG
        }
    }
}
