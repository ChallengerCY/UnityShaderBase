// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//Shader的名字
shader "LearnUnityShader/Chapter7/SingleTexture"
{
    //Shader属性声明
    Properties
    {
        //声明控制物体的整体色调
        _Color("Color Tint",Color)=(1,1,1,1)
        //声明主纹理
        _MainTex("MainTex",2D)="white"{}
        
        _Specular("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",Range(8.0,256))=20
    }
    
    //声明子着色器
    SubShader
    {
        //声明Pass通道
        Pass
        {   
            //为通道声明标签
            Tags
            {   
                //设置Pass在光照流水线中的角色
                "LightMode"="ForwardBase"
            }
            
            //开启CG代码片段
            CGPROGRAM
            
            //声明顶点函数
            #pragma vertex vert
            //声明片元函数
            #pragma fragment frag
            //使用Lighting中的内置变量
            #include "Lighting.cginc"
            //声明对应的_Color变量
            fixed4 _Color;
            //声明对应的主纹理变量
            sampler2D _MainTex;
            //声明纹理的对应属性(缩放和平移) 声明方法为纹理名_ST,其中xy代表缩放，zw代表平移
            float4 _MainTex_ST;
            
            fixed4 _Specular;
            float _Gloss;
            
            //定义顶点着色器的输入输出结构体
            struct a2v
            {
                //声明模型的顶点坐标
                float4 vertex:POSITION;
                //声明模型的法线信息
                float3 normal:NORMAL;
                //声明模型的第一组纹理坐标
                float4 texcoord:TEXCOORD0;
            };          
            //定义片源着色器的输入输出结构体
            struct v2f
            {
                //声明模型的裁剪坐标
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                //声明存储纹理的uv坐标
                float2 uv:TEXCOORD2;
            };
            
            //顶点着色器函数 该函数返回一个v2f类型的变量，需要传入一个a2v类型的变量
            v2f vert(a2v v)
            {
                //定义要返回的片源着色器结构体
                v2f o;
                //计算模型的顶点裁剪坐标
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                //使用_MainTex_ST属性对顶点纹理坐标进行变换，xy代表缩放(缩放需要相乘)，zw代表平移(平移需要相加)
                o.uv=v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
                //or just call the built-in function（调用内置函数）
                //o.uv=TRANSFORM_TEX(v.texcoord,_MainTex)
                return o;
            }
            //定义片元着色器
            fixed4 frag(v2f i):SV_Target
            {
                //计算世界空间下的法线方向
                fixed3 worldNormal=normalize(i.worldNormal);
                //计算世界空间下的光照方向
                fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));
                //使用tex2D进行纹理采样，将采样结果和颜色相乘得到反射率albedo
                fixed3 albedo =tex2D(_MainTex,i.uv).rgb*_Color.rgb;
                //计算环境光部分
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                //计算漫反射
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLightDir));
                fixed3 viewDir=normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir=normalize(worldLightDir*viewDir);
                //计算高光
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
                
                return fixed4(ambient+diffuse+specular,1.0);
            }
            //结束CG代码片段
            ENDCG   
        } 
    }    
    FallBack "Specular"
}

/** 本段代码小结
    在Properties中定义了主纹理和控制物体整体色调的颜色属性。
    2D是纹理属性的声明方式。"white"是内置纹理的名字，代表一张空白的纹理。
    在Subshader中定义了一个Pass通道，并且在该通道中声明了光照模式。
    "LightMode"是Pass标签的一种。用于定义该Pass在光照流水线中的角色。 
    TEXCOORD0 用于存储模型的的第一组纹理坐标
    在片元着色器中声明的uv坐标，用于纹理采样。
    Unity提供了一个内置宏TRANSFORM_TEX来计算纹理的偏移和缩放。
    #define TRANSFORM_TEX(tex,name)(tex.xy*name##_SV+name##SV.zw)
    
    环境光部分的计算为环境光*反射率
*/