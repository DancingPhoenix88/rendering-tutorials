using UnityEngine;

public class SurfaceVectorVisualizer : MonoBehaviour {
    protected Vector3[] vertices;
    protected Vector3[] normals;
    protected Vector4[] tangents;
    protected int countVertices;
    protected Transform t;
    //---------------------------------------------------------------------------------------------------
    protected void Init () {
        if (t != null) {
            return;
        }
        MeshFilter meshFilter = GetComponent<MeshFilter>();
        t = transform;
        Mesh mesh = meshFilter.sharedMesh;
        vertices  = mesh.vertices;
        normals   = mesh.normals;
        tangents  = mesh.tangents;
        countVertices = vertices.Length;
    }
    //---------------------------------------------------------------------------------------------------
    protected void OnDrawGizmos () {
        Init();
        ShowNormalVectors();
        ShowTangentVectors();
        ShowBinormalVectors();
    }
    //---------------------------------------------------------------------------------------------------
    protected void ShowNormalVectors () {
        Gizmos.color = Color.red;
        for (int i = 0; i < countVertices; i++) {
            DrawVector(
                t.TransformPoint(vertices[i]),      // Local to world
                t.TransformDirection(normals[i])    // Local to world
            );
        }
    }
    //---------------------------------------------------------------------------------------------------
    protected void ShowTangentVectors () {
        Gizmos.color = Color.green;
        for (int i = 0; i < countVertices; i++) {
            DrawVector(
                t.TransformPoint(vertices[i]),      // Local to world
                t.TransformDirection(tangents[i])    // Local to world
            );
        }
    }
    //---------------------------------------------------------------------------------------------------
    protected void ShowBinormalVectors () {
        Gizmos.color = Color.blue;
        for (int i = 0; i < countVertices; i++) {
            Vector3 binormal = Vector3.Cross( 
                t.TransformDirection(normals[i]), 
                t.TransformDirection(tangents[i])
            ) * tangents[i].w; // binormal sign (1 / -1)
            DrawVector(
                t.TransformPoint(vertices[i]),      // Local to world
                binormal    // Local to world
            );
        }
    }
    //---------------------------------------------------------------------------------------------------
    protected void DrawVector (Vector3 origin, Vector3 direction, float length = 0.1f) {
        Gizmos.DrawLine( origin, origin + direction * length );
    }
}