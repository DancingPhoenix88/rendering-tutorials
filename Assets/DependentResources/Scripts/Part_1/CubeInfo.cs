using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CubeInfo : MonoBehaviour {
    [SerializeField] protected Vector3 originalPosition;
    //---------------------------------------------------------------------------------------------------
    protected Transform t;
    //---------------------------------------------------------------------------------------------------
    protected void Awake () {
        t = transform;
    }
    //---------------------------------------------------------------------------------------------------
    public Vector3 GetOriginalPosition () {
        return originalPosition;
    }
    //---------------------------------------------------------------------------------------------------
    public void SetOriginalPosition (Vector3 position) {
        originalPosition = position;
    }
    //---------------------------------------------------------------------------------------------------
    public Transform GetTransform () {
        return t;
    }
}
