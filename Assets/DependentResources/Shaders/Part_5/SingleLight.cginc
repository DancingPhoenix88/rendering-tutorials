#if !defined(MY_LIGHTING_INCLUDED)
    #define MY_LIGHTING_INCLUDED
    #include "AutoLight.cginc"
    #include "UnityPBSLighting.cginc"
    //---------------------------------------------------------------------------------------------------
    float4 _TintColor;
    sampler2D _MainTex;
    float4 _MainTex_ST;
    float _Metallic;
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
    UnityLight CreateLight (CustomData data) {
        UnityLight light;
        
        #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
            float3 lightVec = _WorldSpaceLightPos0.xyz - data.worldPos;
            light.dir = normalize(lightVec);
        #else
            light.dir = _WorldSpaceLightPos0.xyz;
        #endif

        light.ndotl = DotClamped(data.normal, light.dir);

        // TEST 1: Default Directional Light
        // float attenuation = 1;

        // TEST 2: Attenuation
        // float attenuation = 1 / (1 + dot(lightVec, lightVec));

        // TEST 3: Attenuation with fading out
        UNITY_LIGHT_ATTENUATION(attenuation, 0, data.worldPos); // this is different between point and spot light. No effect for directional light.

        light.color = _LightColor0.rgb * attenuation;
        return light;
    }
    //---------------------------------------------------------------------------------------------------
    float4 frag (CustomData data) : SV_TARGET {
        data.normal = normalize(data.normal);
        float3 viewDir = normalize(_WorldSpaceCameraPos - data.worldPos);
        float3 albedo = tex2D(_MainTex, data.uv).rgb * _TintColor.rgb;

        float3 specularTint;
        float oneMinusReflectivity;
        albedo = DiffuseAndSpecularFromMetallic(
            albedo, _Metallic, specularTint, oneMinusReflectivity
        );
        
        UnityIndirect indirectLight;
        indirectLight.diffuse = 0;
        indirectLight.specular = 0;

        return UNITY_BRDF_PBS(
            albedo, specularTint,
            oneMinusReflectivity, _Smoothness,
            data.normal, viewDir,
            CreateLight(data), indirectLight
        );
    }
#endif