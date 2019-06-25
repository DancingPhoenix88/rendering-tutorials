using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ModifiersManager : MonoBehaviour {
    public bool combinedModifiersEnabled = false;
    [SerializeField] protected CubeGenerator cubeGenerator;
    //---------------------------------------------------------------------------------------------------
    protected AModifier[] modifiers;
    protected CubeInfo[] cubes;
    protected int countCubes = 0;
    protected Matrix4x4 combinedModifiers;
    //---------------------------------------------------------------------------------------------------
    protected void Init () {
        if (cubes == null) {
            cubes = cubeGenerator.GetCubes();
            countCubes = cubes.Length;

            modifiers = GetComponents<AModifier>();
        }
    }
    //---------------------------------------------------------------------------------------------------
    protected void Update () {
        Init();

        if (combinedModifiersEnabled) {
            CombineModifiers();
        }
        for (int i = 0; i < countCubes; ++i) {
            cubes[i].GetTransform().localPosition = BatchApply( cubes[i].GetOriginalPosition() );
        }
    }
    //---------------------------------------------------------------------------------------------------
    protected Vector3 BatchApply (Vector3 position) {
        if (combinedModifiersEnabled == false) {
            // Method 1: Apply each modifiers to each cube
            for (int i = 0; i < modifiers.Length; ++i) {
                position = modifiers[i].Apply( position );
            }
        } else {
            // Method 2: Combine modifiers ONCE, then apply to each cube
            position = combinedModifiers.MultiplyPoint( position );

            // even faster with assumption: last matrix row = [0, 0, 0, 1]
            // position = combinedModifiers.MultiplyPoint3x4( position );
        }
        return position;
    }
    //---------------------------------------------------------------------------------------------------
    protected void CombineModifiers () {
        combinedModifiers = modifiers[0].Get();
        for (int i = 1; i < modifiers.Length; ++i) {
            combinedModifiers = modifiers[i].Get() * combinedModifiers;
        }
    }
}
