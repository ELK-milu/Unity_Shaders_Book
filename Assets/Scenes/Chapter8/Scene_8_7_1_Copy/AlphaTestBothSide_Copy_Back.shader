Shader "Custom/AlphaTestBothSide_Copy_Back"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Texture",2D) = "white" {}
        _AlphaScale("Alpha Scale",Range(0,1)) = 1
         _CutOff("Alpha CutOff",Range(0,1)) = 0.5
    }
    
    SubShader
    {
        Tags{"Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        Cull Back
        Pass
        {
            Tags{"LightingMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _AlphaScale;
            fixed _CutOff;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = _MainTex_ST.xy * v.texcoord.xy + _MainTex_ST.zw;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormalDir = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 MainTexColor = tex2D(_MainTex,i.uv);
                fixed3 albedo = MainTexColor.xyz * _Color.xyz;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.xyz;
                clip(MainTexColor.a - _CutOff);

                fixed3 diffuse = albedo.rgb * _LightColor0.rgb * saturate(dot(worldNormalDir,worldLightDir));

                return fixed4(ambient.xyz + diffuse.xyz , _AlphaScale * MainTexColor.a);
            }
            ENDCG
        }
    }
    Fallback "Transparent/VertexLit"
}
