using UnityEngine;
using System;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class DofEffect : MonoBehaviour {
    [SerializeField][Range(0.1f, 100f)] protected float focusDistance = 10f;
    [SerializeField][Range(0.1f, 10f)] protected float focusRange = 3f;
    [SerializeField][Range(1f, 10f)] protected float bokehRadius = 4f;
    [SerializeField] protected Shader dofShader;
    [NonSerialized] Material dofMaterial;
    //---------------------------------------------------------------------------------------------------
    protected const int PASS_CIRCLE_OF_CONFUSION    = 0;
    protected const int PASS_PRE_FILTER             = 1;
    protected const int PASS_BOKEH                  = 2;
    protected const int PASS_POST_FILTER            = 3;
    protected const int PASS_COMBINE                = 4;
    //---------------------------------------------------------------------------------------------------
    protected void OnRenderImage (RenderTexture source, RenderTexture destination) {
        // Prepare the shader
        if (dofMaterial == null) {
            dofMaterial = new Material(dofShader);
            dofMaterial.hideFlags = HideFlags.HideAndDontSave;
        }
        dofMaterial.SetFloat("_FocusDistance", focusDistance);
        dofMaterial.SetFloat("_FocusRange", focusRange);
        dofMaterial.SetFloat("_BokehRadius", bokehRadius);

        // Prepare CoC texture
        RenderTexture cocTexture = RenderTexture.GetTemporary(
            source.width, source.height, 0, RenderTextureFormat.RHalf, RenderTextureReadWrite.Linear
        );

        // Prepare bokeh texture
        int width = source.width / 2;
        int height = source.height / 2;
        RenderTextureFormat format = source.format;
        RenderTexture dof0 = RenderTexture.GetTemporary(width, height, 0, format);
        RenderTexture dof1 = RenderTexture.GetTemporary(width, height, 0, format);
        dofMaterial.SetTexture("_CoCTex", cocTexture);
        dofMaterial.SetTexture("_DoFTex", dof0);

        Graphics.Blit(source, cocTexture, dofMaterial, PASS_CIRCLE_OF_CONFUSION);   // Compute focus range
        Graphics.Blit(source, dof0, dofMaterial, PASS_PRE_FILTER);      // Downsample source texture to DOF0
        Graphics.Blit(dof0, dof1, dofMaterial, PASS_BOKEH);             // Produce Bokeh in DOF-1
        Graphics.Blit(dof1, dof0, dofMaterial, PASS_POST_FILTER);       // Blur the bokeh
        Graphics.Blit(source, destination, dofMaterial, PASS_COMBINE);  // Combine bokeh (in DOF-0) with source texture

        RenderTexture.ReleaseTemporary(cocTexture);
        RenderTexture.ReleaseTemporary(dof0);
        RenderTexture.ReleaseTemporary(dof1);
    }
}