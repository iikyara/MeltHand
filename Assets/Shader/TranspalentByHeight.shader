Shader "Custom/TranspalentByHeight"
{
    Properties
    {
        //_Color("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _TopY("TopY", float) = 0.5
        _TopColor("TopColor", Color) = (1, 1, 1, 1)
        _BottomY("BottomY", float) = -0.5
        _BottomColor("BottomColor", Color) = (0, 0, 0, 1)
    }
    SubShader
    {
        Tags { "RenderType" = "Transparent" }

        Pass{
            Tags { "LightMode" = "ForwardBase" }
            LOD 200

            CGPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma vertex vert_surf
            #pragma fragment frag_surf
            //#pragma surface surf Standard fullforwardshadows

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0

            #pragma multi_compile_fwdbase

            #include "HLSLSupport.cginc"
            #include "UnityShaderVariables.cginc"
            #include "UnityShaderUtilities.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            half _TopY;
            half _BottomY;
            float4 _TopColor;
            float4 _BottomColor;

            half _Glossiness;
            half _Metallic;
            fixed4 _Color;

            struct Input
            {
                float2 uv_MainTex;
            };

            struct v2f_surf {
                UNITY_POSITION(pos);
                float2 pack0 : TEXCOORD0; // _MainTex
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float4 vert_color : TEXCOORD3;
                //float4 vertex : SV_POSITION;
                UNITY_SHADOW_COORDS(5)
            };

            // vertex shader
            v2f_surf vert_surf(appdata_full v) {
                v2f_surf o;
                UNITY_INITIALIZE_OUTPUT(v2f_surf, o);
                o.pos = UnityObjectToClipPos(v.vertex);
                o.pack0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                half t = (v.vertex.y - _BottomY) / (_TopY - _BottomY);
                o.vert_color = lerp(_BottomColor, _TopColor, saturate(t));
                UNITY_TRANSFER_LIGHTING(o, v.texcoord1.xy); // pass shadow and, possibly, light cookie coordinates to pixel shader
                return o;
            }

            //surface shader
            void surf(Input IN, inout SurfaceOutputStandard o) {
                // Albedo comes from a texture tinted by color
                fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
                //o.Albedo = c.rgb;
                // Metallic and smoothness come from slider variables
                o.Metallic = _Metallic;
                o.Smoothness = _Glossiness;
                //o.Alpha = c.a;
            }

            // fragment shader
            fixed4 frag_surf(v2f_surf IN) : SV_Target{
                //surf
                SurfaceOutputStandard o;
                UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o);
                Input input;
                input.uv_MainTex = IN.pack0;
                fixed col = tex2D(_MainTex, IN.pack0);
                float4 col_t = col * IN.vert_color;
                o.Albedo = col_t;
                o.Alpha = col_t.a;
                o.Emission = 0.0;
                o.Occlusion = 1.0;
                o.Normal = IN.worldNormal;

                surf(input,o);

                float3 worldPos = IN.worldPos;
               #ifndef USING_DIRECTIONAL_LIGHT
                  fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
               #else
                  fixed3 lightDir = _WorldSpaceLightPos0.xyz;
               #endif
                float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                UNITY_LIGHT_ATTENUATION(atten, IN, worldPos)
                fixed4 c = 0;

                UnityGI gi;
                UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
                gi.light.color = _LightColor0.rgb;
                //gi.light.color = (1, 0, 0, 1);
                gi.light.dir = lightDir;

                UnityGIInput giInput;
                UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
                giInput.light = gi.light;
                giInput.worldPos = worldPos;
                giInput.worldViewDir = worldViewDir;
                giInput.atten = atten;

                giInput.probeHDR[0] = unity_SpecCube0_HDR;
                giInput.probeHDR[1] = unity_SpecCube1_HDR;
               #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION)
                    giInput.boxMin[0] = unity_SpecCube0_BoxMin; // .w holds lerp value for blending
               #endif
                LightingStandard_GI(o, giInput, gi);
                c += LightingStandard(o, worldViewDir, gi);
                return c;
            }
        ENDCG
        }
    }
    FallBack "Diffuse"
}
