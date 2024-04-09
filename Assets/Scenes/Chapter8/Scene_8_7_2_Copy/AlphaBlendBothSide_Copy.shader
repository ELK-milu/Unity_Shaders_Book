Shader "Custom/AlphaBlendBothSide_Copy"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Texture",2D) = "white" {}
        _AlphaScale ("Alpha Scale" , Range(0,1)) = 1
        _CutOff("Cut Off",Range(0,1)) = 0.5
    }
    
    SubShader
    {
        Tags{"Queue"="Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        Pass
        {
            Tags{"LightingMode" = "ForwardBase"}
            // 背面渲染
            Cull Front
            Blend SrcAlpha OneMinusSrcAlpha
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
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = _MainTex_ST.xy * v.texcoord.xy + _MainTex_ST.zw;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormalDir = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 TexColor = tex2D(_MainTex,i.uv);
                fixed3 albedo = TexColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.rgb;

                clip(TexColor.a - _CutOff);

                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldLightDir,worldNormalDir));

                return fixed4(ambient.xyz + diffuse.xyz , _AlphaScale * TexColor.a);

            }
            ENDCG
        }
        Pass
        {
            Tags{"LightingMode" = "ForwardBase"}
            // 正面渲染
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
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
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = _MainTex_ST.xy * v.texcoord.xy + _MainTex_ST.zw;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormalDir = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 TexColor = tex2D(_MainTex,i.uv);
                fixed3 albedo = TexColor.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.rgb;

                clip(TexColor.a - _CutOff);

                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldLightDir,worldNormalDir));

                return fixed4(ambient.xyz + diffuse.xyz , _AlphaScale * TexColor.a);
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
