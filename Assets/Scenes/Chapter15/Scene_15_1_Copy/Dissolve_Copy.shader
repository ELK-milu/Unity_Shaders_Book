Shader "Custom/Dissolve_Copy"
{
    Properties
    {
		_BurnAmount ("Burn Amount", Range(0.0, 1.0)) = 0.0
    	// _LineWidth代表了周边延申的效果线
		_LineWidth("Burn Line Width", Range(0.0, 10)) = 0.1
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BurnFirstColor("Burn First Color", Color) = (1, 0, 0, 1)
		_BurnSecondColor("Burn Second Color", Color) = (1, 0, 0, 1)
		_BurnMap("Burn Map", 2D) = "white"{}
    }
    SubShader
    {
       Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }

			// 不要剔除背面，不然裁剪面片时会发现没有背面
			Cull Off
			
			CGPROGRAM
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			#pragma multi_compile_fwdbase
			
			#pragma vertex vert
			#pragma fragment frag
			
			fixed _BurnAmount;
			fixed _LineWidth;
			sampler2D _MainTex;
			sampler2D _BumpMap;
			fixed4 _BurnFirstColor;
			fixed4 _BurnSecondColor;
			sampler2D _BurnMap;
			
			float4 _MainTex_ST;
			float4 _BumpMap_ST;
			float4 _BurnMap_ST;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uvMainTex : TEXCOORD0;
				float2 uvBumpMap : TEXCOORD1;
				float2 uvBurnMap : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
				SHADOW_COORDS(5)
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.uvMainTex = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uvBumpMap = TRANSFORM_TEX(v.texcoord, _BumpMap);
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
				
				TANGENT_SPACE_ROTATION;
  				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
  				
  				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
  				
  				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {

				// 对噪声纹理进行采样
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;

				// 根据_BurnAmount来clip像素，保留白色去除黑色
				clip(burn.r - _BurnAmount);
				
				float3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap));
				
				fixed3 albedo = tex2D(_MainTex, i.uvMainTex).rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				// 对裁剪掉的部分进行混合颜色渲染
				fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount);
				// 这一部分渲染的颜色是根据smoothstep获取的形状渲染的，
				// 被裁剪部分=0，因此经过smoothstep后周边模糊区域会保留，中心区域裁剪，渲染范围是裁剪部分区域 + _LineWidth
				// 而越靠近裁剪部分的像素渲染越接近firstColor
				fixed3 burnColor = lerp(_BurnFirstColor, _BurnSecondColor, t);
				// 深化颜色，看起来亮一点
				burnColor = pow(burnColor, 5);
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				// 最终再混合光照和燃烧特效色
				// t在此处还作为模型原色和特效颜色混合的系数
				fixed3 finalColor = lerp(ambient + diffuse * atten, burnColor, t * step(0.0001, _BurnAmount));
				
				return fixed4(finalColor, 1);
			}
			
			ENDCG
		}
		
		// Pass to render object as a shadow caster
		Pass {
			Tags { "LightMode" = "ShadowCaster" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_shadowcaster
			
			#include "UnityCG.cginc"
			
			fixed _BurnAmount;
			sampler2D _BurnMap;
			float4 _BurnMap_ST;
			
			struct v2f {
				V2F_SHADOW_CASTER;
				float2 uvBurnMap : TEXCOORD1;
			};
			
			v2f vert(appdata_base v) {
				v2f o;
				
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;

				// 对阴影也需要剔除
				clip(burn.r - _BurnAmount);
				
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
    }
    FallBack "Diffuse"
}
