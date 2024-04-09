// 一个有意思的现象，在其他光源下正面会出现
// 原因是Additional Pass在接收到其他光源后渲染了物体正面纹理
Shader "Custom/HightLightShowingPass"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white" {}
    }
    SubShader
    {
        Tags{"Queue"="Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        //Back
        // BasePass
        Pass
        {
            Tags{"LightMode" ="ForwardBase"}
            Cull Front
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv :TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormalDir = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex,i.uv);
                fixed3 albedo = _LightColor0.rgb * texColor.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormalDir,worldLightDir));
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                return fixed4(ambient+diffuse * atten,texColor.a);
            }
            ENDCG
        }
        //Additional Pass
        Pass
        {
            Tags{"LightMode" = "ForwardAdd"}
            Blend One One
            CGPROGRAM
            #pragma multi_compile_fwdadd_fullshadows
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv :TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };
            
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }
            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormalDir = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex,i.uv);
                fixed3 albedo = _LightColor0.rgb * texColor.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormalDir,worldLightDir));
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                return fixed4(ambient+diffuse * atten,texColor.a);
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
        /*
        // Front
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma multi_compile_fwdbasealpha
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
                        fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv :TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };
            
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormalDir = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex,i.uv);
                fixed3 albedo = _LightColor0.rgb * texColor.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormalDir,worldLightDir));
                UNITY_LIGHT_ATTENUATION(atten,i,i.pos);
                return fixed4(ambient+diffuse * atten,texColor.a);
            }
            ENDCG
        }
        */
    }
}
