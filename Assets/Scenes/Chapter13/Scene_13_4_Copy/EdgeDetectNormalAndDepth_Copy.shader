Shader "Custom/EdgeDetectNormalAndDepth_Copy"
{
    Properties
    {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
		_SampleDistance ("Sample Distance", Float) = 1.0
		_Sensitivity ("Sensitivity", Vector) = (1, 1, 1, 1)
    }
    SubShader
    {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		fixed _EdgeOnly;
		fixed4 _EdgeColor;
		fixed4 _BackgroundColor;
		float _SampleDistance;
		half4 _Sensitivity;
		
		sampler2D _CameraDepthNormalsTexture;
		
		struct v2f {
			float4 pos : SV_POSITION;
			// 一维用于保存uv坐标，其余四维用于采样
			half2 uv[10]: TEXCOORD0;
		};
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			half2 uv = v.texcoord;
			o.uv[0] = uv;

			#if UNITY_UV_STARTS_AT_TOP
			if(_MainTex_TexelSize.y < 0)
				uv.y = 1- uv.y;
			#endif

			// 虽然不知道书中的采样方式为什么可以，但一定有它的数学原理
			/* 采样对角四宫格构成的矩阵似乎就能计算边缘值了
			o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance;
			o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance;
			o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance;
			o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance;
			*/
			// 此处我打算用九宫格采样周边像素依次计算，计算结果是一模一样的
			o.uv[1] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance;
			o.uv[2] = uv + _MainTex_TexelSize.xy * half2(0,-1) * _SampleDistance;
			o.uv[3] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance;
			o.uv[4] = uv + _MainTex_TexelSize.xy * half2(-1,0) * _SampleDistance;
			o.uv[5] = uv + _MainTex_TexelSize.xy * half2(0,0) * _SampleDistance;
			o.uv[6] = uv + _MainTex_TexelSize.xy * half2(1,0) * _SampleDistance;
			o.uv[7] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance;
			o.uv[8] = uv + _MainTex_TexelSize.xy * half2(0,1) * _SampleDistance;
			o.uv[9] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance;
					 
			return o;
		}
		// 检查卷积核对象像素深度或法线值是否相同
		half CheckSame(half4 center, half4 sample) {
			half2 centerNormal = center.xy;
			float centerDepth = DecodeFloatRG(center.zw);
			half2 sampleNormal = sample.xy;
			float sampleDepth = DecodeFloatRG(sample.zw);

			// 此处并未对法线解码，因为只需要计算差异度即可
			half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
			int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;

			float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
			int isSameDepth = diffDepth < 0.1 * centerDepth;
			
			// 若深度和法线值存在相同则返回0，说明是边缘，否则若都不相同则返回1
			return isSameNormal * isSameDepth ? 1.0 : 0.0;
		}
		fixed4 fragRobertsCrossDepthAndNormal(v2f i) : SV_Target {
			half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
			half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
			half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);
			half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]);
			half4 sample5 = tex2D(_CameraDepthNormalsTexture, i.uv[5]);
			half4 sample6 = tex2D(_CameraDepthNormalsTexture, i.uv[6]);
			half4 sample7 = tex2D(_CameraDepthNormalsTexture, i.uv[7]);
			half4 sample8 = tex2D(_CameraDepthNormalsTexture, i.uv[8]);
			half4 sample9 = tex2D(_CameraDepthNormalsTexture, i.uv[9]);

			
			half edge = 1.0;

			// 判断是否为边缘，edge=0为边缘，1则不是
			/*
			// Gx卷积核
			edge *= CheckSame(sample1, sample2);
			// Gy卷积核
			edge *= CheckSame(sample3, sample4);
			 */

			// Gx卷积核
			edge *= CheckSame(sample1, sample5);
			edge *= CheckSame(sample2, sample6);
			edge *= CheckSame(sample4, sample8);
			edge *= CheckSame(sample5, sample9);

			// Gy卷积核
			edge *= CheckSame(sample2, sample4);
			edge *= CheckSame(sample3, sample5);
			edge *= CheckSame(sample5, sample7);
			edge *= CheckSame(sample6, sample8);


			//	混合边缘与主纹理
			fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge);
			// 混合边缘与自设背景色
			fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);

			// 混合边缘计算后的纹理和背景色
			return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
		}
		
		ENDCG
		
		Pass { 
			ZTest Always
			Cull Off
			ZWrite Off
			
			CGPROGRAM      
			
			#pragma vertex vert  
			#pragma fragment fragRobertsCrossDepthAndNormal
			
			ENDCG  
		}
    }
    FallBack "Diffuse"
}
