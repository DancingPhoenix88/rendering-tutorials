using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public abstract class AModifier : MonoBehaviour {
    public abstract Vector3 Apply (Vector3 point); // Method 1
    //---------------------------------------------------------------------------------------------------
    public abstract Matrix4x4 Get (); // Method 2
}
