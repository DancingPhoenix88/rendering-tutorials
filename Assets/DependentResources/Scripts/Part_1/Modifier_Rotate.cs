using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Modifier_Rotate : AModifier {
    [SerializeField] protected Vector3 amount = Vector3.zero;
    //---------------------------------------------------------------------------------------------------
    public override Vector3 Apply (Vector3 point) {
        float radX = amount.x * Mathf.Deg2Rad;
        float radY = amount.y * Mathf.Deg2Rad;
        float radZ = amount.z * Mathf.Deg2Rad;
        float sinX = Mathf.Sin(radX);
        float cosX = Mathf.Cos(radX);
        float sinY = Mathf.Sin(radY);
        float cosY = Mathf.Cos(radY);
        float sinZ = Mathf.Sin(radZ);
        float cosZ = Mathf.Cos(radZ);

        Vector3 xAxis = new Vector3(
            cosY * cosZ,
            cosX * sinZ + sinX * sinY * cosZ,
            sinX * sinZ - cosX * sinY * cosZ
        );
        Vector3 yAxis = new Vector3(
            -cosY * sinZ,
            cosX * cosZ - sinX * sinY * sinZ,
            sinX * cosZ + cosX * sinY * sinZ
        );
        Vector3 zAxis = new Vector3(
            sinY,
            -sinX * cosY,
            cosX * cosY
        );

        return xAxis * point.x + yAxis * point.y + zAxis * point.z;
    }
    //---------------------------------------------------------------------------------------------------
    public override Matrix4x4 Get () {
        // float radX = amount.x * Mathf.Deg2Rad;
        // float radY = amount.y * Mathf.Deg2Rad;
        // float radZ = amount.z * Mathf.Deg2Rad;
        // float sinX = Mathf.Sin(radX);
        // float cosX = Mathf.Cos(radX);
        // float sinY = Mathf.Sin(radY);
        // float cosY = Mathf.Cos(radY);
        // float sinZ = Mathf.Sin(radZ);
        // float cosZ = Mathf.Cos(radZ);

        // return new Matrix4x4(
        //     new Vector4( cosY * cosZ,   cosX * sinZ + sinX * sinY * cosZ,   sinX * sinZ - cosX * sinY * cosZ, 0f ),
        //     new Vector4( -cosY * sinZ,  cosX * cosZ - sinX * sinY * sinZ,   sinX * cosZ + cosX * sinY * sinZ, 0f ),
        //     new Vector4( sinY,          -sinX * cosY,                       cosX * cosY,                      0f ),
        //     new Vector4( 0f,            0f,                                 0f,                               1f )
        // );

        return Matrix4x4.Rotate( Quaternion.Euler( amount ) );
    }
}
