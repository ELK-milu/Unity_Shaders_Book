Shader "Custom/Water_Copy"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
    	// 波动幅度
		_Magnitude ("Distortion Magnitude", Float) = 1
    	// 波动频率
 		_Frequency ("Distortion Frequency", Float) = 1
    	// 波长的倒数
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10
 		_Speed ("Speed", Float) = 0.5
    }
    SubShader
    {
    	// 设置透明渲染Tag
    	// DisableBatching不允许进行批处理，批处理会合并所有相关的模型，这些模型各自的模型空间就会丢失
    	// 我们需要在物体的模型空间下对顶点位置进行偏移，因此需要取消Shader的批处理操作
    	Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
    	Pass
    	{
    		Tags { "LightMode"="ForwardBase" }
    		ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off
			CGPROGRAM  
			#pragma vertex vert 
			#pragma fragment frag
			#include "UnityCG.cginc" 
			
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
				fixed4 offset :TEXCOORD1;
			};

			// 在顶点着色器中，直接在模型空间对顶点应用正弦变换
			v2f vert(a2v v)
			{
				v2f o;
				float4 offset = float4(0.0,0.0,0.0,0.0);
				// 最终结果是(offset.x,0,0,0)
				offset = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
				// 为了方便理解，可以先将模型坐标转换为世界坐标
				// 然后再变换到ClipPos下，但是offset是在模型空间下应用的，因此也需要转换后使用
				fixed4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				fixed4 worldOffset = mul(unity_ObjectToWorld, offset);
				o.offset = offset;
				
				o.pos = UnityWorldToClipPos(worldPos + worldOffset);
				// 书中原来的方法
				//o.pos = UnityObjectToClipPos(v.vertex + offset);
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
				o.uv +=  float2(0.0, _Time.y * _Speed);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				fixed4 c = tex2D(_MainTex, i.uv);
				c.rgb *= _Color.rgb;
				return c;
			} 
			ENDCG
    	}
    }
	FallBack "Transparent/VertexLit"
}
