
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
//#pragma exclude_renderers d3d11 gles

float3x3 GetRotationMatrix(float3 axis,float angle)

{
    float2 sincosA;
    sincos(angle, sincosA.x, sincosA.y);
    const float c = sincosA.y;
    const float s = sincosA.x;
    const float t = 1.0 - c;
    const float x = axis.x;
    const float y = axis.y;
    const float z = axis.z;

    return float3x3(t * x * x + c,      t * x * y - s * z,  t * x * z + s * y,
                    t * x * y + s * z,  t * y * y + c,      t * y * z - s * x,
                    t * x * z - s * y,  t * y * z + s * x,  t * z * z + c);

                    /*
    return float3x3(t * x * x + c,      t * x * y + s * z,  t * x * z - s * y,
                    t * x * y - s * z,  t * y * y + c,      t * y * z + s * x,
                    t * x * z + s * y,  t * y * z - s * x,  t * z * z + c);
                    */

    // 나중에 vector와 matrix를 mul() 할 때, mul(vec, matrix) 하려면 아래가 맞고 ,
    // mul(matrix, vec)하려면 위가 맡다 .

}


float4x4 GetRotationMatrix4x4(float3 axis,float angle)
{
    float2 sincosA;
    sincos(angle, sincosA.x, sincosA.y);
    const float c = sincosA.y;
    const float s = sincosA.x;
    const float t = 1.0 - c;
    const float x = axis.x;
    const float y = axis.y;
    const float z = axis.z;


    return float4x4(t * x * x + c,      t * x * y - s * z,  t * x * z + s * y,  0.0,
                    t * x * y + s * z,  t * y * y + c,      t * y * z - s * x,  0.0,
                    t * x * z - s * y,  t * y * z + s * x,  t * z * z + c,      0.0,
                    0.0,                0.0,                0.0,                1.0);


/*
    return float4x4(t * x * x + c,      t * x * y + s * z,  t * x * z - s * y,  0.0,
                    t * x * y - s * z,  t * y * y + c,      t * y * z + s * x,  0.0,
                    t * x * z + s * y,  t * y * z - s * x,  t * z * z + c,      0.0,
                    0.0,                0.0,                0.0,                1.0);

                    */
    // 나중에 vector와 matrix를 mul() 할 때, mul(vec, matrix) 하려면 아래가 맞고 ,
    // mul(matrix, vec)하려면 위가 맡다 .




}

float3x3 EulerAnglesToRotationMatrix(float3 angles)
{
    float ch = cos(angles.y); float sh = sin(angles.y);
    float ca = cos(angles.z); float sa = sin(angles.z);
    float cb = cos(angles.x); float sb = sin(angles.x);
    return float3x3(
        ch * ca + sh * sb * sa,     -ch * sa + sh * sb * ca,    sh * cb,
        cb * sa,                    cb * ca,                    -sb,
        -sh * ca + ch * sb * sa,    sh * sa + ch * sb * ca,     ch * cb);
}

float4x4 EulerAnglesToRotationMatrix4x4(float3 angles)
{
    float ch = cos(angles.y); float sh = sin(angles.y);
    float ca = cos(angles.z); float sa = sin(angles.z);
    float cb = cos(angles.x); float sb = sin(angles.x);
    return float4x4(
        ch * ca + sh * sb * sa,     -ch * sa + sh * sb * ca,    sh * cb,    0.0,
        cb * sa,                    cb * ca,                    -sb,        0.0,
        -sh * ca + ch * sb * sa,    sh * sa + ch * sb * ca,     ch * cb,    0.0,
        0.0,                        0.0,                        0.0,        1.0);
}



float3x3 LookAt(float3 aim, float3 up)
{
    float3 dir_2 = normalize(aim);
    float3 dir_0 = normalize(cross(up, dir_2));
    float3 dir_1 = normalize(cross(dir_2, dir_0));

    return float3x3(
        dir_0.x, dir_1.x, dir_2.x,
        dir_0.y, dir_1.y, dir_2.y,
        dir_0.z, dir_1.z, dir_2.z);
}

float4x4 LookAt4x4(float3 aim, float3 up)
{
    float3 dir_2 = normalize(aim);
    float3 dir_0 = normalize(cross(up, dir_2));
    float3 dir_1 = normalize(cross(dir_2, dir_0));
    return float4x4(
        dir_0.x, dir_1.x, dir_2.x, 0.0,
        dir_0.y, dir_1.y, dir_2.y, 0.0,
        dir_0.z, dir_1.z, dir_2.z, 0.0,
        0.0,     0.0,     0.0,     1.0) ;
}


float4 AimUpToAxisAngle(float3 aim, float3 up)
{
    float3  left = normalize(cross(up, aim));
    float   s = sqrt((aim.y - up.z) * (aim.y - up.z) + (left.z - aim.x) * (left.z - aim.x) + (up.x - left.y) * (up.x - left.y));
            s = abs(s) < .0001 ? 1.0 : s;
    float   s_div = 1.0 / s;
    float   rot_angle = acos(0.5 * (left.x + up.y + aim.z - 1));
    float   rot_axis_x = s_div * (up.z - aim.y);
    float   rot_axis_y = s_div * (aim.x - left.z);
    float   rot_axis_z = s_div * (left.y - up.x);
    return  float4(-rot_axis_x, rot_axis_y, rot_axis_z, rot_angle);  // why put - in front of rot_axis_x ?
                                                                     // --> houdini unity difference
}



float3x3 AimUpToRotationMatrix(float3 aim, float3 up)
{
    float3  left = normalize(cross(up, aim));

    return float3x3(
        left.x,     left.y,     left.z,
        up.x,       up.y,       up.z,
        aim.x,      aim.y,      aim.z);
    /*
    return float3x3(
        left.x,     up.x,     aim.x,
        left.y,     up.y,     aim.y,
        left.z,     up.z,     aim.z);

    */
    // 나중에 vector와 matrix를 mul() 할 때, mul(vec, matrix) 하려면 아래가 맞고 ,
    // mul(matrix, vec)하려면 위가 맡다 .
}







/*
    double s = Math.sqrt((m[2][1] - m[1][2])*(m[2][1] - m[1][2])
        +(m[0][2] - m[2][0])*(m[0][2] - m[2][0])
        +(m[1][0] - m[0][1])*(m[1][0] - m[0][1])); // used to normalise
    if (Math.abs(s) < 0.001) s=1;
        // prevent divide by zero, should not happen if matrix is orthogonal and should be
        // caught by singularity test above, but I've left it in just in case
    angle = Math.acos(( m[0][0] + m[1][1] + m[2][2] - 1)/2);
    x = (m[2][1] - m[1][2])/s;
    y = (m[0][2] - m[2][0])/s;
    z = (m[1][0] - m[0][1])/s;
   return new axisAngle(angle,x,y,z);
   */


float Fit(float input, float minInput, float maxInput, float minOutput, float maxOutput)
{
    return clamp(minOutput + (input - minInput) * (maxOutput - minOutput) / (maxInput - minInput), min(minOutput, maxOutput), max(minOutput, maxOutput));
}



float3x3 Dihedral(float3 ref, float3 target)
{
    float3 a = normalize(ref);
    float3 b = normalize(target);
    float3 axis = normalize(cross(a,b));
    float angle_between = acos(dot(a,b));
    float3x3 mat_I = float3x3(1,0,0,0,1,0,0,0,1);
    float3x3 mat_A = float3x3(0, axis.z, -axis.y, -axis.z, 0, axis.x, axis.y, -axis.x, 0);

    //float3x3 mat_A = float3x3(0, -axis.z, axis.y, axis.z, 0, -axis.x, -axis.y, axis.x, 0);


    float3x3 mat_rot = mat_I + mul(mat_A, sin(angle_between)) + mul(mat_A, mul(mat_A, (1-cos(angle_between))));
    return mat_rot;
}
// Dihedral 이 후디니에서도 완벽하지는 않다.


float3x3 Transpose3x3(float3x3 m){
return float3x3(m[0][0], m[1][0], m[2][0],
                m[0][1], m[1][1], m[2][1],
                m[0][2], m[1][2], m[2][2]);
}





/////////////////////////////
// Random number generator //
/////////////////////////////

#define RAND_24BITS 0

uint VFXMul24(uint a,uint b)
{
#ifndef SHADER_API_PSSL
    return (a & 0xffffff) * (b & 0xffffff); // Tmp to ensure correct inputs
#else
    return mul24(a, b);
#endif
}

uint WangHash(uint seed)
{
    seed = (seed ^ 61) ^ (seed >> 16);
    seed += (seed << 3);
    seed = seed ^ (seed >> 4);
    seed *= 0x27d4eb2d;
    seed = seed ^ (seed >> 15);
    return seed;
}

uint WangHash2(uint seed) // without mul on integers
{
    seed += ~(seed<<15);
    seed ^=  (seed>>10);
    seed +=  (seed<<3);
    seed ^=  (seed>>6);
    seed += ~(seed<<11);
    seed ^=  (seed>>16);
    return seed;
}

// See https://stackoverflow.com/a/12996028
uint AnotherHash(uint seed)
{
#if RAND_24BITS
    seed = VFXMul24((seed >> 16) ^ seed,0x5d9f3b);
    seed = VFXMul24((seed >> 16) ^ seed,0x5d9f3b);
#else
    seed = ((seed >> 16) ^ seed) * 0x45d9f3b;
    seed = ((seed >> 16) ^ seed) * 0x45d9f3b;
#endif
    seed = (seed >> 16) ^ seed;
    return seed;
}

uint Lcg(uint seed)
{
    const uint multiplier = 0x0019660d;
    const uint increment = 0x3c6ef35f;
#if RAND_24BITS && defined(SHADER_API_PSSL)
    return mad24(multiplier, seed, increment);
#else
    return multiplier * seed + increment;
#endif
}

float ToFloat01(uint u)
{
#if !RAND_24BITS
    return asfloat((u >> 9) | 0x3f800000) - 1.0f;
#else //Using mad24 keeping consitency between platform
    return asfloat((u & 0x007fffff) | 0x3f800000) - 1.0f;
#endif
}

//https://www.rapidtables.com/convert/number/hex-to-decimal.html
//hexadecimal --> decimal
//decimal --> hexadecimal
float Rand(inout uint seed)
{
    seed = Lcg(seed);
    return ToFloat01(seed);
}

float FixedRand(uint seed)
{
    return ToFloat01(AnotherHash(seed));
}




float rand3dTo1d(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719)){
    //make value smaller to avoid artefacts
    float3 smallValue = sin(value);
    //get scalar value from 3d vector
    float random = dot(smallValue, dotDir);
    //make value more random by making it bigger and then taking teh factional part
    random = frac(sin(random) * 143758.5453);
    return random;
}

float rand2dTo1d(float2 value, float2 dotDir = float2(12.9898, 78.233)){
    float2 smallValue = sin(value);
    float random = dot(smallValue, dotDir);
    random = frac(sin(random) * 143758.5453);
    return random;
}



float2 rand2dTo2d(float2 value){
    return float2(
        rand2dTo1d(value, float2(12.989, 78.233)),
        rand2dTo1d(value, float2(39.346, 11.135))
    );
}



float3 rand3dTo3d(float3 value){
    return float3(
        rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
        rand3dTo1d(value, float3(39.346, 11.135, 83.155)),
        rand3dTo1d(value, float3(73.156, 52.235, 09.151))
    );
}












///////////////////
// Baked texture //
///////////////////
/*
Texture2D bakedTexture;
SamplerState samplerbakedTexture;

float HalfTexelOffset(float f)
{
    const uint kTextureWidth = 128;
    float a = (kTextureWidth - 1.0f) / kTextureWidth;
    float b = 0.5f / kTextureWidth;
    return (a * f) + b;
}

float4 SampleGradient(float v,float u)
{
    float2 uv = float2(HalfTexelOffset(saturate(u)),v);
    return bakedTexture.SampleLevel(samplerbakedTexture,uv,0);
}

float SampleCurve(float4 curveData,float u)
{
    float uNorm = (u * curveData.x) + curveData.y;
    switch(asuint(curveData.w) >> 2)
    {
        case 1: uNorm = HalfTexelOffset(frac(min(1.0f - 1e-10f,uNorm))); break; // clamp end. Dont clamp at 1 or else the frac will make it 0...
        case 2: uNorm = HalfTexelOffset(frac(max(0.0f,uNorm))); break; // clamp start
        case 3: uNorm = HalfTexelOffset(saturate(uNorm)); break; // clamp both
    }
    return bakedTexture.SampleLevel(samplerbakedTexture,float2(uNorm,curveData.z),0)[asuint(curveData.w) & 0x3];
}
*/







        float2 voronoiNoise2D(float2 value){
            float2 baseCell = floor(value);

            float minDistToCell = 10;
            float2 closestCell;
            [unroll]
            for(int x=-1; x<=1; x++){
                [unroll]
                for(int y=-1; y<=1; y++){
                    float2 cell = baseCell + float2(x, y);
                    float2 cellPosition = cell + rand2dTo2d(cell);
                    float2 toCell = cellPosition - value;
                    float distToCell = length(toCell);
                    if(distToCell < minDistToCell){
                        minDistToCell = distToCell;
                        closestCell = cell;
                    }
                }
            }
            float random = rand2dTo1d(closestCell);
            return float2(minDistToCell, random); // 두 번째 값이 seed다.
        }




        float3 voronoiNoise3D(float3 value){
            float3 baseCell = floor(value);

            float minDistToCell = 10;
            float3 closestCell;
            [unroll]
            for(int x1=-1; x1<=1; x1++){
                [unroll]
                for(int y1=-1; y1<=1; y1++){
                    [unroll]
                    for(int z1=-1; z1<=1; z1++){
                        float3 cell = baseCell + float3(x1, y1, z1);
                        float3 cellPosition = cell + rand3dTo3d(cell);
                        float3 toCell = cellPosition - value;
                        float distToCell = length(toCell);
                        if(distToCell < minDistToCell){
                            minDistToCell = distToCell;
                            closestCell = cell;
                            //toClosestCell = toCell;
                        }
                    }
                }
            }
            float3 random = rand3dTo3d(closestCell);
            return random;
        }

float3 bezier4(float u, float3 pos_array[4]){
    float3  pos = (1-u) * (1-u) * (1-u) * pos_array[0] +
                  3 * u * (1-u) * (1-u) * pos_array[1] +
                  3 * u * u * (1-u) * pos_array[2] +
                  u * u * u * pos_array[3];
    return pos;
}


//http://danceswithcode.net/engineeringnotes/interpolation/interpolation.html

float3 catmullromFront(float u, float3 pos_array[3]){
    float tau = 0.5;
    float3 a2 = tau * (pos_array[0] - 2 * pos_array[1] + pos_array[2]);
    float3 a1 = tau * (-3 * pos_array[0] + 4 * pos_array[1] - pos_array[2]);
    float3 a0 = pos_array[0];
    return a2 * u * u + a1 * u + a0;
}

float3 catmullromMid(float u, float3 pos_array[4]){
    float tau = 0.5;
    float3 a3 = tau * (-pos_array[0] + 3 * pos_array[1] - 3 * pos_array[2] + pos_array[3]);
    float3 a2 = tau * (2 * pos_array[0] - 5 * pos_array[1] + 4 * pos_array[2] - pos_array[3]);
    float3 a1 = tau * (-pos_array[0] + pos_array[2]);
    float3 a0 = tau * pos_array[1];
    return a3 * u * u * u + a2 * u * u + a1 * u + a0;
}

float3 catmullromBack(float u, float3 pos_array[3]){
    float tau = 0.5;
    float3 a2 = tau * (pos_array[0] - 2 * pos_array[1] + pos_array[2]);
    float3 a1 = tau * (-pos_array[0] + pos_array[2]);
    float3 a0 = pos_array[1];
    return a2 * u * u + a1 * u + a0;
}

float2 catmullromFront(float u, float2 pos_array[3]){
    float tau = 0.5;
    float2 a2 = tau * (pos_array[0] - 2 * pos_array[1] + pos_array[2]);
    float2 a1 = tau * (-3 * pos_array[0] + 4 * pos_array[1] - pos_array[2]);
    float2 a0 = pos_array[0];
    return a2 * u * u + a1 * u + a0;
}

float2 catmullromMid(float u, float2 pos_array[4]){
    float tau = 0.5;
    float2 a3 = tau * (-pos_array[0] + 3 * pos_array[1] - 3 * pos_array[2] + pos_array[3]);
    float2 a2 = tau * (2 * pos_array[0] - 5 * pos_array[1] + 4 * pos_array[2] - pos_array[3]);
    float2 a1 = tau * (-pos_array[0] + pos_array[2]);
    float2 a0 = tau * pos_array[1];
    return a3 * u * u * u + a2 * u * u + a1 * u + a0;
}

float2 catmullromBack(float u, float2 pos_array[3]){
    float tau = 0.5;
    float2 a2 = tau * (pos_array[0] - 2 * pos_array[1] + pos_array[2]);
    float2 a1 = tau * (-pos_array[0] + pos_array[2]);
    float2 a0 = pos_array[1];
    return a2 * u * u + a1 * u + a0;
}
