Shader "Custom/VertexAnimationWithShadow_Copy"
{
    Properties
    {
        _MainTex("Main Tex",2d) = "white" {}
        _Color("Color Tint",Color) = (1,1,1,1)
        _Magnitude("Distortion Magnitude",Float) = 1
        _Frequency("Distortion Frequency",Float) = 1
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10
 		_Speed ("Speed", Float) = 0.5
    }
    SubShader
    {
        Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
        Pass
        {
            Tags{"LightMode"="ForwardBase"}
            ZWrite Off
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma mutli_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
            float _Speed;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed4 offset : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
  				float4 offset;
				offset = float4(0.0,0.0, 0.0, 0.0);
				offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
                o.pos = UnityObjectToClipPos(v.vertex + offset);
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv += float2(0.0,_Time.y * _Speed);
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                
                fixed4 color = tex2D(_MainTex,i.uv) * _Color;
                return color;
            }
            
            ENDCG
        }
        Pass
        {
            Tags{"LightMode"="ShadowCaster"}
            CGPROGRAM
            #pragma multi_compile_shadowcaster
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
			float _Speed;
            
			struct v2f {
				// 使用该宏定义阴影计算所需的变量
			    V2F_SHADOW_CASTER;
			};

			v2f vert(appdata_base v) {
				v2f o;
  				float4 offset;
				offset = float4(0.0,0.0, 0.0, 0.0);
				offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
				v.vertex = v.vertex + offset;

				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				
				return o;
			}
            fixed4 frag(v2f i) : SV_Target {
			    SHADOW_CASTER_FRAGMENT(i)
			}
            ENDCG
        }
    }
    FallBack "VertexLit"
}
