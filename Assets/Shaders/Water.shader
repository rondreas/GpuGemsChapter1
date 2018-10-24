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

      // Include debug symbols to allow debugging in Renderdoc.
      #pragma enable_d3d11_debug_symbols 
      
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
        float4 color: COLOR;
      };

      // Our properties exposed in Unity must be made into variables readable by the CG compiler,
      // to do this we simply define variables of the same type (or one that can be converted) and
      // same name. 
      float _Wavelength;
      float _Amplitude;
      float _Speed;
      float4 _Direction;

      float height(float x, float y, float t)
      {
        /*
         *  Equation 1.
         *    Wi(x,y,t) = Ai * sin(dot(Di, float2(x, y)) * wi + t * PHASE) 
         *
         *  Wave is a function of the vertex position on the horizontal plane, and time.
         *  i denotes which wave we're forming. n=0 -> N
         *
         */

        float w = 2 / _Wavelength;
        float phase = _Speed * w;

        float wave = _Amplitude * sin(dot(_Direction.xz, float2(x, y)) * w + t * phase);

        return wave;
      }

      // Following https://squircleart.github.io/shading/normal-map-generation.html
      // helped me finially solve the partial derivatives for the height function.

      // I couldn't solve it using the equations provided in the GPU Gems chapter so if you know
      // how one could utilze them instead I'm all ears.

      // NOTE everywhere I've looked it's always the -dx and -dy but this resulted in normals
      // pointing the wrong direction, using vertex world position.

      // Forward Finite Difference
      float3 FFD(float x, float y)
      {
        float h = 0.001;

        float dx = (height(x + h, y, _Time.y) - height(x, y, _Time.y)) / h;
        float dy = (height(x, y + h, _Time.y) - height(x, y, _Time.y)) / h;

        return float3(dx, 1, dy);
      }

      // Backward Finite Difference
      float3 BFD(float x, float y)
      {
        float h = 0.001;

        float dx = (height(x + h, y, _Time.y) - height(x, y, _Time.y)) / h;
        float dy = (height(x, y + h, _Time.y) - height(x, y, _Time.y)) / h;

        return float3(dx, 1, dy);
      }

      // Central Finite Difference
      float3 CFD(float x, float y)
      {
        float h = 0.001;

        float dx = (height(x + h, y, _Time.y) - height(x - h, y, _Time.y)) / h;
        float dy = (height(x, y + h, _Time.y) - height(x, y - h, _Time.y)) / h;

        return float3(dx, 1, dy);
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

        // Get the vertex world position,
        float4 worldpos = mul(unity_ObjectToWorld, v.vertex);

        // Equation 2 is the sum of all waves, and for now we only have one.
        // Equation 3 is the final position P for each vertex.xy in time.
        worldpos.y += height(worldpos.x, worldpos.z, _Time.y);

        // Convert the solved worldposition back into object space to transform our vert.
        o.vertex.y += mul(unity_WorldToObject, worldpos.y);

        // Using the Central Finite Difference to solve the partial derivatives required
        // to solve the normal, we also normalize the vector and remap values to be within
        // color space 0->1
        o.color.xyz = normalize(CFD(worldpos.x, worldpos.z)) * 0.5 + 0.5;

        // Set alpha to fully opaque,
        o.color.w = 1.0;

        return o;
      }
      
      // Pixel shader, now that we know the position for each vertex. Draw a flat gray color for all surfaces.
      fixed4 frag (v2f i) : SV_Target
      {
        fixed4 col = i.color;
        return col;
      }

      // And finally, end the CG program to return to Unity shaderlab code.
      ENDCG
    }
  }
}
