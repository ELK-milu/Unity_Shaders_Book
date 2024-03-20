Shader "Custom/NormalMapWorldSpaceCopy"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("MainTex",2D) = "white"{}
        _BumpMap("NormalMap",2D) = "bump"{}
        _BumpScale("BumpScale",Float) = 1
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,255)) = 20
    }
    
    SubShader
    {
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
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv: TEXCOORD0;
                float4 T2W0 : TEXCOORD1;
                float4 T2W1 : TEXCOORD2;
                float4 T2W2 : TEXCOORD3;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = _MainTex_ST.xy * v.texcoord.xy + _MainTex_ST.zw;
                o.uv.zw = _BumpMap_ST.xy * v.texcoord.xy + _BumpMap_ST.zw;
                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                // 为啥
                //float3 worldTangent = mul(unity_ObjectToWorld,v.tangent).xyz;
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBitangent = cross(worldNormal,worldTangent) * v.tangent.w;
                o.T2W0 = float4(worldTangent.x,worldBitangent.x,worldNormal.x,worldPos.x);
                o.T2W1 = float4(worldTangent.y,worldBitangent.y,worldNormal.y,worldPos.y);
                o.T2W2 = float4(worldTangent.z,worldBitangent.z,worldNormal.z,worldPos.z);
                return o;
            }

            fixed4 frag(v2f i) :SV_Target
            {
                float3 worldPos = float3(i.T2W0.w,i.T2W1.w,i.T2W2.w);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                fixed3 Normal = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                Normal.xy *= _BumpScale;
                Normal.z = sqrt(1.0 - saturate(dot(Normal.xy,Normal.xy)));
                // 矩阵乘法
                Normal = normalize(half3(dot(i.T2W0.xyz,Normal),dot(i.T2W1.xyz,Normal),dot(i.T2W2.xyz,Normal)));

                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = albedo * _LightColor0.rgb * saturate(dot(Normal,lightDir));
                fixed3 halfDir = normalize(lightDir + viewDir);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * pow(saturate(dot(Normal,halfDir)),_Gloss);

                return fixed4(diffuse + ambient + specular,1.0);
            }
            
            ENDCG
            
        }
    }
    Fallback "Specular"
}
