Shader "Custom/GlassRefraction_2_Copy"
{
     Properties
    {
        _MainTex("Main Tex",2D) = "white" {}
        _BumpMap("Normal Map",2D) = "bump" {}
        _Cubemap("Cube Map",Cube) = "_skybox" {}
        _Distortion("Distortion",Range(0,100)) = 10
        _RefractAmount("Refraction Amount",Range(0,1)) = 1
    }
    
    SubShader
    {
        //  "RenderType"="Opaque" 为了使用着色器替换（Shader Replacement）时，该物体被正确渲染
        Tags{"Queue" = "Transparent" "RenderType" ="Opaque"}
        // 抓取不透明物体渲染后的缓存，并保存到_RefractionTex纹理中
        GrabPass { "_RefractionTex" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _Cubemap;
            float _Distortion;
            fixed _RefractAmount;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;

            struct a2v
            {
                float4 vertex:POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
			    float4 TtoW1 : TEXCOORD3;  
			    float4 TtoW2 : TEXCOORD4; 
            };

            // 获取从切线空间转换到世界空间下的坐标，从而获得T2W转换矩阵
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.pos);

                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);

                float3 worldPos = o.pos;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = mul(unity_ObjectToWorld,v.tangent);
                float3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);

                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                
                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));

                // 计算折射光的偏移 = 法线纹理 * 扭曲值 * 折射纹理(GrabPass的缓存颜色)
                float2 refractionOffset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;

                // 应用矩阵变换将法线变换到世界空间中
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                
                // 对Grab的RenderTex纹理的offset进行计算以应用折射光偏移
                // max(0.5,(1-i.scrPos.z))根据深度对折射纹理进行采样
                i.scrPos.xy = refractionOffset * max(0.5,(1-i.scrPos.z)) + i.scrPos.xy;
                // 我们不能直接对_RefractionTex进行采样，因为ComputeScreenPos得到的scrPos是使用o.pos计算得到的
                // 因此scrPos是齐次裁剪空间下的四维向量，若需要采样则应当先应用齐次除法转换到NDC空间下
                fixed3 refractionColor = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
                
                fixed3 reflectDir = reflect(-worldViewDir,bump);
                fixed4 texColor = tex2D(_MainTex,i.uv.xy);
                fixed3 reflectColor = texCUBE(_Cubemap,reflectDir).rgb * texColor.rgb;
                
                fixed3 finalColor = reflectColor * (1-_RefractAmount) + refractionColor * _RefractAmount;
                return fixed4(finalColor, 1);
            }
            
            ENDCG
        }
    }
	Fallback "Diffuse"
}
