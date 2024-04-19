Shader "Custom/Chapter9/SchlickFresnel"
{
    Properties
    {
        _Color("Color Tint",Color) =(1,1,1,1)
        _FresnelScale ("Fresnel Scale", Range(0, 1)) = 0.5
        _Cubemap("Reflection Cubemap",Cube) = "_Skybox" {}
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            fixed4 _Color;
            fixed _FresnelScale;
            samplerCUBE _Cubemap;

            struct v2f
            {
                float4 pos :SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal :TEXCOORD1;
                float3 worldReflect : TEXCOORD2;
                float3 worldView : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.worldView = UnityWorldSpaceViewDir(o.worldPos);
                o.worldReflect = reflect(-o.worldView,o.worldNormal);
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                fixed3 worldNormalDir = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(i.worldView);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;
                fixed3 reflection = texCUBE(_Cubemap,i.worldReflect).rgb;
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                fixed3 diffuse = _LightColor0.rgb * _Color.rgb * saturate(dot(worldLightDir,worldNormalDir));
                fixed3 fresnel = _FresnelScale + (1-_FresnelScale) * pow((1-dot(worldViewDir,worldNormalDir)),5);
                fixed3 color = ambient + lerp(diffuse,reflection,saturate(fresnel)) * atten;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
Fallback "Specular"
}
