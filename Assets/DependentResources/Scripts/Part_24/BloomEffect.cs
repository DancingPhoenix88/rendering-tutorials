using UnityEngine;
using System;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class BloomEffect : MonoBehaviour {
    [SerializeField][Range(1, 16)] protected int iterations = 4;
    [SerializeField][Range(0, 10)] protected float threshold = 1;
    [SerializeField][Range(0, 1)] protected float softThreshold = 0.5f;
    [SerializeField][Range(0, 10)] protected float intensity = 1;
    [SerializeField] protected Shader bloomShader;
    [SerializeField] protected bool debug;
    [NonSerialized] Material bloom;
    //---------------------------------------------------------------------------------------------------
    protected const int PASS_PRE_FILTER     = 0;
    protected const int PASS_DOWN_SAMPLE    = 1;
    protected const int PASS_UP_SAMPLE      = 2;
    protected const int PASS_APPLY_BLOOM    = 3;
    protected const int PASS_DEBUG_BLOOM    = 4;
    //---------------------------------------------------------------------------------------------------
    protected void OnRenderImage (RenderTexture source, RenderTexture destination) {
        // Prepare shader
        if (bloom == null) {
            bloom = new Material(bloomShader);
            bloom.hideFlags = HideFlags.HideAndDontSave;
        }
        float knee = threshold * softThreshold;
        Vector4 filter;
        filter.x = threshold;
        filter.y = filter.x - knee;
        filter.z = 2f * knee;
        filter.w = 0.25f / (knee + 0.00001f);
        bloom.SetVector("_Filter", filter);
        bloom.SetFloat("_Intensity", Mathf.GammaToLinearSpace(intensity));

        // Copy original texture from camera to a temp texture (discard dark pixels)
        int width = source.width;
        int height = source.height;
        RenderTextureFormat format = source.format;
        RenderTexture[] textures = new RenderTexture[16];
        RenderTexture tempTexture = textures[0] = RenderTexture.GetTemporary( width, height, 0, format );
        Graphics.Blit(source, tempTexture, bloom, PASS_PRE_FILTER);

        // Downsample original texture progressively and save result into an array
        int i = 1;
        for (; i < iterations; ++i) {
            width /= 2;
            height /= 2;
            if (height < 2) break;

            RenderTexture downTexture = textures[i] = RenderTexture.GetTemporary( width, height, 0, format );
            Graphics.Blit( tempTexture, downTexture, bloom, PASS_DOWN_SAMPLE ); // blit to smaller texture
            tempTexture = downTexture;
        }

        // Upsample temporary textures
        for (i -= 2; i >= 0; --i) {
            RenderTexture upTexture = textures[i];
            textures[i] = null;
            Graphics.Blit( tempTexture, upTexture, bloom, PASS_UP_SAMPLE ); // blit to larger texture
            RenderTexture.ReleaseTemporary( tempTexture );
            tempTexture = upTexture;
        }

        // Blend original texture with blury texture to create bloom effect
        bloom.SetTexture("_SourceTex", source);
        if (debug) {
            Graphics.Blit(tempTexture, destination, bloom, PASS_DEBUG_BLOOM);
        } else {
            Graphics.Blit(tempTexture, destination, bloom, PASS_APPLY_BLOOM);
        }
        RenderTexture.ReleaseTemporary( tempTexture );
    }
}