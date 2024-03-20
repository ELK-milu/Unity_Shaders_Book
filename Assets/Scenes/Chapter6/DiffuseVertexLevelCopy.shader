// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Chapter6/DiffuseVertexLevelCopy"
{
	Properties{
		_Diffuse ("Diffuse",Color) = (1,1,1,1)
	}
	SubShader{
		Pass{
			Tags{"LightMode" = "ForwardBase"}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"

			fixed4 _Diffuse;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				fixed3 color : COLOR;
			};

			v2f vert(a2v v) {
				v2f o;
				// 用MVP变换将顶点从模型空间变换到裁剪空间
				o.pos = UnityObjectToClipPos(v.vertex);
				// 获取环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				// 将法线从模型空间变换到世界空间
				// 解释一下该公式，mul(v.normal,(float3x3)_World2Object)的原因比较复杂
				// 首先法向量是始终垂直于模型表面，因此无需平移，则其应用的是齐次变换矩阵中的左上方三阶矩阵
				// 即包括了旋转和拉伸的部分
				// 但是法向量的计算是通过顶点插值获取，所以并不等同与顶点计算
				// 由于O2W的左上方三阶矩阵是旋转和缩放的复合矩阵，则[ow2]T = [rotate]T * [scale]T
				// 由于旋转矩阵是正交矩阵，缩放矩阵是对角矩阵，因此上述结果为=[rotate]-1 * [scale]
				// 正确的计算方法是应当对模型法向量应用[O2W]^T来进行反向缩放,再求逆矩阵
				// 所以计算公式是 normal = [[[o2w]T]-1 * n]T =  [[[o2w]-1]T * n]T  = [[w2o]T * n]T = nT * w2o
				fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
				// 获取世界空间中的光照方向
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

				// 计算漫反射光照 ,对应上文公式
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));

				o.color = ambient + diffuse;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				return fixed4(i.color,1.0);
			}
			ENDCG
		}
	}
	FallBack "Diffuse"
}
