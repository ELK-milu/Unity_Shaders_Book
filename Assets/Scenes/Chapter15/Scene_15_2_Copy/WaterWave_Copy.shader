Shader "Custom/WaterWave_Copy"
{
    Properties
    {
        _Color ("Main Color", Color) = (1,1,1,1)
        _MainTex ("Base Tex", 2D) = "white" {}
        _WaveMap ("Wave Map",2D) = "bump"{}
        _Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
		_WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01
		_WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01
		_Distortion ("Distortion", Range(0, 100)) = 10
    }
    SubShader
    {
		Tags { "Queue"="Transparent" "RenderType"="Opaque" }
		// 抓取不透明物体渲染后的缓存，并保存到_RefractionTex纹理中
		// 此处GrabPass在渲染水面纹理之前，因此抓取的是未渲染水面时的场景画面
		GrabPass { "_RefractionTex" }
		Pass
		{
			Tags{ "LightMode"="ForwardBase" }
			CGPROGRAM
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			#pragma multi_compile_fwdbase
			
			#pragma vertex vert
			#pragma fragment frag
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _WaveMap;
			float4 _WaveMap_ST;
			samplerCUBE _Cubemap;
			fixed _WaveXSpeed;
			fixed _WaveYSpeed;
			float _Distortion;	
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
				float4 TtoW1 : TEXCOORD3;  
				float4 TtoW2 : TEXCOORD4; 
			};
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.scrPos = ComputeGrabScreenPos(o.pos);
				
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);

				// 用于计算光照模型（菲涅尔反射）。需要用到世界空间下的切线方向
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				// 计算水波纹理在uv上的采样速度
				float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);
				
				// 对法线纹理采样并将法线纹理转换回切线空间
				// 此处为了模拟水波的不规则运动，bump1边对speed正方向采样，bump2对负方向采样，并将两种法线纹理采样都应用上去
				fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb;
				fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;
				fixed3 bump = normalize(bump1 + bump2);
				
				// 将场景的像素与法线进行混合以实现水面波动和场景画面的颜色值的混合
				// _Distortion越大，水体背后的物体看起来变形程度越大
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				// 对z坐标进行相乘，以模拟深度越大，折射程度越大的效果
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				fixed3 refrCol = tex2D( _RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
				
				// 将采样法线贴图计算的切线空间坐标变换到世界空间下
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

				// 采样主纹理并计算菲涅尔反射
				fixed4 texColor = tex2D(_MainTex, i.uv.xy + speed);

				fixed3 reflDir = reflect(-viewDir, bump);
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb * _Color.rgb;
				
				fixed fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);
				fixed3 finalColor = lerp(refrCol,reflCol,fresnel);
				//fixed3 finalColor = reflCol * fresnel + refrCol * (1 - fresnel);
				
				return fixed4(finalColor, 1);
			}
			ENDCG
		}
    }
	// 不投射阴影
	FallBack Off
}
