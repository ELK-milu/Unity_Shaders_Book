Shader "Custom/AlphaTest_Shader_Copy"
{
   Properties
   {
      _Color("Color Tint",Color) = (1,1,1,1)
      _MainTex("Main Tex",2D) = "white" {}
      _CutOff("Alpha CutOff",Range(0,1)) = 0.5
   }
   
   SubShader
   {
      // 队列使用透明度测试，IgnoreProjector设置为true意味着Shader不受投影器影响
      // RenderType可以让Unity把Shader归入到提前定义的组————此处为TransparentCutout组
      // 使用了透明度测试的Shader都应该在SubShader中设置这三个标签
      Tags{"Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType"= "TransparentCutout"}
      Pass
      {
         Tags{"LightMode" = "ForwardBase"}
         CGPROGRAM
         #pragma vertex vert
         #pragma fragment frag
         #include "Lighting.cginc"
         #include "UnityCG.cginc"

         fixed4 _Color;
         sampler2D _MainTex;
         float4 _MainTex_ST;
         fixed _CutOff;

         struct a2v
         {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float4 texcoord : TEXCOORD0;
         };

         struct v2f
         {
            float4 pos :SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 worldNormal : TEXCOORD1;
            float3 worldPos : TEXCOORD2;
         };

         v2f vert(a2v v)
         {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

            //o.worldNormal = mul(unity_ObjectToWorld,v.normal).xyz;
            o.worldNormal = UnityObjectToWorldNormal(v.normal);
            o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
            return o;
         }

         float4 frag(v2f i):SV_Target
         {
            fixed3 worldNormalDir = normalize(i.worldNormal);
            fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

            fixed4 texColor = tex2D(_MainTex,i.uv.xy);

            // 舍弃alpha值小于CutOff的片元
            clip(texColor.a - _CutOff);

            fixed3 albedo = texColor.rgb * _Color.rgb;
            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.xyz;
            fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormalDir,worldLightDir));

            return fixed4(diffuse + ambient,1.0);
         }
         ENDCG
      }
   }
   Fallback "Transprant/Cutout/VertexLit"
}
