Shader "Sprites/Beat/Diffuse-Shadow"
{
    Properties
    {
        _MainTex ("Sprite Texture", 2D) = "white" {}//[PerRendererData] 

		_Palette ("Palette (RGBA)", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _Cutoff ("Shadow alpha cutoff", Range(0,1)) = 0.5
    }
 
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="TransparentCutout"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

		LOD 200
        Cull Off
        Lighting On
        ZWrite On

        CGPROGRAM
        #pragma surface surf Lambert addshadow alphatest:_Cutoff

		#pragma target 3.0
 
        sampler2D _MainTex;
		sampler2D _Palette;
        fixed4 _Color;
 
        struct Input
        {
            float2 uv_MainTex;
			float2 uv_Palette;
			//float3 lightDir;
			//float3 viewDir;
			//float3 worldNormal;
			//INTERNAL_DATA
        };
 
        void surf (Input IN, inout SurfaceOutput o)
        {
            fixed4 c2 = tex2D(_MainTex, IN.uv_MainTex);
			fixed4 c = tex2D(_Palette, float2(c2.r, 0)) * _Color;
			o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG

    }
 
    Fallback "Legacy Shaders/Transparent/Cutout/VertexLit"
}
