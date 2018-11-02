using UnityEngine;
using UnityEditor;
using System;

[Serializable]
public struct Wave
{
    public float Wavelength { get; set; }
    public float Amplitude { get; set; }
    public float Speed { get; set; }
    public Vector2 Direction { get; set; }
}

public class WaveShaderGUI : ShaderGUI {

	public override void OnGUI (MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);

        Material targetMaterial = materialEditor.target as Material;
    }

}
