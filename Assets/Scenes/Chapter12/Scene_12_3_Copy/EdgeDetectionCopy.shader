Shader "Custom/EdgeDetectionCopy"
{
    Properties
    {
		_MainTex ("MainTex", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
    	Pass
    	{
    		ZTest Always
    		ZWrite Off
    		Cull Off
    		CGPROGRAM
		    #pragma fragment frag
		    #pragma vertex vert
		    #include "UnityCG.cginc"
		    sampler2D _MainTex;
		    // 小坑，变量名定义需要使用XXX_TexelSize来访问对应纹理的纹素
		    uniform half4 _MainTex_TexelSize;
		    fixed _EdgeOnly;
		    fixed4 _EdgeColor;
		    fixed4 _BackgroundColor;
		    struct v2f
		    {
			    float4 pos : SV_POSITION;
		    	// 该数组用于采样卷积用的像素
				half2 uv[9] : TEXCOORD0;
		    };

    		v2f vert(appdata_img v)
    		{
				v2f o;
    			o.pos = UnityObjectToClipPos(v.vertex);
    			half2 uv = v.texcoord;
    			// 采样卷积中心的周围9个像素点
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);

    			return o;
    		}

		    // 计算对比度
			fixed luminance(fixed4 color)
    		{
    			return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
    		}

		    // 应用Sobel卷积
		    half Sobel(v2f i)
    		{
				const half Gx[9] = {-1,  0,  1,
										-2,  0,  2,
										-1,  0,  1};
				const half Gy[9] = {-1, -2, -1,
										0,  0,  0,
										1,  2,  1};		
				
    			half texColor;
    			half GradientX = 0;
    			half GradientY  = 0;
    			for (int index = 0;index<9;index++)
    			{
    				texColor = luminance(tex2D(_MainTex,i.uv[index]));
    				GradientX += texColor * Gx[index];
    				GradientY += texColor * Gy[index];
    			}
    			half edge = 1-abs(GradientX)-abs(GradientY);

    			return edge;
    		}
		    
		    fixed4 frag(v2f i):SV_Target
    		{
    			// 获取边缘(Sobel返回结果越<1则越边缘)
    			half edge = Sobel(i);

    			//对卷积中心根据卷积值来lerp颜色,edge值越小越接近_EdgeColor,反之越接近原色
    			fixed4 edgeColorMixRigionColor = lerp(_EdgeColor,tex2D(_MainTex,i.uv[4]),edge);
    			fixed4 edgeColorMixCustomBGColor = lerp(_EdgeColor,_BackgroundColor,edge);
    			
    			return lerp(edgeColorMixRigionColor,edgeColorMixCustomBGColor,_EdgeOnly);
    		}
    		ENDCG
		}
    }
	FallBack Off
}
