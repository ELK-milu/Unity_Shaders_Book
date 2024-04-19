Shader "Custom/MirrowMat_Copy"
{
    Properties
    {
        _MainTex("Main Tex",2D) = "white" {}
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "Queue"="Geometry"}
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            sampler2D _MainTex;

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				// 镜子效果需要x轴翻转
				o.uv.x = 1 - o.uv.x;
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }
    }
    FallBack Off
}
