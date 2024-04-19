Shader "Custom/GlassRefraction_Copy"
{
    Properties
    {
        _MainTex("Main Tex",2D) = "white"{}
        _BumpMap("Normal Tex",2D) = "bump"{}
        _Cubemap("Cube Map",Cube) = "_Skybox" {}
        _Distortion("Distortion",Range(0,100)) =10
        _RefractAmount("Refraction Amount",Range(0,1)) =1
    }
    
    SubShader
    {
        Tags{"Queue" = "Transparent" "RenderType"="Opaque"}
        GrabPass { "_RefractionTex" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            samplerCUBE _Cubemap;
            float _Distortion;
            fixed _RefractAmount;
            sampler2D _RefractionTex;
            float4 _RefractionTex_TexelSize;
            
            struct a2v
            {
                float4 vertex :POSITION;
                float3 normal :NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 scrPos : TEXCOORD0;
                float4 TtoW0:TEXCOORD1;
                float4 TtoW1:TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                float4 uv : TEXCOORD4;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.pos);
                o.uv.xy = TRANSFORM_TEX(v.texcoord , _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent);
                float3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;
                
                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                
                fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                float2 RefractOffset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
                bump = normalize(half3(dot(i.TtoW0.xyz ,bump),dot(i.TtoW1.xyz ,bump),dot(i.TtoW2.xyz ,bump)));

                i.scrPos.xy = RefractOffset * max(0.5,(1-i.scrPos.z)) + i.scrPos.xy;
                fixed3 RefractColor = tex2D(_RefractionTex,i.scrPos.xy/i.scrPos.w ).rgb;


                fixed3 ReflectDir = reflect(-worldViewDir,bump);
                fixed4 TexColor = tex2D(_MainTex,i.uv.xy);
                fixed3 ReflectColor = texCUBE(_Cubemap,ReflectDir).rgb * TexColor.rgb;
                fixed3 Color = ReflectColor * (1-_RefractAmount) + RefractColor * _RefractAmount;
                return fixed4(Color,1);
            }
            ENDCG
        }
    }
Fallback "Diffuse"
}
