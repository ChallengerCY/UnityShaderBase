// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "LearnUnityShader/Chapter7/NormalMapTangentSpace"
{
    //着色器属性
    Properties
    {
        //声明主颜色
        _Color ("Color Tint", Color) = (1,1,1,1)
        //声明主纹理
        _MainTex ("Main Tex", 2D) = "white" {}
        //声明法线纹理图片
        _BumpMap("Normal Map",2D)="bump"{}
        //声明控制凹凸程度，为0时意味着法线纹理不会对光照产生任何影响
        _BumpScale("Bump Scale",Float)=1.0 
        _Specular("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",Range(8.0,256))=20
    } 
    //子着色器
    SubShader
    {
        //声明Pass通道
        Pass
        {   //为通道声明标签
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
            //声明法线纹理图片
            sampler2D _BumpMap;
            //声明法线纹理属性
            float4 _BumpMap_ST;
            //声明凹凸程度
            float _BumpScale;
            
            fixed4 _Specular;
            float _Gloss;
            
            //声明顶点着色器函数
            struct a2v
            {
                //声明模型的顶点
                float4 vertex:POSITION;
                //声明模型的法线
                float3 normal:NORMAL;
                //声明模型的切线
                float4 tangent:TANGENT;
                //声明模型的第一组纹理坐标
                float4 texcoord:TEXCOORD0;
            };
            
            //声明片元着色器函数            
            struct v2f
            {
                //声明模型的裁剪坐标
                float4 pos:SV_POSITION;
                //声明存储纹理的uv坐标
                float4 uv:TEXCOORD0;
                //声明切线空间下的光照方向
                float3 LightDir:TEXCOORD1;
                //声明切线空间下的视角方向
                float3 viewDir:TEXCOORD2;
            };
            
            //顶点着色器函数 该函数返回一个v2f类型的变量，需要传入一个a2v类型的变量
            v2f vert(a2v v)
            {
                v2f o;
                //计算模型的裁剪坐标
                o.pos=UnityObjectToClipPos(v.vertex);
                //将主纹理坐标存储到uv的xy变量中
                o.uv.xy=v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
                //将法线坐标存储到uv的zw变量中
                o.uv.zw=v.texcoord.xy*_BumpMap_ST.xy+_BumpMap_ST.zw;
                //使用Unity内置宏定义计算模型空间下切线方向，副切线方向，和法线方向按行排列来得到从模型空间转到切线空间的变换矩阵rotation
                TANGENT_SPACE_ROTATION;
                //先得到模型空间下的光照方向，再用矩阵将方向转换到切线空间下面
                o.LightDir=mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                //先得到模型空间下的视觉方向，再用矩阵将方向转换到切线空间下面
                o.viewDir=mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;
                return o;
            }
            
            //片元函数着色器函数 需要传入一个 v2f类型的变量
            fixed4 frag(v2f i):SV_Target
            {
                //归一化切线空间下光照方向
                fixed3 tangentLightDir=normalize(i.LightDir);
                //归一化切线空间下视觉方向
                fixed3 tangentViewDir=normalize(i.viewDir);
                //对法线纹理进行采样
                fixed4 packedNormal=tex2D(_BumpMap,i.uv.zw);
                //计算法线的z分量
                fixed3 tangentNormal;
                tangentNormal=UnpackNormal(packedNormal);
                tangentNormal.xy*=_BumpScale;
                tangentNormal.z=sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));
                
                fixed3 albedo=tex2D(_MainTex,i.uv).rgb*_Color.rgb;
                fixed3 ambinent=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(tangentNormal,tangentLightDir));
                
                fixed3 halfDir=normalize(tangentLightDir+tangentViewDir);
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(tangentNormal,halfDir)),_Gloss);
                
                return fixed4(ambinent+diffuse+specular,1.0);
            }
            
            ENDCG
        }
       
    }
    FallBack "Specular"
}

/* 本段代码小结

*/
