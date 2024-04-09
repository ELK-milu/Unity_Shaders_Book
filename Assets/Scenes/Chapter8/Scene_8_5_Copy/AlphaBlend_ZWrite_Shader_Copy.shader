Shader "Custom/AlphaBlend_ZWrite_Shader_Copy"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white" {}
        _AlphaScale("Alpha Scale",Range(0,1)) = 1
    }
    
    SubShader
    {
        Tags{"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" ="Transparent"}
        // 只需增加一个进行深度写入的Pass即可
		Pass {
			ZWrite On
			// ColorMask用于设置颜色通道的 写掩码(write mask)
			// 包括 RGB | A | 0 | 以及其他RGBA的组合 ,当其为对应值时代表对对应通道写入颜色值，当为0则不写入任何颜色值
			ColorMask 0
		}
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _AlphaScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNromal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = _MainTex_ST.xy * v.texcoord.xy + _MainTex_ST.zw;
                o.worldNromal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.pos));
                fixed3 worldNormalDir = normalize(i.worldNromal);

                fixed4 texColor = tex2D(_MainTex,i.uv);
                fixed3 albedo = _Color.rgb * texColor.xyz;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.xyz;

                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldLightDir,worldNormalDir));

                return fixed4(ambient + diffuse , _AlphaScale * texColor.a);
            }
            
            ENDCG
        }
    }
	FallBack "Transparent/VertexLit"
}
