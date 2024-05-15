Shader "Custom/GaussianBlur_Copy"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _BlurSize ("Blur Size", Float) = 1.0
    }
    SubShader
    {
        CGINCLUDE
        sampler2D _MainTex;
        uniform half4 _MainTex_TexelSize;
        float _BlurSize;
        #include "UnityCG.cginc"
        struct v2f
		{
			float4 pos : SV_POSITION;
			half2 uv[5] : TEXCOORD0;
		};
        fixed4 CaculateGaussionKenel(v2f i)
        {
        	float weight[3] = {0.4026, 0.2442, 0.0545};
        	fixed3 texColor;
        	fixed3 finalColor = 0;
        	for (int index = 0;index <5;index++)
        	{
        		texColor = tex2D(_MainTex, i.uv[index]);
        		finalColor += texColor.rgb * weight[abs(index-2)];
        	}
        	return fixed4(finalColor,1.0);
        }
        fixed4 frag(v2f i):SV_Target
		{
			fixed4 Blur = CaculateGaussionKenel(i);
			return Blur;
		}
        ENDCG

        // vertical
        Pass
        {
        	NAME "GAUSSIAN_BLUR_VERTICAL"
            ZTest Always
            ZWrite Off
            Cull Off
            CGPROGRAM
            #pragma fragment frag
            #pragma vertex vert

            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
            	half2 uv = v.texcoord;
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(0, -2) * _BlurSize;
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1) * _BlurSize;
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(0, 0) * _BlurSize;
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(0, 1) * _BlurSize;
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 2) * _BlurSize;
            	return o;
            }
            ENDCG
        }

        // horizon
        Pass
        {
        	NAME "GAUSSIAN_BLUR_HORIZONTAL"
            ZTest Always
            ZWrite Off
            Cull Off
            CGPROGRAM
            #pragma fragment frag
            #pragma vertex vert
            
            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
            	half2 uv = v.texcoord;
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-2, 0) * _BlurSize;
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(-1, 0) * _BlurSize;
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(0, 0) * _BlurSize;
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(1, 0) * _BlurSize;
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(2, 0) * _BlurSize;
            	return o;
            }
            ENDCG
        }
    }
    FallBack Off
}
