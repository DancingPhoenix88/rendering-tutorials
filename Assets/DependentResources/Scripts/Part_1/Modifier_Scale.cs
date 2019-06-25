using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Modifier_Scale : AModifier {
    [SerializeField] protected Vector3 amount = Vector3.one;
    //---------------------------------------------------------------------------------------------------
    public override Vector3 Apply (Vector3 point) {
        return Vector3.Scale( point, amount );
    }
    //---------------------------------------------------------------------------------------------------
    public override Matrix4x4 Get () {
        // return new Matrix4x4(
        //     new Vector4( amount.x,  0f,         0f,         0f ),
        //     new Vector4( 0f,        amount.y,   0f,         0f ),
        //     new Vector4( 0f,        0f,         amount.z,   0f ),
        //     new Vector4( 0f,        0f,         0f,         1f )
        // );
        return Matrix4x4.Scale( amount );
    }
}
