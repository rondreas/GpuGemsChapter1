Shader "GPU Gems/Wave"
{
  Properties
  {
    _Wavelength ("Wavelength", Float) = 1.0
    _Amplitude ("Amplitude", Float) = 1.0                   // The height from the water plane, to the wave crest.
    _Speed("Speed", Float) = 0.5
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
      
      // Include the cginc file from your Unity installation (../Unity/2018.1.0f2/Editor/Data/CGIncludes)
      // defining a lot of helper functions and utilities. We're not using any in this version however.
      // #include "UnityCG.cginc"

      // Define a structure with information we want from each vertex.
      struct appdata
      {
        float4 vertex : POSITION;
      };

      struct v2f
      {
        float4 vertex : SV_POSITION;
      };

      // Our properties exposed in Unity must be made into variables readable by the CG compiler,
      // to do this we simply define variables of the same type (or one that can be converted) and
      // same name. 
      float _Wavelength;
      float _Amplitude;
      float _Speed;
      float4 _Direction;

      /*
       *  Equation 1.
       *    Wi(x,y,t) = Ai * sin(dot(Di, float2(x, y)) * wi + t * PHASE) 
       *
       *  Wave is a function of the vertex position on the horizontal plane, and time.
       *
       */
      float Equation_1(float x, float y, float t)
      {
        float w = 2 / _Wavelength;
        float phase = _Speed * w;

        float wave = _Amplitude * sin(dot(_Direction.xz, float2(x, y)) * w + t * phase);

        return wave;
      }

      /*
       *  Normals and Tangents,
       */

      /* Calculate the Binormal */
      float3 Equation_4(float x, float y)
      {
        return float3(1, 0, 0);
      }

      /* Tangent */
      float3 Equation_5(float x, float y)
      {
        return float3(1, 0, 0);
      }
      
      /* Normal */
      float3 Equation_6(float x, float y)
      {
        return float3(1, 0, 0);
      }

      // v2f, seeing as this is the structure we will return. And we call this function vert 
      // as we defined with the pragma earlier.
      v2f vert (appdata v)
      {
        // Create an empty v2f structure to load all the information unto.
        v2f o;  

        // Get the vertex position in Clip space from previously object space.
        o.vertex = UnityObjectToClipPos(v.vertex); 

        /*
         *  _Time is already defined float4 by Unity, holding different values of time from which 
         *  we will use _Time.y which should be the curent time. 
         *
         *  Explained at Unity Answers: http://answers.unity.com/answers/1292847/view.html
         */

        // Equation 2 is the sum of all waves, and for now we only have one.
        // Equation 3 is the final position P for each vertex.xy in time.
        o.vertex.y += Equation_1(v.vertex.x, v.vertex.z, _Time.y);

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
