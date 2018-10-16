Shader "GPU Gems/Wave"
{
  Properties
  {
    _Amplitude ("Amplitude", Float) = 1.0                   // The height from the water plane, to the wave crest.
    _Frequency("Frequency", Float) = 0.5
    _Direction("Direction", Vector) = (1.0, 0.0, 0.0, 1.0)  // Only using the first two variables here, one should be able to pack all values into one vector, then use a custom material editor to allow user interface.
  }
  SubShader
  {
    Tags { "RenderType"="Opaque" }
    LOD 100

    Pass
    {
      // Keyword to start the CG Program
      CGPROGRAM

      // Preprocessors to define vertex and fragment shaders as vert and frag respectively
      #pragma vertex vert
      #pragma fragment frag
      
      // Include the cginc file from (example) ../Unity/2018.1.0f2/Editor/Data/CGIncludes
      // defining a lot of helper functions and utilities. We're not using any in this version however.
      #include "UnityCG.cginc"

      // Define a structure with information we want from each vertex.
      struct appdata
      {
              float4 vertex : POSITION;
      };

      struct v2f
      {
              float4 vertex : SV_POSITION;
      };

      // v2f, seeing as this is the structure we will return. And we call this function vert as we defined with the pragma earlier.
      v2f vert (appdata v)
      {
              v2f o;  // Create an empty v2f structure to load all the information unto.
              o.vertex = UnityObjectToClipPos(v.vertex); // Get the vertex position in Clip space from previously object space.
              return o;
      }
      
      
      // Pixel shader, now that we know the position for each vertex. Draw a flat gray color for all surfaces.
      fixed4 frag (v2f i) : SV_Target
      {
              fixed4 col = fixed4(0.5, 0.5, 0.5, 1.0);
              return col;
      }

      // And finally, end the CG program to return to Unity shaderlab code.
      ENDCG
    }
  }
}
