// Upgraded version of SingleLight_Reflection

#if !defined(MY_LIGHTING_INCLUDED)
    #define MY_LIGHTING_INCLUDED
    #include "UnityPBSLighting.cginc"
    #include "AutoLight.cginc"
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

        #if defined(VERTEXLIGHT_ON)
            float3 vertexLightColor : TEXCOORD2;
        #endif

        #if defined(SHADOWS_SCREEN)
            SHADOW_COORDS(3)
        #endif
    };
    //---------------------------------------------------------------------------------------------------
    void ComputeVertexLightColor (inout CustomData data) {
        #if defined(VERTEXLIGHT_ON)
            data.vertexLightColor = Shade4PointLights(
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb,
                unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, data.worldPos, data.normal
            );
        #endif
    }
    //---------------------------------------------------------------------------------------------------
    CustomData vert (CustomData data) {
        CustomData output;
        output.position = UnityObjectToClipPos( data.position );
        output.normal = UnityObjectToWorldNormal( data.normal );
        output.uv = TRANSFORM_TEX( data.uv, _MainTex );
        output.worldPos = mul(unity_ObjectToWorld, data.position);

        #if defined(SHADOWS_SCREEN)
            output._ShadowCoord = ComputeScreenPos(output.position);
        #endif

        ComputeVertexLightColor(output);
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
        UNITY_LIGHT_ATTENUATION(attenuation, data, data.worldPos);
        light.color = _LightColor0.rgb * attenuation;
        return light;
    }
    //---------------------------------------------------------------------------------------------------
    float3 BoxProjection (
        float3 direction, float3 position,
        float4 cubemapPosition, float3 boxMin, float3 boxMax
    ) {
        #if UNITY_SPECCUBE_BOX_PROJECTION // Only apply if BoxProject is enabled (in Inspector)
            UNITY_BRANCH // Request to compile to actual branch, since all fragments of this mesh use same setting -> reduce branch mis-prediction
            if (cubemapPosition.w > 0) { // w component = use box-projection (per probe setting)
                float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
                float scalar = min(min(factors.x, factors.y), factors.z);
                direction = direction * scalar + (position - cubemapPosition);
            }
        #endif
        return direction;
    }
    //---------------------------------------------------------------------------------------------------
    UnityIndirect CreateIndirectLight (CustomData data, float3 viewDir) {
        UnityIndirect indirectLight;
        indirectLight.diffuse = 0;
        indirectLight.specular = 0;

        #if defined(VERTEXLIGHT_ON)
            indirectLight.diffuse = data.vertexLightColor;
        #endif

        #if defined(FORWARD_BASE_PASS)
            indirectLight.diffuse += max(0, ShadeSH9(float4(data.normal, 1)));
            float3 reflectionDir = reflect(-viewDir, data.normal);
            Unity_GlossyEnvironmentData envData;
            envData.roughness = 1 - _Smoothness;

            // TEST 1: Use normal projection
            // envData.reflUVW = reflectionDir;

            // TEST 2: Use box projection
            // envData.reflUVW = BoxProjection(
            //     reflectionDir, data.worldPos,
            //     unity_SpecCube0_ProbePosition,
            //     unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
            // );

            // TEST 3: Use built-in function
            envData.reflUVW = BoxProjectedCubemapDirection(
                reflectionDir, data.worldPos,
                unity_SpecCube0_ProbePosition,
                unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
            );

            indirectLight.specular = Unity_GlossyEnvironment(
                UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
            );
        #endif
        
        return indirectLight;
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

        return UNITY_BRDF_PBS(
            albedo, specularTint,
            oneMinusReflectivity, _Smoothness,
            data.normal, viewDir,
            CreateLight(data), CreateIndirectLight(data, viewDir)
        );
    }
#endif