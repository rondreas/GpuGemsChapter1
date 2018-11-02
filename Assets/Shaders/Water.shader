Shader "GPU Gems/Wave"
{
  Properties
  {
    _Wavelength_01("Wavelength", Float) = 1.0
    _Amplitude_01("Amplitude", Float) = 1.0                   // The height from the water plane, to the wave crest.
    _Speed_01("Speed", Float) = 0.5
    _Direction_01("Direction", Vector) = (1.0, 0.0, 0.0, 1.0)  // Only using the first two variables here, one should be able to pack all values into one vector, then use a custom material editor to allow user interface.

    _Wavelength_02("Wavelength", Float) = 1.0
    _Amplitude_02("Amplitude", Float) = 1.0                   // The height from the water plane, to the wave crest.
    _Speed_02("Speed", Float) = 0.5
    _Direction_02("Direction", Vector) = (1.0, 0.0, 0.0, 1.0)  // Only using the first two variables here, one should be able to pack all values into one vector, then use a custom material editor to allow user interface.
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

      // Stole the Pie from python math.pi
      #define PI 3.141592653589793

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

      struct wave
      {
        float wavelength;
        float amplitude;
        float speed;
        float2 direction;
      };

      // Our properties exposed in Unity must be made into variables readable by the CG compiler,
      // to do this we simply define variables of the same type (or one that can be converted) and
      // same name. 
      float _Wavelength_01;
      float _Amplitude_01;
      float _Speed_01;
      float4 _Direction_01;

      float _Wavelength_02;
      float _Amplitude_02;
      float _Speed_02;
      float4 _Direction_02;

      wave waves[2];

      float Height(wave Wave, float x, float y)
      {
        /*
         *  Equation 1.
         *    Wi(x,y,t) = Ai * sin(dot(Di, float2(x, y)) * wi + t * PHASE) 
         *
         *  Wave is a function of the vertex position on the horizontal plane, and time.
         *  i denotes which wave we're forming. n=0 -> N
         *
         */

        float w = 2 / Wave.wavelength;
        float phase = Wave.speed * w;
        float height = Wave.amplitude * sin(dot(Wave.direction, float2(x, y)) * w + _Time.y * phase);

        return height;
      }

      // Following https://squircleart.github.io/shading/normal-map-generation.html
      // helped me finially solve the partial derivatives for the height function.

      // I couldn't solve it using the equations provided in the GPU Gems chapter so if you know
      // how one could utilze them instead I'm all ears.

      // NOTE everywhere I've looked it's always the -dx and -dy but this resulted in normals
      // pointing the wrong direction, using vertex world position.

      // Central Finite Difference
      float2 CFD(wave Wave, float x, float y)
      {
        float h = 0.001;

        float dx = (Height(Wave, x + h, y) - Height(Wave, x - h, y)) / h;
        float dy = (Height(Wave, x, y + h) - Height(Wave, x, y - h)) / h;

        return float2(dx, dy);
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

        waves[0].wavelength = _Wavelength_01;
        waves[0].amplitude = _Amplitude_01;
        waves[0].speed = _Speed_01;
        waves[0].direction = normalize(float2(_Direction_01.xz));

        waves[1].wavelength = _Wavelength_02;
        waves[1].amplitude = _Amplitude_02;
        waves[1].speed = _Speed_02;
        waves[1].direction = normalize(float2(_Direction_02.xz));

        // Equation 2 is the sum of all waves, and for now we only have one.
        // Equation 3 is the final position P for each vertex.xy in time.
        worldpos.y += Height(waves[0], worldpos.x, worldpos.z);
        worldpos.y += Height(waves[1], worldpos.x, worldpos.z);

        // Convert the solved worldposition back into object space to transform our vert.
        o.vertex.y += mul(unity_WorldToObject, worldpos.y);

        // Using the Central Finite Difference to solve the partial derivatives required
        // to solve the normal, we also normalize the vector and remap values to be within
        // color space 0->1

        float2 w1cfd = CFD(waves[0], worldpos.x, worldpos.z);
        float2 w2cfd = CFD(waves[1], worldpos.x, worldpos.z);

        float3 N = float3((w1cfd.x + w2cfd.x), 1, (w1cfd.y + w2cfd.y));

        o.color.xyz = normalize(N) * 0.5 + 0.5;
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
