// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/BrightnessSaturationAndContrast_Copy"
{
    Properties
    {
        _MainTex("BaseTexture",2D) = "white"{}
        _Brightness("Brightness",Float) = 1
        _Saturation("Saturation",Float) = 1
        _Contrast("Contrast",Float) = 1
    }
    SubShader
    {
        Pass
        {
            // 该语句是屏幕后处理的标配
            // 因为屏幕画面应当是最前方的，因此深度测试应当总是通过
            // 关闭背面剔除
            // 关闭深度写入以防止它覆盖其他物体渲染
            ZTest Always
            Cull Off
            Zwrite Off
            CGPROGRAM
            #pragma fragment frag
            #pragma vertex vert
            #include "UnityCG.cginc"
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Brightness;
            float _Saturation;
            float _Contrast;

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }
            fixed4 frag(v2f i):SV_Target
            {
                // 亮度 = 颜色 * 亮度值
                fixed4 renderTex = tex2D(_MainTex,i.uv);
                fixed3 finalColor = renderTex.rgb * _Brightness;

                // 在线性颜色空间下的RGB 转为灰度值的心理学公式
                fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                fixed3 luminanceColor = fixed3(luminance,luminance,luminance);
                finalColor = lerp(luminanceColor,finalColor,_Saturation);

                // 对比度颜色值
                fixed3 avgColor = fixed3(0.5,0.5,0.5);
                finalColor = lerp(avgColor,finalColor,_Contrast);

                return fixed4(finalColor,renderTex.a);
            }
            
            ENDCG
            
        }
    }
	Fallback Off
}
