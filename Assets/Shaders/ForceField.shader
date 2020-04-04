// author: Marcus Xie
Shader "Custom/ForceField"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Tint Color", Color) = (0,0.3,1,1)
        _Power("Intersection Width", Range(1.0, 10.0)) = 3.0
        _BasicOpacity("Basic Opacity", Range(0.0, 1.0)) = 0.08
        _CollisionPos("Collision Position", Vector) = (1.0, 1.0, 1.0)
        _WaveScale("Wave Scale", Range(0.0, 1.0)) = 0.0
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        LOD 100

        ZWrite Off
        Blend Off // since we have grabpass, we do blending internally

        GrabPass{ "_GrabTexture" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                fixed4 normal: NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD1;
                fixed fresnel : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
            };

            struct mrtOutput
            {
                fixed4 dest0 : SV_Target0;
                fixed dest1 : SV_Target1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;
            fixed4 _Color;
            half _Power;
            fixed _BasicOpacity;
            sampler2D _GrabTexture;
            float4 _GrabTexture_TexelSize;
            float4 _CollisionPos;
            half _WaveScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.screenPos.z);
                fixed3 viewDir = normalize(ObjSpaceViewDir(v.vertex));
                o.fresnel = 1.0 - saturate(dot(viewDir, v.normal));
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            mrtOutput frag (v2f i) : SV_Target
            {
                mrtOutput mrtO;
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv + float2(_Time.x, 0.0));

                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                fixed depth = 1.0 - saturate(LinearEyeDepth(tex2D(_CameraDepthTexture, screenUV).r) - i.screenPos.z);
                // roi indicates where is rim or intersection
                fixed roi = max(depth, i.fresnel);
                fixed alpha = pow(roi * col.g, _Power) + _BasicOpacity;
                // make the edges look like saturating to white, which is to fake a high emittance intensity
                fixed3 srcCol = lerp(_Color.rgb, fixed3(1.0, 1.0, 1.0), roi);

                //Distortion
                float distToCo = distance(i.worldPos, _CollisionPos.xyz); // distance from current fragment to collision point
                // after the wave starts, _WaveScale goes from one to zero
                // zeroToRadius controls the spreading-out of the wave, and I pow it to make the spreading speed faster at first and slower later
                half zeroToRadius = pow(1.0 - _WaveScale, 1.0 / 2.2) * 0.8; // the constant multiplied here can be seen as radius
                // multiply by _WaveScale to make the width of the wave wider at first and narrower later
                half waveWidth = 0.2 * _WaveScale;
                // use two smoothstep to create a single pulse along the direction to the collision point, that is, a prominent circle around the collision point
                float pulseRange = smoothstep(zeroToRadius, zeroToRadius + waveWidth, distToCo) * (1.0 - smoothstep(zeroToRadius + waveWidth, zeroToRadius + 2.0 * waveWidth, distToCo));
                // multiply by sin to make it more like a wave, rather than a single pulse,
                // multiply by _WaveScale to make the distortion less intensive as the wave spreading out 
                float wave = pulseRange * sin(distToCo * 50.0) * 30.0 * _WaveScale;
                fixed3 dstCol = tex2D(_GrabTexture, screenUV + _GrabTexture_TexelSize.xy * wave).rgb;

                //fixed alphaDest0 = alpha + roi * 0.3 + saturate(pulseRange * sine * _WaveScale) * 0.3;// + roi * 0.3 to make a fake bloom on the edges
                fixed alphaDest0 = alpha + roi * 0.3;// + roi * 0.3 to make a fake bloom on the edges
                fixed3 blendedCol = alphaDest0 * (srcCol - dstCol) + dstCol; // equivalent to: alphaDest0 * srcCol + (1.0 - alphaDest0) * dstCol;
                fixed4 fogCol = fixed4(blendedCol.r, blendedCol.g, blendedCol.b, 1.0);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, fogCol);

                //MRT (multiple render texuture, used in my bloom)
                mrtO.dest0 = fogCol;
                mrtO.dest1 = alpha;
                return mrtO;
            }
            ENDCG
        }
    }
}
