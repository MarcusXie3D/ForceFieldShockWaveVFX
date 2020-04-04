﻿Shader "Custom/ForceFieldBloom"  {
	Properties {
		_MainTex ("Texture", 2D) = "black" {}
        _HalfPixelX ("Half Pixel X", Float) = 0.0
        _HalfPixelY ("Half Pixel Y", Float) = 0.0
        _Color("Tint Color", Color) = (0,0.3,1,1)
        _BloomIntensity("Bloom Intensity", Float) = 2.0
	}

    CGINCLUDE
		#include "UnityCG.cginc"

		sampler2D _MainTex, _SourceTex;
        float _HalfPixelX;
        float _HalfPixelY;
		
		sampler3D _ClutTex;
		half _Scale;
		half _Offset;

        fixed4 _Color;
        float _BloomIntensity;

		struct VertexData {
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct Interpolators {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		Interpolators VertexProgram (VertexData v) {
			Interpolators i;
			i.pos = UnityObjectToClipPos(v.vertex);
			i.uv = v.uv;
			return i;
		}        
	ENDCG

	SubShader {
		Cull Off
		ZTest Always
		ZWrite Off

		Pass { // 0
			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

                fixed Downsample(float2 uv) {
                    float2 UV;
                    fixed sum;

                    sum = tex2D(_MainTex, uv) * 4.0;

                    UV = float2(uv.x - _HalfPixelX, uv.y - _HalfPixelY);
                    sum += tex2D(_MainTex, UV);

                    UV = float2(uv.x + _HalfPixelX, uv.y + _HalfPixelY);
                    sum += tex2D(_MainTex, UV);

                    UV = float2(uv.x + _HalfPixelX, uv.y - _HalfPixelY);
                    sum += tex2D(_MainTex, UV);

                    UV = float2(uv.x - _HalfPixelX, uv.y + _HalfPixelY);
                    sum += tex2D(_MainTex, UV);

                    return sum * 0.125;// sum / 8.0
                }

                fixed FragmentProgram (Interpolators i) : SV_Target {
                    return Downsample(i.uv);
				}
			ENDCG
		}

        Pass { // 1
			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

                fixed Upsample(float2 uv) {
                    float2 UV;
                    fixed sum;

                    UV = float2(uv.x - _HalfPixelX * 2.0, uv.y);
                    sum = tex2D(_MainTex, UV);

                    UV = float2(uv.x - _HalfPixelX,       uv.y + _HalfPixelY);
                    sum += tex2D(_MainTex, UV) * 2.0;

                    UV = float2(uv.x,                     uv.y + _HalfPixelY * 2.0);
                    sum += tex2D(_MainTex, UV);

                    UV = float2(uv.x + _HalfPixelX,       uv.y + _HalfPixelY);
                    sum += tex2D(_MainTex, UV) * 2.0;

                    UV = float2(uv.x + _HalfPixelX * 2.0, uv.y);
                    sum += tex2D(_MainTex, UV);

                    UV = float2(uv.x + _HalfPixelX,       uv.y - _HalfPixelY);
                    sum += tex2D(_MainTex, UV) * 2.0;

                    UV = float2(uv.x,                     uv.y - _HalfPixelY * 2.0);
                    sum += tex2D(_MainTex, UV);

                    UV = float2(uv.x - _HalfPixelX,       uv.y - _HalfPixelY);
                    sum += tex2D(_MainTex, UV) * 2.0;

                    return sum / 12.0;
                }

                fixed FragmentProgram (Interpolators i) : SV_Target {
					return Upsample(i.uv);
				}
			ENDCG
		}

        Pass { // 2
			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

                fixed4 FragmentProgram (Interpolators i) : SV_Target {
					fixed bloom = tex2D(_MainTex, i.uv) * _BloomIntensity;
					fixed3 c = _Color.rgb * bloom;
					c += tex2D(_SourceTex, i.uv).rgb;
					// color grading with LUT
					c = tex3D(_ClutTex, c.rgb * _Scale + _Offset).rgb;
					return fixed4(c, 1.0);
				}
			ENDCG
		}

		Pass { // 3
			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

                fixed4 FragmentProgram (Interpolators i) : SV_Target {
					fixed3 c = tex2D(_MainTex, i.uv).rgb;
					// color grading with LUT
					c = tex3D(_ClutTex, c.rgb * _Scale + _Offset).rgb;
					return fixed4(c, 1.0);
				}
			ENDCG
		}

		Pass { // 4
			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

                fixed4 FragmentProgram (Interpolators i) : SV_Target {
					fixed bloom = tex2D(_MainTex, i.uv) * _BloomIntensity;
					fixed3 c = _Color.rgb * bloom;
					c += tex2D(_SourceTex, i.uv).rgb;
					return fixed4(c, 1.0);
				}
			ENDCG
		}
	}
}