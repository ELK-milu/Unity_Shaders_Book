Shader "Custom/AlphaBlendBothSideShadowBuild"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white" {}
        _AlphaScale("Alpha Sclae",Range(0,1)) = 1
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags{"Queue"="Geometry" "IgnoreProjector" = "True" "RenderType" = "Transparent"}
        // Back
        // BasePass
        Pass
        {
            Tags{"LightMode" ="ForwardBase"}
            ZWrite Off
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
            fixed _Cutoff;
            fixed _AlphaScale;

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
                clip(texColor.a - _Cutoff);
                fixed3 albedo = _Color.rgb * texColor.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormalDir,worldLightDir));
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                return fixed4(ambient+diffuse * atten,texColor.a * _AlphaScale);
            }
            
            ENDCG
        }
        //Additional Pass
        Pass
        {
            Tags{"LightMode" = "ForwardAdd"}
            ZWrite Off
            Blend One One
            Cull Front
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
            fixed _Cutoff;
            fixed _AlphaScale;
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
                clip(texColor.a - _Cutoff);
                fixed3 albedo = _Color.rgb * texColor.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormalDir,worldLightDir));
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                return fixed4(ambient+diffuse * atten,texColor.a*_AlphaScale);
            }
            ENDCG
        }
        // Front
        // BasePass
        Pass
        {
            Tags{"LightMode" ="ForwardBase"}
            ZWrite Off
            Cull Back
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
            fixed _Cutoff;
            fixed _AlphaScale;
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
                clip(texColor.a - _Cutoff);
                fixed3 albedo = _Color.rgb * texColor.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormalDir,worldLightDir));
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                return fixed4(ambient+diffuse * atten,texColor.a * _AlphaScale);
            }
            ENDCG
        }
        //Additional Pass
        Pass
        {
            Tags{"LightMode" = "ForwardAdd"}
            ZWrite Off
            Blend One One
            Cull Back
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
            fixed _Cutoff;
            fixed _AlphaScale;
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
                clip(texColor.a - _Cutoff);
                fixed3 albedo = _Color.rgb * texColor.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormalDir,worldLightDir));
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                return fixed4(ambient+diffuse * atten,texColor.a * _AlphaScale);
            }
            ENDCG
        }
        // 使用Dithering实现的半透明阴影效果
        // 本质上半透明阴影的实现比较困难，尽量少搞这种东西
        // ShadowCaster
        /*
        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }
            ZWrite On ZTest LEqual
            Cull Off
            CGPROGRAM
            #pragma target 3.0

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_shadowcaster

            #define UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
            #define UNITY_STANDARD_USE_DITHER_MASK
            #define UNITY_STANDARD_USE_SHADOW_UVS

            #include "UnityStandardShadow.cginc"

            fixed _AlphaScale;

            struct VertexOutput
            {
                V2F_SHADOW_CASTER_NOPOS
                float2 tex : TEXCOORD1;
            };

            void vert(VertexInput v, out VertexOutput o, out float4 opos : SV_POSITION)
            {
                TRANSFER_SHADOW_CASTER_NOPOS(o,opos)
                o.tex = v.uv0;
            }
            struct v2f
            {
                V2F_SHADOW_CASTER;
            };
            half4 frag(VertexOutput i, UNITY_VPOS_TYPE vpos : VPOS) : SV_Target
            {
                half alpha = tex2D(_MainTex, i.tex).a * _AlphaScale;

                half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy*0.25,alpha*0.9375)).a;
                clip(alphaRef - 0.01);
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
        */
        // 该Pass作者：lyh萌主 https://www.bilibili.com/read/cv16147169/ 出处：bilibili
		Pass 
		{
			Tags { "LightMode" = "ShadowCaster" }
            Cull Off

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
			fixed _AlphaScale;

			float4 frag( v2f i ) : SV_Target
			{
                //hard shadow:镂空物体的阴影
				fixed4 texcol = tex2D( _MainTex, i.uv );
                float alpha = texcol.a * _AlphaScale;
				clip(alpha - _Cutoff);

                //soft shadow(fade shadow):半透明物体的阴影,会加剧阴影的闪烁
                float dither = tex3D(_DitherMaskLOD, float3((i.pos.xy)*0.5, alpha*0.85)).a ;
                clip(dither - _Cutoff);

                //计算深度
				return UnityEncodeCubeShadowDepth((length(i.vec) + unity_LightShadowBias.x) * _LightPositionRange.w);
			}
			ENDCG
		}
        
    }
    FallBack "VertexLit"
}
