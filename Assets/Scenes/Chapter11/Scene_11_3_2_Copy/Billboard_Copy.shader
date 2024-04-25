Shader "Custom/Billboard_Copy"
{
    Properties
    {
        _MainTex("Main Tex",2D) = "white"{}
        _Color("Color Tint",Color) = (1,1,1,1)
    	// 垂直率，1为法线垂直与平面，0为平行与平面
		_VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1 
    }
    SubShader
    {
        Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching" = "True"}
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed _VerticalBillboarding;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                // 以空间坐标原点为锚点构建法线
                float3 center = float3(0, 0, 0);
                
				float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos, 1));
				// 法线始终指向view方向
				float3 normalDir = viewer - center;

            	// 对y应用垂直率，_VerticalBillboarding越小，法线方向越落到xz平面上
            	// 因此_VerticalBillboarding控制了法线在垂直方向上的约束度
            	// 当_VerticalBillboarding为1时则还是法线方向，当其为0代表完全落在了xz平面上
				normalDir.y =normalDir.y * _VerticalBillboarding;
				normalDir = normalize(normalDir);

                // 根据法线y方向确定向上的方向,若法线正好为(0,1,0)或(0,-1,0)则法线将与up向量方向平行，此时需要将up方向指向模型表面方向(0,0,1)
            	// 避免两向量平行叉乘出零向量
            	// 其余情况下则保持平面y轴始终向上，即(0,1,0)
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
            	// 叉乘计算与两向量垂直的向右基向量
				float3 rightDir = normalize(cross(upDir, normalDir));
            	// 再计算法线和向右正交基构成的向上的基向量
            	
				upDir = normalize(cross(normalDir, rightDir));

            	// 计算锚点位置，锚点=顶点位置 + 顶点到锚点的偏移量
                float3 centerOffs = v.vertex.xyz - center;
            	// 变换后的位置是基于锚点的，对centerOffs乘以变换后的基向量(相当于应用了平移的矩阵变换）
				float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;

            	// 由于存在平移变换(非线性)，因此需要先转为四维矩阵再计算Clip空间
				o.pos = UnityObjectToClipPos(float4(localPos, 1));
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

				return o;
            }

            fixed4 frag (v2f i) : SV_Target {
				fixed4 c = tex2D (_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				
				return c;
			}
            ENDCG
        }
    }
	FallBack "Transparent/VertexLit"
}
