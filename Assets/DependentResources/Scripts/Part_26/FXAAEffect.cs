using UnityEngine;
using System;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class FXAAEffect : MonoBehaviour {
    [SerializeField] protected Shader fxaaShader;
    [SerializeField] protected LuminanceMode luminanceSource = LuminanceMode.CALCULATE;
    [SerializeField][Range(0.0312f, 0.0833f)] protected float contrastThreshold = 0.0312f;
    [SerializeField][Range(0.063f, 0.333f)] protected float relativeThreshold = 0.063f;
    [SerializeField][Range(0f, 1f)] protected float subpixelBlending = 1f;
    [SerializeField] protected bool lowQuality;
    [SerializeField] protected bool gammaBlending;
    [NonSerialized] protected Material fxaaMaterial;
    //---------------------------------------------------------------------------------------------------
    protected const int PASS_LUMINANCE  = 0;
    protected const int PASS_FXAA       = 1;
    //---------------------------------------------------------------------------------------------------
    void OnRenderImage (RenderTexture source, RenderTexture destination) {
        // Prepare the shader
        if (fxaaMaterial == null) {
            fxaaMaterial = new Material(fxaaShader);
            fxaaMaterial.hideFlags = HideFlags.HideAndDontSave;
        }
        fxaaMaterial.SetFloat("_ContrastThreshold", contrastThreshold);
        fxaaMaterial.SetFloat("_RelativeThreshold", relativeThreshold);
        fxaaMaterial.SetFloat("_SubpixelBlending", subpixelBlending);
        fxaaMaterial.SetKeyword( "LOW_QUALITY", lowQuality );
        fxaaMaterial.SetKeyword( "GAMMA_BLENDING", gammaBlending );

        // Calculate luminance
        if (luminanceSource == LuminanceMode.CALCULATE) {
            fxaaMaterial.DisableKeyword("LUMINANCE_GREEN");
            RenderTexture luminanceTex = RenderTexture.GetTemporary(
                source.width, source.height, 0, source.format
            );
            Graphics.Blit(source, luminanceTex, fxaaMaterial, PASS_LUMINANCE);
            Graphics.Blit(luminanceTex, destination, fxaaMaterial, PASS_FXAA);
            RenderTexture.ReleaseTemporary(luminanceTex);
        } else {
            fxaaMaterial.SetKeyword( "LUMINANCE_GREEN", luminanceSource == LuminanceMode.GREEN );
            Graphics.Blit(source, destination, fxaaMaterial, PASS_FXAA);
        }
    }
}
//---------------------------------------------------------------------------------------------------
public enum LuminanceMode {
    ALPHA,
    GREEN, 
    CALCULATE
}
//---------------------------------------------------------------------------------------------------
public static class MaterialExtension {
    public static void SetKeyword (this Material m, string keyword, bool enabled) {
        if (enabled) {
            m.EnableKeyword( keyword );
        } else {
            m.DisableKeyword( keyword );
        }
    }
}