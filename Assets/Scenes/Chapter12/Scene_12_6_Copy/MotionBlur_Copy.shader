Shader "Custom/MotionBlur_Copy"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BlurAmount ("BlurAmount", Range(0,1)) = 0.0
    }
    SubShader
    {
        CGINCLUDE
        #include "UnityCG.cginc"
        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        fixed _BlurAmount;
        struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
		};
        v2f vert(appdata_img v)
        {
        	
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord;
        	float tex = tex2D(_MainTex,o.uv);
            return o;
        }
        // 只需把传入的图像的颜色值直接渲染叠加到当前帧即可
        // 第二帧会叠加第一帧的颜色值，第三帧会叠加第二帧的，而第二帧中包含第一帧
        // 假设第一帧叠加到第二帧后透明底0.9，则叠加到第三帧后为0.81，以此类推直到接近0为止第一帧就完全不显示了
        // 因此每次叠加就像递归一样，_BlurAmount越大，运动模糊效果越明显（当然不能为1，否则直接覆盖了）
        fixed4 fragRGB(v2f i):SV_Target
        {
            return fixed4(tex2D(_MainTex,i.uv).rgb,_BlurAmount);
        }
        
        half4 fragA (v2f i) : SV_Target
        {
			return tex2D(_MainTex, i.uv);
		}
        ENDCG
		ZTest Always Cull Off ZWrite Off
		
		Pass {
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask RGB
			
			CGPROGRAM
			
			#pragma vertex vert  
			#pragma fragment fragRGB  
			
			ENDCG
		}
		
		// 处理透明度的Pass，看不出有什么影响
		Pass {   
			Blend One Zero
			ColorMask A
			   	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment fragA
			  
			ENDCG
		}
    }
    Fallback Off
}
