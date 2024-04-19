Shader "Custom/Refraction_Copy"
{
   Properties
   {
      _Color("Color Tint",Color) =(1,1,1,1)
      _RefractColor("Refraction Color",Color) = (1,1,1,1)
      // 折射强度,用于lerp计算
      _RefractAmount("Refraction Amount",Range(0,1)) = 1
      // 相对折射率 = 射入介质折射率/原介质折射率
      _RefractRatio("Refraction Ratio",Range(0.1,1)) = 0.5
      _Cubemap("Refraction Cubemap",Cube) = "_Skybox"{}
   }
   
   SubShader
   {
      Tags{"Queue" = "Geometry" "RenderType" = "Opaque"}
      Pass
      {
         Tags{"LightMode" = "ForwardBase"}
         CGPROGRAM
         #pragma vertex vert
         #pragma fragment frag
         #pragma multi_compile_fwdbase
         #include "UnityCG.cginc"
         #include "Lighting.cginc"
         #include "AutoLight.cginc"
         fixed4 _Color;
         fixed4 _RefractColor;
         fixed _RefractAmount;
         fixed _RefractRatio;
         samplerCUBE _Cubemap;

         struct v2f
         {
            float4 pos : SV_POSITION;
            float3 worldPos : TEXCOORD0;
            float3 worldView : TEXCOORD1;
            float3 worldNormal : TEXCOORD2;
            float3 worldRefract : TEXCOORD3;
            SHADOW_COORDS(4)
         };

         v2f vert(appdata_base v)
         {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.worldPos = mul(unity_ObjectToWorld,v.vertex);
            o.worldNormal = UnityObjectToWorldNormal(v.normal);
            o.worldView = UnityWorldSpaceViewDir(o.worldPos);
            // 根据入射方向和法线以及相对折射率计算折射方向
            o.worldRefract = refract(-normalize(o.worldView),normalize(o.worldNormal),_RefractRatio);
            TRANSFER_SHADOW(o);
            return o;
         }

         fixed4 frag(v2f i):SV_Target
         {
            fixed3 worldNormalDir = normalize(i.worldNormal);
            fixed3 worldViewDir = normalize(i.worldView);
            fixed3 worldRefractDir = normalize(i.worldRefract);
            fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;
            fixed3 diffuse = _LightColor0.rgb * _Color.rgb * saturate(dot(worldNormalDir,worldLightDir));
            fixed3 refraction = texCUBE(_Cubemap,i.worldRefract).rgb * _RefractColor.rgb;
            UNITY_LIGHT_ATTENUATION(atten ,i,i.worldPos);
            fixed3 color = ambient+ lerp(diffuse,refraction,_RefractAmount) * atten;
            return fixed4(color,1.0);
         }
         ENDCG
      }
   }
   Fallback "Diffuse"
}
