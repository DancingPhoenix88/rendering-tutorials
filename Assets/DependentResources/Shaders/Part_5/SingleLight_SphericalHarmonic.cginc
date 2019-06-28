#if !defined(MY_LIGHTING_INCLUDED)
    #define MY_LIGHTING_INCLUDED
    #include "UnityPBSLighting.cginc" // this needs to be included first to define UnityDecodeCubeShadowDepth for AutoLight usage (Part_7)
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

        #if defined(SHADOWS_SCREEN) // this is added to support "Shadow receiving" in Part_7
            // float4 _ShadowCoord : TEXCOORD3; // version 1: Manual
            SHADOW_COORDS(3) // version 2: Use macro from AutoLight, without semi-colon
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

        #if defined(SHADOWS_SCREEN) // this is added to support "Shadow receiving" in Part_7
            // TEST 7.1: Receive shadow in screen-space (INCORRECT)
            // output._ShadowCoord = output.position;

            // TEST 7.2: Convert shadow map to world space (INCORRECT with Direct3D API using Y axis downward)
            // output._ShadowCoord.xy = (output.position.xy + output.position.w) * 0.5;
            // output._ShadowCoord.zw = output.position.zw;

            // TEST 7.3: Convert shadow map to world space (MAY BE CORRECT)
            // output._ShadowCoord.xy = (float2(output.position.x, -output.position.y) + output.position.w) * 0.5;
            // output._ShadowCoord.zw = output.position.zw;

            // TEST 7.4: Using built-in functions (auto handle Y axis issue) => CORRECT, but might fail on Tegra hardware
            output._ShadowCoord = ComputeScreenPos(output.position);

            // TEST 7.5: Using macros (FAILED, because it requires 2 struct with named attributes: position=>vertex, position=>pos)
            // TRANSFER_SHADOW(output);
            // This should be fixed by re-writing the entire shader -> Skip
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
        UNITY_LIGHT_ATTENUATION(attenuation, data, data.worldPos); // 2nd param changes from 0 to data to take shadow into account
        light.color = _LightColor0.rgb * attenuation;
        return light;
    }
    //---------------------------------------------------------------------------------------------------
    UnityIndirect CreateIndirectLight (CustomData data) {
        UnityIndirect indirectLight;
        indirectLight.diffuse = 0;
        indirectLight.specular = 0;

        #if defined(VERTEXLIGHT_ON)
            indirectLight.diffuse = data.vertexLightColor;
        #endif

        #if defined(FORWARD_BASE_PASS)
            indirectLight.diffuse += max(0, ShadeSH9(float4(data.normal, 1))); // Add spherical harmonic as indirect-light
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
            CreateLight(data), CreateIndirectLight(data)
        );
    }
#endif