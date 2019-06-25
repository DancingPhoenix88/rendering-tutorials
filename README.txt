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
    Without lighting (& skybox - ambient light), objects look flat.
    Vertex program alters vertices of the mesh (need vertex position in Object-space as input).
    Fragment program alters fragment / pixel color (need pixel position in Screen-space as input).
    Both vertex and fragment program uses the same data, so it is better to define a struct containing data they need.
    By using ': POSITION', ': TEXCOORD0', we tell CPU to fill those attributes with appropriate values before passing to vertex program.
    Property declaration must NOT have semi-colon at the end of the line.
    struct declaration must have semi-colon at the end of the block.
    UV map: [0,0] at the bottom left, [1, 1] aat the top right.
    Unity stores extra data of material when a texture is available in special variables with _ST suffix (Extra data of '_MainTex' is '_MainTex_ST').
    When UV coordinate gets out of range [0, 1], the 'WrapMode' property of texture will decide which pixel to sample. (Clamp = No Tiling & Offset outside of texture).
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
    We can use un-used component in Vector to store custom data for better performance.
    We can use a texture with solid color (only pure RGB & black) to mask areas for each textures = Splat Map.
