using UnityEngine;

public class GPUInstancingTest : MonoBehaviour {
    [SerializeField] protected Transform prefab;
    [SerializeField] protected int instances = 5000;
    [SerializeField] protected float radius = 50f;
    [SerializeField] protected ColorMode color = ColorMode.FIXED;
    [SerializeField] protected bool useLOD = false;
    //---------------------------------------------------------------------------------------------------
    protected void Start () {
        Transform tRoot = transform;
        MaterialPropertyBlock properties = new MaterialPropertyBlock();
        int PROP_COLOR = Shader.PropertyToID( "_Color" );

        for (int i = 0; i < instances; i++) {
            Transform t = Instantiate(
                prefab, 
                Random.insideUnitSphere * radius,
                Quaternion.identity,
                tRoot
            );

            MeshRenderer mesh = useLOD ? t.GetComponentInChildren<MeshRenderer>() : t.GetComponent<MeshRenderer>();
            if (color == ColorMode.RANDOM) {
                mesh.material.color = 
                    new Color(Random.value, Random.value, Random.value);
            } else if (color == ColorMode.RANDOM_WITH_BLOCK) {
                properties.SetColor( PROP_COLOR, new Color(Random.value, Random.value, Random.value) );
                mesh.SetPropertyBlock( properties );
            }
        }
    }
}
//---------------------------------------------------------------------------------------------------
public enum ColorMode {
    FIXED,
    RANDOM,
    RANDOM_WITH_BLOCK
}
