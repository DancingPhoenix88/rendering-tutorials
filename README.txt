Rendering tutorial notes
https://catlikecoding.com/unity/tutorials/rendering/
=================================================================

1. MATRICES
    Modify cubes positions by applying translating, scaling, rotating their original positions.
    Vector4( x, y, z, 1 ) = a point (x, y, z) in 3D space.
    Vector4( x, y, z, 0 ) = a direction (x, y, z), can be scaled, rotated but not positioned.
    => Matrix4x4.MultiplyPoint( p )     <=> Matrix4x4.Multiply( Vector4( p.x, p.y, p.z, 1 ) )
    => Matrix4x4.MultiplyVector( d )    <=> Matrix4x4.Multiply( Vector4( d.x, d.y, d.z, 0 ) )
    Matrix is used to transform points & vectors from one space to another.
    Matrix can represent all transformations => faster transforming
    Needed when writing shader.

------------------------------------------------------------------
2. SHADER FUNDAMENTALS
    Basic:
        Without lighting (& skybox - ambient light), objects look flat.
        Vertex program alters vertices of the mesh (need vertex position in Object-space as input).
        Fragment program alters fragment / pixel color (need pixel position in Screen-space as input).
    Data:
        Both vertex and fragment program uses the same data, so it is better to define a struct containing data they need.
        By using ': POSITION', ': TEXCOORD0', we tell CPU to fill those attributes with appropriate values before passing to vertex program.
        Property declaration must NOT have semi-colon at the end of the line.
        struct declaration must have semi-colon at the end of the block.
    Texture:
        UV map: [0,0] at the bottom left, [1, 1] aat the top right.
        Unity stores extra data of material when a texture is available in special variables with _ST suffix (Extra data of '_MainTex' is '_MainTex_ST').
        When UV coordinate gets out of range [0, 1], the 'WrapMode' property of texture will decide which pixel to sample. (Clamp = No Tiling & Offset outside of texture).
    Texture settings:
        If number of texels (pixels on texture) doesn not match with projected screen area -> a "filtering" process happens to decide the final color:
            Point = nearest texel
            Bilinear = interpolate between 2 texels (both X & Y)
                Texels < Pixels => blurry output
                Texels > Pixels => skipped texels => too sharp -> should use a smaller version of that texture = mipmap.
                If texture is too easy to detect mipmap level -> blurry & sharp parts will interleave
            Trilinear = Bilinear + interpolate between mipmap levels
        When projecting to screen, there might be an axis distorted more than the other -> same mipmap does not help. We need NPOT mipmap too -> anisotropic.
        Anisotropic is per-texture setting, but we can still adjust the general setting in Quality window.

------------------------------------------------------------------
3. COMBINING TEXTURES
    Multiplying colors leads to a darker color.
    We can use un-used component in Vector to store custom data for better performance (float4.xy for the 1st float2, float4.zw for the 2nd float2)
    We can use a texture with solid color (only pure RGB & black) to mask areas for each textures = Splat Map.

------------------------------------------------------------------
4. THE FIRST LIGHT
    Normal vector:
        ': NORMAL' instructs CPU to fill Object-space normal vector for each vertex.
        Use 'UnityObjectToWorldNormal' to convert normal vector from Object-space to World-space.
        dot(N1, N2) = cos( angle_between(N1, N2) ) (since N1, N2 are normalized).
    Diffuse & Specular:
        If not specify "LightMode" in "Tags", _WorldSpaceLightPos0 is not available to use.
        Basic lighting formula (diffuse): albedo * lightColor * DotClamped( lightPosition, normal ).
        'Diffuse' could be understood as: texture color, clamped in [darkest, brightness] based on light direction.
        'Specular' could be understood as: diffuse + reflection to camera.
    Blinn-Phong:
        'Phong reflection model' = Calculate accurate reflection direction then clamp by view direction.
        'Blinn-Phong reflection model' = Use halfway vector ((view + light)/2) as local reflection, then clamp by vertex normal.
        We can combine diffuse and specular, but just by adding them might produce too bright image.
        'Energy conservation' is an adjustment between diffuse and specular (If specular is too strong, texture color will be ignored, like a mirror under the sun).
        'Specular workflow': Control color and strength of both diffuse and specular.
        'Metallic workflow': Control color of diffuse and energy conservation between diffuse and specular => simpler.
    Physically-Based Shading:
        'Physically-Based Shading': New algorithm to calculate light, substitute for the old Blinn-Phong technique. There is still diffuse & specular (different way of calculating), plus Fresnel.
        PBS works best with Shader Level 3.0 => '#pragma target 3.0' is needed.
        Unity has multiple implementations for PBS and BRDF (Bidirectional Reflectance Distribution Function) is one of them.

------------------------------------------------------------------
5. MULTIPLE LIGHTS
    Multiple Passes:
        If we add 1 more light to the scene, nothing happens -> Because our shader compute for 1 light only.
        If we duplicate the 1st pass to make a 2nd pass, and edit "LightMode" = "ForwardAdd", then the 2nd pass will compute for ALL extra lights.
        Dynamic batching is disabled for multiple lights.
        More lights might result in more draw calls (since each light has to be computed in a separate pass).
    Different light types:
        '_WorldSpaceLightPos0' is position of point / spot light, but it is light direction for directional light => need to define DIRECTIONAL or POINT or SPOT before including "AutoLight.cginc".
        It is better to use '#pragma multi_compile_fwdadd' to compile to different shaders (called shader variants), for each type of light.
        'multi_compile_fwdadd' = DIRECTIONAL DIRECTIONAL_COOKIE POINT POINT_COOKIE SPOT.
        Directional light could have cookie too, but it is treated as a different light type in AutoLight, with directive DIRECTIONAL_COOKIE.
    Vertex light:
        Normally, light is computed for each fragment / pixel -> limit 'Pixel Lights Count' in 'Quality'.
        We can convert point lights to 'Vertex Light' to compute light for each vertex then interpolate for each fragment => FASTER.
        You can specify which light is pixel / vertex light by 'Render Mode' = Important / Not Important.
        If 'Render Mode' = Auto, Unity will decide which light should be vertex due to contribution to final image.
    Spherical harmonic:
        For multiple points on a circle edge, we have sine and cosine functions, to represent the entire function of those points.
        In case of 3D space, we need spherical functions to represent multiple points on a surface of the sphere.
        Why they are called 'spherical harmonic' ? Does not matter in term of Computer Graphics. It was first used to represent harmonic motion (https://en.wikipedia.org/wiki/Simple_harmonic_motion).
        If we sample light intensity of every points, in every directions, we can represent those points as a single function, or spherical harmonic.
        Usually, we have to construct that final function by adding multiple simpler functions together (each called a band).
        Each band should be periodical, so we have frequency as its signature. 
        Bands with small frequency contributes more to the final function.
        Bands with high frequency contributes less to the final function and could be discarded for optimization.
        Unity uses its own function with 3 bands, represented by 9 factors (for 3 axis), it is called 'ShadeSH9'.
        9 images of spheres in the tutorial represent 9 factors in the table above it.
        Unity computes color in RGB channels, so the final function is represented by 27 factors, stored in 7 float4 variables from 'UnityShaderVariables'.
        When all pixel lights and vertex lights are used, the rest of them will be converted to use spherical harmonic.
        Unity renders light from skybox using spherical harmonic.

------------------------------------------------------------------
6. BUMPINESS
    Tangent:
        A quad has only 4 vertices <=> 4 normal vectors => for each fragment, normal vector is just interpolated by the others => smooth transition.
        If we store custom normal vectors in a texture called Normal Map, we can create rough surface.
        If we store offset of each fragment comparing to the surface of triangles, we have a Height Map.
        A tangent vector represents a linear function between heights of 2 texels on a height map, or in short, it is perpendicular to normal vector.
        We calculate final normal vector of a fragment by cross product tangent vectors of U and V axis.
        Instead of re-computing these tangent vectors & final normal vectors, we use Normal Map.
    Normal map:
        Warning: Normal map is encoded in RGB channels to represent 3D directions -> a downsampled normal map could not represent directions correctly (when using MipMap). 
        But Unity will handle this issue when you specify a texture as a normal map.
        More over, we can adjust the factor of this normal map as well, by a slider 'Bumpiness'.
        Unity will even produce a new normal map with pre-multiplied bumpiness to use in-game, while keeping your original normal map intact.
        Wondering about the color of the normal map ? 
            In UV space, XY are encoded in RG channels, so the height offset (Z) must be encoded in B channels.
            The normal vectors are in range [-1, 1], but the RGB channels are in [0, 255] => 0 in normal vector space will be represented as 128 in color space.
            That explains why a flat surface will have the color of light blue (128, 128, 255) <=> (0, 0, 1).
    DXT5nm:
        Unity uses DXT5nm algorithm to encode normap by default, but not on mobile.
        It only stores XY and we have to calculate Z ourselve since normal vector is normalized.
        We should use function 'UnpackScaleNormal' from 'UnityStandardUtils.cginc' to unpack normal vector from normal map.
        Remember that normal map is normalized, so if we scale XY, the Z component will decrease, leads to a flatter surface.
    Blending normal maps:
        For blending colors, we just multiply them.
        For blending normal vectors, we could not multiply them.
        A simple method is using their average, but the final normal vector will be flatter.
        Because flat normal vector affects the final result -> should be ignored -> whiteout blending.
        'UnityStandardUtils.cginc' offers function 'BlendNormals' to perform that blending with normalizing as well.
    Binormal / Bitangent:
        Normal and tangent vectors could represent 2D dimension, and we need another vector, perpendicular to those 2 to define object orientation in 3D space.
        That vector is called binormal, or bitangent.
        There is 2 vectors that could be perpendicular to both normal and tangent vectors, so we need to specify 1 of them by using 'binormal sign', stored as 4th component (w) in tangent vector.
        In order to synchronize binormal vectors between 3D modeler, Unity and shader, we need to check:
            - 3D modeler uses Mikkelsen's tangent space
            - Unity could use tangent vectors from the mesh or generate them itself using mikktspace algorithm
            - Shader computes binormal vectors in vertex program like Unity's standard shaders

------------------------------------------------------------------
7. SHADOWS
    Basic:
        Without shadow, each mesh is rendered as an isolated object.
        Unity supports soft shadow which is a filtering technique to simulate penumbra.
        There are many ways to compute realtime shadows, Unity uses the most popular way - shadow mapping.
    Shadow Mapping:
        When shadow enabled, many passes are needed to render shadows (each light needs a separated pass) -> expensive.
        Use Frame Debugger to see result after each pass:
            - Render shadow map (from light point-of-view) x lights, using shader 'Hidden/Internal-ScreenSpaceShadows' to a quad, then filter it to create soft shadows
            - Collect shadow map (from camera point-of-view) x lights
            - Render meshes with shadows
        Shadow map resolution is controlled by Shadow Quality setting.
        Short shadow distance produces soft shadows close to camera, and discard shadows far away from the camera.
        We can control shadow map resolution by camera distance via mipmapped shadow texture, called shadow cascade (visual debug is available in Scene view)
        Shadow projection:
            - Stable fit: distance to camera position (circle projection in Scene view)
            - Close fit: distance to camera plane (rectangle projection in Scene view) -> higher performance but produce shadow swimming (blinking shadow edge)
        'Shadow acne' is visible when using low quality hard shadows, we can fix it by adjusting bias & normal bias to push the shadow acne under the surface.
    Anti-aliasing in shadow map:
        MSAA: Multi-Sampling Anti-Aliasing: This is Unity's default algorithm, works on meshes, doesn't affect shadow map.
        FXAA: (Post-processing effect): Performs anti-aliasing on screen-space -> work on both meshes and shadows. In fact, they perform with pixels on screen.
    Custom shader - Directional light:
        Need a separate pass with "LightMode"="ShadowCaster" to cast shadow (and passing world position).
        Need to compile with directive 'SHADOWS_SCREEN' to receive shadow (and complex operations to project shadow correctly).
        Directional light has 'ShadowType'='Hard & Soft Shadow' by default, other lights have shadow disabled by default.
    Custom shader - Spot light:
        Directive 'SHADOWS_SCREEN' only works with directional lights.
        Use 'multi_compile_fwdadd_fullshadows' instead of 'multi_compile_fwdadd' to support shadow from different light types.
        Spotlight uses perspective projection (instead of orthographic projection like directional light), then there is no shadow cascade (but the macro SHADOW_ATTENUATION handles the filtering for us already)
        Spotlight has a position, so it just draw the shadow map, does not need to perform depth-checking pass, screen-space shadow pass -> less draw calls than directional light.
        So, Spot light shadow is cheap but ugly.
    Custom shader - Point light:
        'UnityDecodeCubeShadowDepth' is used by 'AutoLight.cginc', but defined in 'UnityPBSLighting.cginc' -> 'UnityPBSLighting' needs to be included first.
        Point light shines in all directions, so its view can be considered as a cube map.
        Without cube map support, point light can still cast shadow, but with incorrect shadow map.
        So, Point light shadow is expensive and ugly.

------------------------------------------------------------------
8. REFLECTION
    Environment mapping:
        Use macro 'UNITY_SAMPLE_TEXCUBE' to sample Skybox cubemap, stored in variable 'unity_SpecCube0'.
        And remember to decode received color in HDR mode if needed.
        Reflection should be changed when looking from different angles.
    Reflection probe:
        Reflection cube renders surrounded objets into 6 planes of a cube map.
        It only renders static objects and baked result to use in realtime by default.
        You can configure it to render all objects in realtime, but that is expensive due to rendering scenes 6 times to its cubemap.
        When the cube map of a reflection probe is rendered, it will be merged with skybox cube map (depend on camera position).
        So reflection probe works WITHOUT extra shader code.
        Note: An object could be marked 'Static' for just 'Reflection probe'. Then it might move somewhere else but its reflected image is baked in the reflection probe cube map already.
    Blurry reflection:
        Blurry reflection could be achieved by using mipmap versions of baked environment map.
        We could specify which level by macro 'UNITY_SAMPLE_TEXCUBE_LOD' and let _Smoothness parameter control this progress (not linear a relationship)
        Normal map could add more rough details to the mesh surface, along with blurry reflection, to create realistic image.
    Reflection probe advanced:
        Reflection probes could reflect other ones as well.
            We can control how many times light bounce back and forth between those probes by 'Environment Reflections' > 'Bounces' in Lighting window.
        Outdoor scenes have infinte skybox so that reflection probe works quite well.
            Indoor scenes require the reflection changing its size based on camera position.
            So we have to use Box Projection option of Reflection probe.
            Reflection probe ignores rotation and scaling of the GameObject to keep its projection box axis-aligned.
            Box-object has another cool effect that helps reflection from different position looks like it has its own probe at that position, saving many computations.
        A probe has fixed position.
            Probe size should match surrounded environment to prevent impossible reflection.
            Example: a probe is in the house, but its size is biigger than the house -> even an outside mirror can reflect the interior.
            In case of overlapped area, we need to blend cube maps of many probes.
            Reflection probdes modes:
                - Off: Use only skybox as reflection source.
                - Blend Probes: Blend overlapped probes.
                - Blend Probes And Skybox: Blend over probes and consider skybox as another probe.
                - Simple: No blend, use only the most important probe.

------------------------------------------------------------------
9. SHADER GUI
    UI script runs in editor only -> put in Editor folder.
    Extending ShaderGUI to override default material UI.
    Shader must specifies which Inspector to use via "CustomEditor" attribute.
    Add some more textures to mimic Unity's standard shader:
        - Metallic Map: Instead of using a constant for the entire texture, we could adjust the metallic property using a separated texture. 
                By using this texture, we can represent both metal & non-metal materials in a same texture.
                Metallic value is stored in R channel of the texture.
        - Smoothness Map: Similar to metallic, smoothness value is stored in A channel of Metallic Map or Albedo Map (We can choose which).
        - Emission Map: Additive blending color to fragments without light.

------------------------------------------------------------------
10. MORE COMPLEXITY
    Occlusion Map: 
        The higher part in the mesh should cast shadow to lower part of itself (self-shadowing) and this is not possible with Normal Map.
        So we needs to add Occlusion Map.
        It is like a baked shadow map for this Albedo texture.
        Occlusion value is stored in G channel of the texture.
    Combine maps:
        - Metallic: R
        - Occlusion: G
        - Smoothness: A
        This is convenient but not a default behavior of Unity, you'll have to create your own shader.
    Detail Mask:
        We could add details by Detail Map and Detail Normal Map (in part 3).
        But we don't want to apply those details to all fragments.
        So we could adjust the Detail Map and Detail Normal Map, but what if these maps are tiled ?
        We need a separate mask to control the masking, with same tiling & offset of those maps.
        A new map is called Detail Mask.

------------------------------------------------------------------
11. TRANSPARENCY
    Cutout:
        Use 'Standard' shader, 'Cutout' RenderMode.
        Use A channel in Albedo texture to control.
        Pixels having alpha value < 'Alpha Cutoff' will be discarded.
        Other pixels will be drawn with RGB color -> No semi-transparent.
        Object will be rendered in Opaque queue.
        Cutout could receive shadow.
    Fade:
        Use 'Standard' shader, 'Fade' RenderMode.
        Use A channel in Albedo Tint Color to control.
        All pixels will be drawn with RGBA color, additive blending with Tint Color.
        All colors (diffuse, specular, reflection ...) are faded along with Alpha.
        Object will be rendered in Transparent queue.
        Fade could NOT receive shadow.
    Transparent:
        Use 'Standard' shader, 'Transparent' RenderMode.
        Similar to Fade, but specular & reflection colors are maintained regardless the alpha.
        I met an error when changing RenderMode to Transparent, it does not work. I had to re-create a new material, seems like Unity bug.
        Transparent could NOT receive shadow.
    Blend Modes: https://docs.unity3d.com/Manual/SL-Blend.html
    ZWrite:
        'On': This object should cover ones behind it (like fence)
        'Off': This object should NOT cover ones behind it (like smoke)

------------------------------------------------------------------
12. SEMI-TRANSPARENT SHADOWS
    Basic:
        Our custom shaders do not support Cutout / Fade / Transparent shadow because we do not take Alpha into account.
        Unity standar shader does support it.
        The theory is simple. 
            We clip or blend the shadow like the way we work with Albedo, in shadow caster pass.
            In that way, we might need to sample Albedo map for Alpha value.
            And Cutout shadow works very well.
    Semi-transparent shadow:
        But shadow map just stores the distance to surface blocking light, there is no info about how much light is blocked on semi-transparent object.
        We need to fake that, by using dithering technique.
        Dithering: Using 16 pixels (only full black or white color) to represent intensity of a 4x4 area. (Number of pixels can vary)
        More white pixels -> brighter, more black pixels -> darker.
        Dithering helps simulating gradient, and we use it to simulate transition between dark and light areas of shadow.
        More: https://www.tutorialspoint.com/dip/concept_of_dithering.htm
        Example: https://bjango.com/images/articles/gradients/dithering-extreme.png
            The image on the right side uses same number of colors like the left one. By inserting white pixels in between, it creates an illusion of brighter color.
    Dithering:
        Internally, Unity dithers the scene (from light point-of-view) into 16 LOD and stores those textures in '_DitherMaskLOD'
        We just need to select the right LOD and sample with UV (from light point-of-view => VPOS).
        And those 16 textures are stored as a 3D textures with 16 layers.
        Unity offers dithering texture with size = 4x4 -> there are 16 different combinations of B&W pixels, called 16 patterns.
        We access these patterns by range [0, 1] / 16 steps = [0, 15] * 0.0625 = [0, 0.9375].
        We select the LOD by 'alpha * 0.9375', which lets alpha controls the dithering pattern.
    Swimming shadow:
        Dithering is a simulation technique, shadow map is low-resolution.
        Both of these limitations lead to unstable dithering when moving object / camera.
        It causes swimming shadow.
        So we add an option to use Cutout shadow on semi-transparent objects as alternative.

------------------------------------------------------------------
13. DEFERRED SHADING
    Basic
        In default rendering pipeline of Unity (Forward Rendering), each object needs to be drawn multiple times, based on how many lights affected.
        In Deferred Rendering pipeline, objects prepare for all kinds of data (position, normal, uv, color, depth ...) first, then each light is calculated later.
        By doing that, object data is calculated only ONCE, and it does not matter much how many lights you have.
        On the other side, we need G-Buffers to store calculated data (by fragments ~ resolution), which is possible for high-end computers, not mobiles.
    Pass
        We need a separate pass with 'LightMode' = 'Deferred'.
        This pass is similar to the base pass.
        In the fragment program of deferred pass, instead of returning fragment color, we store calculated information in 4 G-Buffers.
        In the fragment program of other passes, we just need to get values from these buffers.
    G-Buffers
        0:  RGB = Diffuse albedo, A = Occlusion
        1:  RGB = Specular, A = Smoothness
        2:  World-space normal vectors (each axis needs 10 bits)
        3:  Emission + Ambient light
    Reflection
        In Forward Rendering, we need to blend fragments of reflection cubemaps.
        In Deferred Rendering, the reflection probes projects their cubemaps into other surfaces.
        By default, probe projects entire cubemap surfaces into a surface, which may not look realistic to some viewpoints (like: floor reflects itself).
            So we need to adjust Blend Distance parameter (only available in Deferred Rendering)
        For horizontal plane, probes could render reflection inside a room to outside floor, which is incorrect.
            So we need to adjust the vertical size of reflection box to control this issue.

------------------------------------------------------------------
14. FOG
    Fog color blending
        First we compute the distance between fragment's world position and camera position.
        Then we compute the blend factor between fog color and fragment color by function 'UNITY_CALC_FOG_FACTOR_RAW'.
        Finally, we use 'lerp' function to blend 2 colors.
    Depth-based fog
        2 objects with same depth could behaves differently to fog, because the distance to camera is different.
        So we need to calculate the distance to camera plane, which is depth.
        In order to do that, we need to store depth (z in Screen-space) to 'w' component of world position.
        Then we use that instead of distance when computing fog.
        Note: We migh need to use 'UNITY_Z_0_FAR_FROM_CLIPSPACE' to handle some hard cases (like reversed Z order)
        Depth-based fog is useful for fixed camera distance (like platform games)
    Multiple lights
        Each light requires a separate pass to render.
        And fog color is accumulated to become too bright.
        So we need to make fog color BLACK in additive pass to keep original fog color (in base pass).
    Deferred rendering
        Fog is affected by camera distance and object distance.
        Fog is computed after all lighting stuffs -> no fog in Deferred Rendering.
        We have to create fog ourselves applying function 'OnRenderImage' to camera with a custom fog shader.
        Since we are processing the entire texture, the vertex program just pass some parameters to fragment program.
        In fragment program, we use function 'SAMPLE_DEPTH_TEXTURE' to get depth and blend fog color with fragment color.
        Notice that we need to scale the depth based on camera range and cut the offset by near plane.
        We will need to add attribute '[ImageEffectOpaque]' to function 'OnRenderImage' to render fog after opaque and before transparent.
    Deferred rendering distance-based fog
        We do NOT have vertex information for objects here, in camera.
        So we have to calculate distance in a different way.
        Firstly, we get 4 frustum corners of the camera to pass to shader (Beware of order: 0, 3, 1, 2 to match quad's vertices).
        Secondly, we convert 4 frustum corners positions into 4 rays. Since our render texture is just a quad with 4 vertices, we use the formula 'u+2v' too match the order.
        Finally, we scale the ray by the depth to get the distance.
    Skybox with fog (only with Deferred Rendering)
        We just need to consider the far plane of the camera as a quad and apply fog to it.
        if (depth > 0.9999) unityFogFactor = 1; // 1 = apply fog to skybox, 0 = reject fog to skybox

------------------------------------------------------------------
15. DEFERRED LIGHTS
    Render light, shadow by using data from G-Buffers.
    And note that we are processing G-Buffers (via sampler2d _CameraGBufferTexture*), not each objects.
    And each light renders its light map to a light buffer that we can access by 'sampler2D _LightBuffer';

------------------------------------------------------------------
16. STATIC LIGHTS
    Light map
        If the light properties are fixed and the objects are static too, we could pre-compute the light and shadow ONCE and apply later.
        The result is stored in a Light Map.
        Light should be set to 'Baked' mode to cache its lightmap, and it will NO LONGER affect dynamic objects.
        Only diffuse light is stored in a light map, because specular light depends on camera angle.
        It explains why the baked outdoor scene looks darker.
        But using lightmap enable bounced indirect light calculated, making objects in shadow still got bounced light -> brighter.
        Unity evens carries the color of bounced surface along when light bounces.
        So a white sphere next to a green wall will have a light green color.
        Adding support to light map in custom shaders takes a lot of effort.
    Directional light map
        Directional light map adds another map to store normal vectors of static objects to combine later.
    Light probes
        Baked light does not have any effect on dynamic objects.
        We could pre-compute spherical harmonic information at some points and store them in light probes.
        A light probe group could have many probes, some of them will be interpolated to add indirect light to dynamic objects.
        When selected, a dynamic object show connections to light probes affecting it (Drag it in and out of shadowed area to see the difference)
        Notice: Since our light is set to 'Baked' mode, there is no Shadow to dynamic objects.

------------------------------------------------------------------
17. MIXED LIGHTS
    Mixed
        Baked light does not affect dynamic objects -> no dynamic shadow.
        Switch light mode to 'Mixed' will bake the indirect light to light map, without shadow.
        In this mode:
            - Shadow is realtime -> applied to all objects
            - Indirect light is from light map (static objects) and light probes (dynamic objects)
        It explains why this mode is called 'Mixed'.
    Shadowmask
        Indirect light is stored in light map due to 'Light > Scene > Mixed Lighting > Lighting Mode' = Baked Indirect.
        We can bake shadow from static objects to light map by setting it to 'Shadowmask'
        In this mode: 
            - Shadow is from shadowmask for static objects
            - Shadow is realtime for dynamic objects
            - Indirect light is from light map (static objects) and light probes (dynamic objects)
        In Deferred Rendering, a shadowmask needs an additional G-Buffer (5th), which might not be supported in some platforms.
        Shadowmask helps baked shadow for static objects, which is faster than just baked indirect light and reatime shadow.
        But, static objects do NOT cast shadow to dynamic objects.
    Distance shadowmask
        This is an advanced version of shadowmask.
        All static objects have their own shadowmaskes, to cast shadow on dynamic objects.
        This is expensive (not as expensive as realtime), but remember realtime shadow does not have indirect light.
    Shadowmask buffer
        Shadowmask just needs 1 channel to store its information.
        So we can store 4 shadowmaskes in a RGBA texture (5th G-Buffer).
        And that is why shadowmask only support max 4 overlapping lights.
    Subtractive
        If the scene has only 1 directional light, we could fake the shadow from static objects to dynamic objects by decreasing shadowed area in light map.
        So for dynamic objects, when we compute the indirect light, we subtract an amount based on static object shadowmask.
    Comparisons: https://docs.unity3d.com/2018.2/Documentation/uploads/Main/BestPracticeLightingPipeline5.svg

------------------------------------------------------------------
18. REALTIME GI, PROBE VOLUMES, LOD GROUPS
    Realtime Global Illumination
        Baked indirect light and shadow works well for static light.
        For dynamic light, we could only bake the bouncing direction and amount between static surfaces, to speed up calculating indirect light and shadow in realtime
        This is called Realtime Global Illumination (Realtime GI), with options in Light > Scene > Realtime Lighting > Realtime Global Illumination.
        When this option is disabled, dynamic light will contribute direct light and shadow only.
        When this option is enabled, dynamic light will contribute direct light, shadow and indirect light.
        GI works very well for 1 directional light (normally the sun).
    Emissive Light
        For materials having Emission texture, they could emit light to surrounded objects too.
        Since it is NOT a proper light, it is considered as GI.
        You could control the emitted light will be baked or realtime in Material Inspector
    Light Probe Proxy Volumes (LPPV)
        A dynamic object uses baked light data from light probes to compute its color.
        But it uses only one point to sample data.
        It works well for small object.
        But for big object, whose parts laid on different light condition, we need many sample points.
        In order to do that, we need LPPV to setup sample points on the object itself.
    LOD Groups
        https://docs.unity3d.com/Manual/class-LODGroup.html
        Level-Of-Detail (LOD) is an optimization technique, to use a simpler version of an object (mesh, texture, material) when it is far from camera.
        We could configure when the transition between LODs occur in a LOD Group.
        When indirect light and shadow are baked, only LOD0 is calculated.
        We could define a cross-fade transition between levels and Unity will render 2 levels at the same time when camera falls into transition area.

------------------------------------------------------------------
19. REALTIME GI, PROBE VOLUMES, LOD GROUPS