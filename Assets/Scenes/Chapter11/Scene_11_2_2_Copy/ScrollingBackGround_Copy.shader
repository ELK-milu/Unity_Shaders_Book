Shader "Custom/ScrollingBackGround_Copy"
{
    Properties
    {
        _MainTex("Base Layer(RGB)",2D) = "white" {}
        _DetailTex("2nd Layer(RGB)",2D) = "white" {}
        // 控制卷轴不同图层滚动速度
        _ScrollX("Base Layer Scroll Speed",Float) = 1.0
        _Scroll2X("2nd Layer Scroll Speed",Float) = 1.0
        // 控制亮度
        _Multiplier ("Layer Multiplier",Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DetailTex;
            float4 _DetailTex_ST;
            float _ScrollX;
            float _Scroll2X;
            float _Multiplier;

            struct a2v
            {
                float4 vertex:POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
            };
            // 横向运动背景的原理很简单，就是随时间变换采样的U坐标即可
            v2f vert(a2v v)
            {
                v2f o;
                o.pos  = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex) + frac(float2(_ScrollX,0.0) * _Time.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_DetailTex) + frac(float2(_Scroll2X,0.0) * _Time.y);
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                float Time = _Time.y;
                // 若将UV坐标计算部分从顶点着色器放到片元着色器采样纹理时，其作用也是一样的
                // fixed4 firstLayer = tex2D(_MainTex,i.uv.xy + frac(float2(_ScrollX,0.0) * _Time.y));
                fixed4 firstLayer = tex2D(_MainTex,i.uv.xy );
                fixed4 secondLayer = tex2D(_DetailTex,i.uv.zw );
                fixed4 color = lerp(firstLayer,secondLayer,secondLayer.a);
                color.rgb *= _Multiplier;
                return color;
            }
            ENDCG
        }
    }
    Fallback "VertexLit"
}
