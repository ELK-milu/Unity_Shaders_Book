Shader "Custom/SpecularVertexLevelCopy"
{
    Properties
    {
        _Diffuse ("Diffuse",Color) = (1,1,1,1)
        _Specular ("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",Range(8.0,255)) = 20
    }
    
    SubShader
    {
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma  fragment frag
            #include "Lighting.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));

                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 计算漫反射光颜色
                fixed3 diffuse = _Diffuse.rgb * _LightColor0.rgb * saturate(dot(worldNormal,worldLightDir));
                // 获取反射光方向，实际公式定义和reflect函数正好入射方向是反的，所以注意对入射光反向取反
                //注意千万别搞反了i和n的输入顺序，否则就会在背光面反射
                fixed3 reflectDir = reflect(-worldLightDir,worldNormal);
                // 视角方向即为摄像机点到顶点的方向，两点向量相减后标准化即可
                // normalize(camera-vertex)，注意二者统一到世界坐标下
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex).xyz);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir,viewDir)),_Gloss);
                o.color = ambient + diffuse + specular;
                return o;
            }
			fixed4 frag(v2f i) : SV_Target {
				return fixed4(i.color,1.0);
			}
            ENDCG
        }
    }
    Fallback "Specular"
}
