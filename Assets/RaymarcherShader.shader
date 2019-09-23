Shader "Custom/RaymarcherShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_MaxRayDepth ("Maximum ray depth", int) = 1000
		_Anim ("Anim", float) = 0.1
	}

	SubShader
	{
		Pass
		{
			Cull Off ZWrite Off ZTest Always

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			uniform sampler2D _MainTex;
			uniform float4x4 _FrustumCornersES;
			uniform float4 _MainTex_TexelSize;
			uniform float4x4 _CameraInvViewMatrix;
			uniform float3 _CameraWS;
			uniform float _Anim;
			
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 ray : TEXCOORD1;
			};

			float sdTorus(float3 p, float2 t)
			{
				float2 q = float2(length(p.xz) - t.x, p.y);
				return length(q) - t.y;
			}

			float map( float3 p)
			{
				float scale = 1.0;
				float4 orb = float4(1000.0, 1000.0, 1000.0, 1000.0); 
	
				for( int i=0; i<8;i++ )
				{
					p = -1.0 + 2.0*frac(0.5*p+0.5);

					float r2 = dot(p,p);
					orb = min( orb, float4(abs(p),r2) );
		
					float k = _Anim/r2;
					p     *= k;
					scale *= k;
				}
	
				return 0.25*abs(p.y)/scale;
			}

/*
			float map(float3 p)
			{
				return sdTorus(p, float2(1, 0.2));
			}
			*/
			float3 calcNormal(in float3 pos)
			{
				const float2 eps = float2(0.001, 0.0);
				float3 nor = float3(
					map(pos + eps.xyy).x - map(pos - eps.xyy).x,
					map(pos + eps.yxy).x - map(pos - eps.yxy).x,
					map(pos + eps.yyx).x - map(pos - eps.yyx).x);
				return normalize(nor);
			}

			fixed4 raymarch(float3 ro, float3 rd)
			{
				fixed4 ret = fixed4(0,0,0,0);
				const int maxstep = 64;
				float t = 0;
				for (int i = 0; i < maxstep; i++)
				{
					float3 p = ro + rd * t;
					float d = map(p);

					if (d < 0.0001)
					{
						float3 n = calcNormal(p);
						ret = fixed4(dot(_WorldSpaceLightPos0.xyz, n).rrr,1);
						break;
					}
					t += d;
				}
				return ret;
			}

			v2f vert (appdata v)
			{
				v2f o;
    
				half index = v.vertex.z;
				v.vertex.z = 0.1;
    
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv.xy;
    
				if (_MainTex_TexelSize.y < 0)
					o.uv.y = 1 - o.uv.y;

				o.ray = _FrustumCornersES[(int)index].xyz;
				o.ray /= abs(o.ray.z);
				o.ray = mul(_CameraInvViewMatrix, o.ray);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float3 rd = normalize(i.ray.xyz);    
				float3 ro = _CameraWS;

				fixed3 col = tex2D(_MainTex,i.uv);
				fixed4 add = raymarch(ro, rd);

				return fixed4(col*(1.0 - add.w) + add.xyz * add.w,1.0);
			}
			ENDCG
		}
	}
}