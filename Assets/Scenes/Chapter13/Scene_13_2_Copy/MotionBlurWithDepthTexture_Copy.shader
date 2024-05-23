Shader "Custom/MotionBlurWithDepthTexture_Copy"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
		_BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture;
		float4x4 _CurrentViewProjectionInverseMatrix;
		float4x4 _PreviousViewProjectionMatrix;
		half _BlurSize;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;
		};
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif
					 
			return o;
		}

		fixed4 frag(v2f i) : SV_Target {
			// 采样深度值
			float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);

			// 我的一个误区，从NDC空间变换到齐次裁剪空间不需要“齐次乘法”，
			// 因为齐次除法就是除以了VP矩阵的w分量，所以乘以了VP矩阵的逆其实就是应用了所谓齐次乘法
			
			// 逆运算将深度值以及屏幕采样的像素坐标重新映射回NDC坐标
			float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, depth * 2 - 1, 1);
			// 乘以当前帧vp逆矩阵获得当前帧下像素点对应的世界空间下的四维向量
			float4 D = mul(_CurrentViewProjectionInverseMatrix, H );
			// 再次应用其次除法变换为世界坐标
			float4 worldPos = D / D.w;
			
			float4 currentPos = H;
			// 用当前世界坐标与前一帧的VP矩阵相乘获得前一帧NDC下的四维向量
			float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
			// 应用其次除法获得NDC坐标
			previousPos /= previousPos.w;

			// 用坐标差的均值计算不同分量上顶点运动的速度
			float2 velocity = (currentPos.xy - previousPos.xy)/2.0f;
			
			float2 uv = i.uv;
			float4 color = tex2D(_MainTex, uv);
			// 用_BlurSize来控制采样的偏移
			uv += velocity * _BlurSize;

			// 为当前帧根据速度叠加两帧采样偏移的画面，用三帧合并的渲染画面体现运动模糊的效果
			for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
				float4 currentColor = tex2D(_MainTex, uv);
				color += currentColor;
			}
			// 对三帧合并的画面计算均值
			color /= 3;
			
			return fixed4(color.rgb, 1.0);
		}
		ENDCG
		Pass {      
			ZTest Always
			Cull Off
			ZWrite Off
			    	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}
    }
}
