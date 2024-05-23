Shader "Custom/FogWithDepthTexture_Copy"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
		_FogDensity ("Fog Density", Float) = 1.0
		_FogColor ("Fog Color", Color) = (1, 1, 1, 1)
		_FogStart ("Fog Start", Float) = 0.0
		_FogEnd ("Fog End", Float) = 1.0
    }
    SubShader
    {
		CGINCLUDE
		#include "UnityCG.cginc"
		// 裁剪平面的四条射线构成的矩阵，方阵存储虽然浪费了点内存，但不用include其他文件
		float4x4 _FrustumCornersRay;
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture;
		half _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;

		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;
			float4 interpolatedRay : TEXCOORD2;
		};

		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;

			// 根据平台重设UV坐标
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif

			// 根据坐标判断对应顶点落在了那个射线上
			int index = 0;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
				index = 0;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
				index = 1;
			} else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
				index = 2;
			} else {
				index = 3;
			}

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				index = 3 - index;
			#endif

			// 为四边形的每个像素点获取射线方向
			o.interpolatedRay = _FrustumCornersRay[index];
				 	 
			return o;
		}

		fixed4 frag(v2f i) : SV_Target {
			// 采样深度值并转为线性深度
			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
			// 根据偏移计算出像素点坐标，在片元着色器中计算像素就可以对片元以顶点进行插值
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;
			// 计算线性雾效系数
			// _FogEnd是受雾影响的最大距离，_FogStart是受雾影响的最小距离，
			// worldPos.y是计算雾效的距离，此外用不同的轴可以决定雾效扩散的方向（由负方向到正方向）
			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart); 
			fogDensity = saturate(fogDensity * _FogDensity);
			
			fixed4 finalColor = tex2D(_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);
			
			return finalColor;
		}
		ENDCG
		
		Pass {
			ZTest Always Cull Off ZWrite Off
			     	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}	
		
    }
    FallBack Off
}
