Shader "Custom/NormalMapTangentSpaceCopy"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("MainTex",2D) = "white"{}
        _BumpMap("NormalMap",2D) = "bump"{}
        _BumpScale("Bump Scale",Float) = 1.0
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0,256)) = 20
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
                float4 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

                // 计算贴图纹理和法线贴图的UV坐标
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                // 使用宏直接获取rotation矩阵，也就是模型空间到切线空间的变换矩阵
				TANGENT_SPACE_ROTATION;
                // 获取在模型空间下的方向，再转为切线空间
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
				return o;
            }

            fixed4 frag(v2f i): SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                // tex2D方法获取指定贴图对应像素坐标上的值，一般是颜色值
                fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);
                fixed3 tangentNormal;

                // 是对法线采样的反映射函数，也就是tangentNormal = 2 * packedNormal.xyz - 1
                // 将法线从切线贴图上的RGB转为切线空间的法线坐标
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                // 法线数值由xy决定，法线方向由z决定，因此scale仅对xy应用
                // 对xy方向乘以scale,可通过归一化的逆运算获取
                // 归一化方向向量模长为1，即为(tangentNormal.x)^2 + (tangentNormal.y)^2 + (tangentNormal.z)^2 = 1
                // dot(tangentNormal.xy,tangentNormal.xy) = (x,y) · (x,y) = x^2 + y^2
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                // albedo值 = 纹理贴图像素颜色值 * 纹理面板颜色值
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 用切线空间下的法线和光照方向，视角方向来计算
                fixed3 diffuse = albedo * _LightColor0.rgb * saturate(dot(tangentNormal,tangentLightDir));
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
                fixed3 specular = _Specular.rgb * _LightColor0.rgb * pow(saturate(dot(tangentNormal,halfDir)),_Gloss);

                return fixed4(diffuse + ambient + specular , 1.0);
            }
            ENDCG
        }
    }
Fallback "Specular"
}
