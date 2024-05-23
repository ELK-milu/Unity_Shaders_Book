Shader "Custom/ToonShading_Copy"
{
    Properties
    {
        _Color("Tint Color",Color) = (1,1,1,1)
        _MainTex("Map Tex",2D)="white"{}
        _RampTex("Ramp Tex",2D) = "grey"{}
        _Outline("Outline",Range(0,1)) = 0.1
        _OutlineColor("Outline Color",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _SpecularScale("Specular Scale",Float) =1.0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "Queue"="Geometry"
        }
        CGINCLUDE
        #include "UnityCG.cginc"
        fixed4 _Color, _OutlineColor, _Specular;
        fixed _Outline;
        float _SpecularScale;
        sampler2D _MainTex, _RampTex;
        half4 _MainTex_ST;
        ENDCG
        // 背面渲染一次并根据法线方向挤出顶点
        Pass
        {
            Name "OUTLINE"
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                // 此处直接按照法线方向挤出顶点，描边效果稍微不同
                v.vertex.xyz += v.normal * _Outline;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag(v2f i):SV_Target
            {
                return fixed4(_OutlineColor.rgb, 1);
            }
            ENDCG
        }
        // 正面渲染
        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }
            Cull Back
            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct v2f
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            v2f vert(appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) :SV_Target
            {
                fixed3 worldNormalDir = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                fixed4 c = tex2D(_MainTex, i.uv);
                fixed3 albedo = c.rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // 计算与阴影方向，并从标准坐标系[-1,1]映射到[0,1]以采样渐变纹理
                fixed diff = dot(worldNormalDir, worldLightDir);
                diff = (diff * 0.5 + 0.5) * atten;
                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_RampTex, float2(diff, diff)).rgb;
                // 计算高光方向
                fixed spec = dot(worldNormalDir, worldHalfDir);
                //fwidth(v) = abs(ddx(v))+ abs(ddy(v)) 以2x2像素为单位，ddx为右边界-左边界，ddy为下边界-上边界
                // fwidth的返回值表明UV值在该点和临近像素之间的变化，这个值帮助我们判断模糊的大小范围
                // 总之是用于smoothstep对像素进行模糊的
                fixed w = fwidth(spec) * 2.0;
                // smoothstep柔和过渡避免锯齿
                fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(
                    0.0001, _SpecularScale);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG

        }
    }
    FallBack "Diffuse"

}