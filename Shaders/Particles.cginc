#include "../Libraries/header.cginc"


#ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED

    struct Particle
    {
        uint    Id;
        float3  Position;
        float3  Velocity;
        float   Life;
        float   Age;
    };
    #if defined(SHADER_API_GLCORE) || defined(SHADER_API_D3D11) || defined(SHADER_API_GLES3) || defined(SHADER_API_METAL) || defined(SHADER_API_VULKAN) || defined(SHADER_API_PSSL) || defined(SHADER_API_XBOXONE)

        uniform StructuredBuffer<Particle> _BufferParticle;


    #endif
#endif







void SetupVtx()   // Get data from buffer and store them in private variables // Here it's just a dummy function
{
        return;
}



void GPUInstancing_float(float3 InPos, out float3 OutPos)
{
    OutPos = float3(0, 0, 0);

    #ifdef UNITY_PROCEDURAL_INSTANCING_ENABLED

        Particle pc_attribs = _BufferParticle[unity_InstanceID];


        float3  pos = pc_attribs.Position;
        OutPos = InPos + pos;
    #endif  

}