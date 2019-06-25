using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CubeGenerator : MonoBehaviour {
    [SerializeField] protected CubeInfo prefCube;
    [SerializeField][Range(5, 20)] protected int size = 10;
    //---------------------------------------------------------------------------------------------------
    protected CubeInfo[] cubes;
    //---------------------------------------------------------------------------------------------------
    protected void Awake () {
        cubes = new CubeInfo[ size * size * size ];
        int i = 0;
        for (int x = 0; x < size; ++x) {
            for (int y = 0; y < size; ++y) {
                for (int z = 0; z < size; ++z) {
                    cubes[i++] = Spawn( x, y, z );
                }
            }
        }
    }
    //---------------------------------------------------------------------------------------------------
    protected CubeInfo Spawn (int x, int y, int z) {
        float center = (size - 1) * 0.5f;
        Vector3 position = new Vector3(
            (x - center) * 2f,
            (y - center) * 2f,
            (z - center) * 2f
        );
        CubeInfo cube = Instantiate<CubeInfo>( prefCube, position, Quaternion.identity );
        cube.SetOriginalPosition( position );
        cube.GetComponent<MeshRenderer>().material.color = new Color(
            x * 1f / size,
            y * 1f / size,
            z * 1f / size
        );
        return cube;
    }
    //---------------------------------------------------------------------------------------------------
    public CubeInfo[] GetCubes () {
        return cubes;
    }
}
