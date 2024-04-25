Shader "Custom/ImageSequenceAnimation_Copy"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex ("Image Sequence",2D) ="white" {}
        _HorizontalAmount("Horizontal Amount",Float) =4
        _VerticalAmount("Vertical Amount",Float) = 4
        _Speed("Speed",Range(1,100)) = 30
    }
    
    SubShader
    {
        // 由于序列帧图像通常是带有透明通道的，可以视为半透明物体
        // 因此我们对其进行透明度混合渲染
        Tags{"Queue" = "Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "AutoLight.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HorizontalAmount;
            float _VerticalAmount;
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
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                // 总时间 = 经过时间 * 帧率 ，floor取整
                float time = floor(_Time.y * _Speed);
                // 使用Shader实现序列帧动画的本质就是把时间映射到贴图上
                // 这种映射关系要求时间应当是与行列相关的，根据材质来看就应当是逐行地移动到下一张贴图
                // 我们应当整个序列帧图视为n行m列的矩阵，贴图采样随着时间沿着这个矩阵逐行运动
                // 假设当前的行列坐标为(n,m)，则经过的图片数量为 8 * m + n,由此不难得到时间与行列的映射关系:
                // Time = row * _HorizontalAmount + column;
                float row = floor(time / _HorizontalAmount);
                float column = time - row * _HorizontalAmount;
                // 注意由于OpenGL图像原点在左下角，所以移动UV时横向应用加法，纵向应用减法
                half2 uv = i.uv + half2(column, -row);
                // 将矩阵切割，最后采样的UV大小就应当是一个矩阵块的大小
				uv.x /=  _HorizontalAmount;
				uv.y /= _VerticalAmount;

                fixed4 c = tex2D(_MainTex, uv);
				c.rgb *= _Color;
				
				return c;
            }
            
            ENDCG
            
        }
    }
	FallBack "Transparent/VertexLit"
}
