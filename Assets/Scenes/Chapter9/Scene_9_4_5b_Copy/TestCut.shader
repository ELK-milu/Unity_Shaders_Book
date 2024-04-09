Shader "Custom/TestCut" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
	}
	SubShader {
		Pass {
			Tags { "LightMode"="ForwardBase" }

			Cull Front
            Blend SrcAlpha OneMinusSrcAlpha//混合透明度分量，实现半透明

			CGPROGRAM

			#pragma multi_compile_fwdbase

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
				SHADOW_COORDS(3)
			};

			v2f vert(a2v v) {
			 	v2f o;
			 	o.pos = UnityObjectToClipPos(v.vertex);

			 	o.worldNormal = UnityObjectToWorldNormal(v.normal);

			 	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

			 	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

			 	// Pass shadow coordinates to pixel shader
			 	TRANSFER_SHADOW(o);

			 	return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed4 texColor = tex2D(_MainTex, i.uv);
                float alpha = texColor.a*_Color.a ;
				clip( alpha - _Cutoff);

				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);//自阴影

				return fixed4((ambient + diffuse)*atten , alpha);
			}

			ENDCG
		}
Pass {
			Tags { "LightMode"="ForwardBase" }

			Cull Back
            Blend SrcAlpha OneMinusSrcAlpha//混合透明度分量，实现半透明

			CGPROGRAM

			#pragma multi_compile_fwdbase

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
				SHADOW_COORDS(3)
			};

			v2f vert(a2v v) {
			 	v2f o;
			 	o.pos = UnityObjectToClipPos(v.vertex);

			 	o.worldNormal = UnityObjectToWorldNormal(v.normal);

			 	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

			 	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

			 	// Pass shadow coordinates to pixel shader
			 	TRANSFER_SHADOW(o);

			 	return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				fixed4 texColor = tex2D(_MainTex, i.uv);
                float alpha = texColor.a*_Color.a ;
				clip( alpha - _Cutoff);

				fixed3 albedo = texColor.rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);//自阴影

				return fixed4((ambient + diffuse) , alpha);
			}

			ENDCG
		}
		Pass {

			Tags { "LightMode" = "ShadowCaster" }


			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

            struct a2v {
				float4 vertex : POSITION;
                float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
                float3 vec : TEXCOORD0;
				float2  uv : TEXCOORD1;
			};

			float4 _MainTex_ST;
            sampler3D _DitherMaskLOD;//Unity内置的三维抖动纹理

			v2f vert( a2v v )
			{
				v2f o;
                //用于保存顶点到光源的向量
                o.vec = mul(unity_ObjectToWorld, v.vertex).xyz - _LightPositionRange.xyz;
                //在裁剪空间中对坐标z分量应用深度偏移
                o.pos = UnityApplyLinearShadowBias(UnityClipSpaceShadowCasterPos(v.vertex,v.normal));
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			sampler2D _MainTex;
			fixed _Cutoff;
			fixed4 _Color;

			float4 frag( v2f i ) : SV_Target
			{
                //hard shadow:镂空物体的阴影
				fixed4 texcol = tex2D( _MainTex, i.uv );
                float alpha = texcol.a*_Color.a ;
				clip( alpha - _Cutoff);

                //soft shadow(fade shadow):半透明物体的阴影,会加剧阴影的闪烁
                float dither = tex3D(_DitherMaskLOD, float3((i.pos.xy)*0.5, alpha*0.9375 )).a;
                clip(dither - _Cutoff);

                //计算深度
				return UnityEncodeCubeShadowDepth((length(i.vec) + unity_LightShadowBias.x) * _LightPositionRange.w);
			}
			ENDCG
		}

	}
    FallBack "VertexLit"
}