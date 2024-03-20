Shader "Custom/MaskTexture_Shader_Copy"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white" {} 
        _BumpMap("Normal Map",2D) = "bump" {}
        _BumpScale("BumpSclae",Float) = 10.0
        _SpecularMask("Specular Mask",2D) = "white" {}
        _Specular("Specular",Color) = (1,1,1,1)
        _SpecularScale("Specular Scale",Float) = 10.0
        _Gloss("Gloss",Range(8.0,255)) = 20
    }
    SubShader
    {
        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float _BumpScale;
            sampler2D _SpecularMask;
            fixed4 _Specular;
            float _SpecularScale;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = _MainTex_ST.xy * v.texcoord.xy + _MainTex_ST.zw;

                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;
                return o;
            }

            fixed4 frag(v2f i):SV_Target{
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                float4 packedNormal = tex2D(_BumpMap,i.uv.xy);
                
                float3 tangentNormalDir = UnpackNormal(packedNormal);
                tangentNormalDir.xy *= _BumpScale;
                tangentNormalDir.z = sqrt(1.0 -  dot(tangentNormalDir.xy,tangentNormalDir.xy));

                float3 albedo = _Color.rgb * tex2D(_MainTex,i.uv.xy);
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo.rgb;
                float3 halfLambert = normalize(tangentLightDir + tangentViewDir);

                fixed specularMask = tex2D(_SpecularMask,i.uv.xy).r * _SpecularScale;
                
                float3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(tangentNormalDir,tangentLightDir));
                float3 specualr = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfLambert,tangentNormalDir)),_Gloss) * specularMask;
                return fixed4(specualr + diffuse + ambient ,1.0);
            }
            
            ENDCG
        }
    }
    Fallback "Specular"
}
