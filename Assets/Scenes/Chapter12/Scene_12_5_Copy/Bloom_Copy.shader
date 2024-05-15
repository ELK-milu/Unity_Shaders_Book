Shader "Custom/Bloom_Copy"
{
    
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        // 由于需要混合两张RenderTexture，因此设置两个2DTex
		_Bloom ("Bloom (RGB)", 2D) = "black" {}
        _LuminanceThreshold ("Luminance Threshold", Float) = 0.5
		_BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        sampler2D _Bloom;
        half4 _Bloom_TexelSize;
        float _LuminanceThreshold;
        float _BlurSize;

        struct v2f
        {
            float4 pos : SV_POSITION; 
			half2 uv : TEXCOORD0;
        };

        v2f vertGetBright(appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
            return o;
        }

        // 计算对比度，此处因为物体主体部分是红绿，因此希望提高红绿采样的对比度
        fixed luminance(fixed4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
		}
        fixed4 fragGetBright(v2f i):SV_Target
        {
			fixed4 c = tex2D(_MainTex, i.uv);
        	// 获取较亮区域的方法竟然是使得整张图变暗
        	// 减去阈值获取暗度图像，阈值以上视为亮部
			fixed val = clamp(c - _LuminanceThreshold, 0.0, 1.0);
			return c * val;
        }

        struct v2fBloom {
			float4 pos : SV_POSITION;
        	// 存储了两张uv，_MainTex和_Bloom
			half4 uv : TEXCOORD0;
		};
        v2fBloom vertBloom(appdata_img v)
        {
            v2fBloom o;
			
			o.pos = UnityObjectToClipPos (v.vertex);
			o.uv.xy = v.texcoord;		
			o.uv.zw = v.texcoord;
			
			#if UNITY_UV_STARTS_AT_TOP			
			if (_MainTex_TexelSize.y < 0.0)
				o.uv.w = 1.0 - o.uv.w;
			#endif
				        	
			return o; 
        }

        fixed4 fragBloom(v2fBloom i):SV_Target
        {
        	// 将暗度图像和原图相加，暗色部分接近0，叠加后颜色变化小，亮色部分接近1，叠加后颜色变化大
        	// 因此可以实现亮部突出的效果
            return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
        }
        ENDCG

        // 获取较亮区域
        Pass
        {
            CGPROGRAM
            #pragma vertex vertGetBright
            #pragma fragment fragGetBright
            ENDCG
        }
        // 高斯模糊
        UsePass "Custom/GaussianBlur_Copy/GAUSSIAN_BLUR_VERTICAL"
        UsePass "Custom/GaussianBlur_Copy/GAUSSIAN_BLUR_HORIZONTAL"

        // Bloom混合
        Pass
        {
            CGPROGRAM
            #pragma vertex vertBloom
            #pragma fragment fragBloom
            ENDCG
        }
    }
    Fallback Off
}
