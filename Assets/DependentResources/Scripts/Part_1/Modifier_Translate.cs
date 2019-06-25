using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Modifier_Translate : AModifier {
    [SerializeField] protected Vector3 amount = Vector3.zero;
    //---------------------------------------------------------------------------------------------------
    public override Vector3 Apply (Vector3 point) {
        return amount + point;
    }
    //---------------------------------------------------------------------------------------------------
    public override Matrix4x4 Get () {
        // return new Matrix4x4(
        //     new Vector4( 1f,        0f,         0f,         0f ),
        //     new Vector4( 0f,        1f,         0f,         0f ),
        //     new Vector4( 0f,        0f,         1f,         0f ),
        //     new Vector4( amount.x,  amount.y,   amount.z,   1f )
        // );
        return Matrix4x4.Translate( amount );
    }
}
