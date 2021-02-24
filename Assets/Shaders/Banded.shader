Shader "Custom/Banded"
{
    Properties
    {   
        _MainTex("Main Texture", 2D) = "white" {}                     //TEXTURA

        _Albedo("Albedo Color", Color) = (1, 1, 1, 1)                 //COLOR

        _NormalTex("Normal Texture", 2D) = "bump" {}                  //NORAML
        _NormalStrength("Normal Strength", Range(-5.0, 5.0)) = 1.0
         
        _FallOff("Max falloff", Range(0.0, 0.5)) = 0.0                   //WRAP

        [HDR] _RimColor("Rim Color", Color) = (1, 0, 0, 1)              //RIM
        _RimPower("Rim Power", Range(0.0, 8.0)) = 1.0

        _RampTex("Ramp Texture", 2D) = "white" {}                      //RAMP TEX

      
        _SpecularColor("Specular Color", Color) = (1, 1, 1, 1)        //PHONG
        _SpecularPower("Specular Power", Range(1.0, 10.0))= 5.0
        _SpecularGloss("Specular Gloss", Range(1, 5.0))= 1.0
        _GlossSteps("GlossSteps", Range(1, 8)) = 4

        _Steps("Banded Steps", Range(1, 100)) = 20                    //BANDED

    }

    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
        }

         CGPROGRAM 
    
            #pragma surface surf DiffuseWrap

            sampler2D _MainTex;    //TEXTURA
            sampler2D _NormalTex;  //NORMAL
            sampler2D _RampTex;    //RAMP

            half4 _Albedo;    //COLOR

            half _FallOff;    //WRAP

            half4 _SpecularColor;   //PHONG
            half _SpecularPower;
            half _SpecularGloss;
            int _GlossSteps;
        
            float _NormalStrength;    //NORMAL

            half4 _RimColor;     //RIM
            float _RimPower;

            fixed _Steps;       //BANDED



            half4 LightingDiffuseWrap(SurfaceOutput s, half3 lightDir, half3 viewDir, half atten)
            {
                half NdotL = max(0, dot(s.Normal, lightDir));
                half3 reflectedLight = reflect(-lightDir, s.Normal);
                half RdotV = max(0, dot(reflectedLight, viewDir));
                half3 specularity = pow(RdotV, _SpecularGloss / _GlossSteps) * _SpecularPower * _SpecularColor.rgb;
                half diff = NdotL * _FallOff + _FallOff;

                half lightBandsMultiplier = _Steps / 256;
                half lightBandsAdditive = _Steps / 2;
                fixed bandedLightModel = (floor((NdotL * 256  + lightBandsAdditive) / _Steps)) * lightBandsMultiplier;

                float x = NdotL * 0.5 + 0.5;
                float2 uv_RampTex = float2(x, 0);
                half4 rampColor = tex2D(_RampTex, uv_RampTex);

                half4 c;
                c.rgb = (NdotL * s.Albedo +  specularity) * _LightColor0.rgb * atten * diff * bandedLightModel *  rampColor ;
                c.a = s.Alpha;
                return c;
            }

            struct Input
            {
                float a;
                float2 uv_MainTex;         
                float2 uv_NormalTex;
                float3 viewDir;
            };

            void surf(Input IN, inout SurfaceOutput o)
            {
                
                half4 texColor = tex2D(_MainTex, IN.uv_MainTex);
                half4 normalColor = tex2D(_NormalTex, IN.uv_NormalTex);
                half3 normal = UnpackNormal(normalColor);
                normal.z = normal.z / _NormalStrength;
                o.Normal = normalize(normal);
                float3 nVwd= normalize(IN.viewDir);
                float3 NdotV = dot(nVwd, o.Normal);
                half rim = 1 - saturate(NdotV);
                o.Emission = _RimColor.rgb * pow(rim, _RimPower);
                o.Albedo = texColor.rgb * _Albedo;
            }

    ENDCG

    }

}