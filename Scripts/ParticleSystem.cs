using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Collections;

namespace ParticleSolver
{
    public class ParticleSystem : MonoBehaviour
    {
        const int NB_EMIT_THREADS_PER_GROUP = 16;
        const int NB_UPDATE_THREADS_PER_GROUP = 256;


        public struct Particle
        {
            public uint Id;
            public Vector3 Position;
            public Vector3 Velocity;
            public float Life;
            public float Age;
        }

        [SerializeField] private ComputeShader ComputeParticle;

        [SerializeField] private int NumParticleMax = 100000;

        [SerializeField] private Material MaterialInstance;
        [SerializeField] private Mesh InstanceMesh;
        [SerializeField] private int NumEmit = 8;
        [SerializeField] private int IdParticleMax = 65536;
        [SerializeField] private Vector3 Bounds = new Vector3(100f, 100f, 100f);

        [SerializeField] private float EmitFPS = 50.0f; // 50FPS


        private PingPongAppendBuffer _BufferParticle;
        private ComputeShader _Compute;
        private int _KernelIDUpdate = -1;
        private int _KernelIDEmit = -1;
        private int _KernelIDUpdateComputeArgs = -1;


        private int _NumThreadGrpEmit;
        //private int _NumThreadGrpUpdate;

        private Bounds _Bounds;

        private ComputeBuffer _BufferNextId;


        private ComputeBuffer _BufferRenderArgs;// Render args buffer
        private ComputeBuffer _BufferComputeUpdateArgs;// Compute update args buffer

        private uint[] _ArgsRender = new uint[5] { 0, 0, 0, 0, 0 };
        private uint[] _ArgsCompute = new uint[4] { 1, 1, 1, 0 };

        private float _EmitFpsInverse;
        private float _TimeCounter;

        private void InitCompute()
        {

            // Variable initiation
            _EmitFpsInverse = 1.0f / EmitFPS;
            _TimeCounter = 0.0f;



            // next id buffer initiation
            _BufferNextId = new ComputeBuffer(1, Marshal.SizeOf(typeof(uint)));//, ComputeBufferType.Counter);
            var next_id = new uint[0];
            _BufferNextId.SetData(next_id);
            next_id = null;


            // Render args initiation
            _BufferRenderArgs = new ComputeBuffer(1, _ArgsRender.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
            _ArgsRender = new uint[5] { 0, 0, 0, 0, 0 };
            uint num_indices = (InstanceMesh != null) ? (uint)InstanceMesh.GetIndexCount(0) : 0;
            _ArgsRender[0] = num_indices;
            _ArgsRender[1] = 0;// This should be updated with copyCount() 
            _BufferRenderArgs.SetData(_ArgsRender);
            _ArgsRender = null;
            _Bounds = new Bounds(transform.position, Bounds);

            //_BufferRenderArgs.SetCounterValue(0);





            // Compute update args initiation
            _ArgsCompute = new uint[4] { 1, 1, 1, 1 };
            _BufferComputeUpdateArgs = new ComputeBuffer(1, 16, ComputeBufferType.IndirectArguments);
            _BufferComputeUpdateArgs.SetData(_ArgsCompute);
            _ArgsCompute = null;

            //_BufferComputeUpdateArgs.SetCounterValue(0);


            // _BufferParticle initation
            _BufferParticle = new PingPongAppendBuffer(NumParticleMax, typeof(Particle));
            var particle_array = new Particle[NumParticleMax];
            for(int i = 0; i < NumParticleMax; i++)
            {
                particle_array[i].Id = 0;
                particle_array[i].Position = new Vector3(0.0f, 0.0f, 0.0f);
                particle_array[i].Velocity = new Vector3(0.0f, 0.0f, 0.0f);
                particle_array[i].Life = 0;
                particle_array[i].Age = 0;
            }
            _BufferParticle.Previous.SetData(particle_array);
            _BufferParticle.Current.SetData(particle_array);
            particle_array = null;


            _BufferParticle.Current.SetCounterValue(0);
            _BufferParticle.Previous.SetCounterValue(0);

            // kernel id setup

            _Compute = ComputeParticle;

            _KernelIDEmit = _Compute.FindKernel("Emit");
            _KernelIDUpdate = _Compute.FindKernel("Update");
            _KernelIDUpdateComputeArgs = _Compute.FindKernel("UpdateComputeArgs");

            // Compute shader - buffer setup

            _Compute.SetBuffer(_KernelIDEmit, "_BufferParticleCurrent", _BufferParticle.Current);
            _Compute.SetBuffer(_KernelIDEmit, "_BufferRenderArgs", _BufferRenderArgs);

            _Compute.SetBuffer(_KernelIDEmit, "_BufferNextId", _BufferNextId); // Atmoic function으로 조정



            _Compute.SetBuffer(_KernelIDUpdate, "_BufferParticlePrevious", _BufferParticle.Previous);
            _Compute.SetBuffer(_KernelIDUpdate, "_BufferParticleCurrent", _BufferParticle.Current);

            _Compute.SetBuffer(_KernelIDUpdate, "_BufferRenderArgs", _BufferRenderArgs);



            //_Compute.SetBuffer(_KernelIDUpdateComputeArgs, "_BufferParticleCurrent", _BufferParticle.Current);

            _Compute.SetBuffer(_KernelIDUpdateComputeArgs, "_BufferRenderArgs", _BufferRenderArgs);
            _Compute.SetBuffer(_KernelIDUpdateComputeArgs, "_BufferComputeUpdateArgs", _BufferComputeUpdateArgs);

            _Compute.SetInt("_NumParticleMax", NumParticleMax); // Atmoic function으로 조정
            _Compute.SetInt("_IdParticleMax", IdParticleMax); // Atmoic function으로 조정
            //_Compute.SetInt("_NumEmit", NumEmit); // Atmoic function으로 조정


        }


        private void UpdateCompute()
        {
            // 0. previous - current swap  // 5 단계로 하는 방법도 해보자.

            _BufferParticle.Swap();


            // 1. Update를 시작하기 전 Current append buffer 를 초기화 해준다. 
            _BufferParticle.Current.SetCounterValue(0);

            // 2. Update 먼저

            _Compute.SetFloat("_DeltaTime", Time.deltaTime);
            _Compute.SetFloat("_SeedTime", Time.time % 10000);
            _Compute.SetBuffer(_KernelIDUpdate, "_BufferParticlePrevious", _BufferParticle.Previous);
            _Compute.SetBuffer(_KernelIDUpdate, "_BufferParticleCurrent", _BufferParticle.Current);

            //_Compute.SetBuffer(_KernelIDUpdate, "_BufferRenderArgs", _BufferRenderArgs);



            _Compute.DispatchIndirect(_KernelIDUpdate, _BufferComputeUpdateArgs);


            // 3. 그 다음에 Emit


            // TimeCounter를 이용하는 것은 fixedUpdate와 같은 효과를 준다.
            // FPS에 상관 없이 균일하게 emit하기 위해서
            _TimeCounter += Time.deltaTime;

            if (_TimeCounter > _EmitFpsInverse)
            {


                var num_emit = NumEmit;// * Mathf.Floor(_TimeCounter * EmitFPS);



                if (Input.GetMouseButton(0))
                {
                    if (num_emit == 0) _NumThreadGrpEmit = 0;
                    else
                    {


                        _Compute.SetInt("_NumEmit", num_emit);



                        _Compute.SetBuffer(_KernelIDEmit, "_BufferParticleCurrent", _BufferParticle.Current);
                        //_Compute.SetBuffer(_KernelIDEmit, "_BufferRenderArgs", _BufferRenderArgs);



                        _NumThreadGrpEmit = Mathf.FloorToInt((num_emit - 1) / NB_EMIT_THREADS_PER_GROUP) + 1;
                        var pos_click = Camera.main.ScreenToWorldPoint(Input.mousePosition + Vector3.forward * 10);
                        _Compute.SetVector("_ParticleEmitPosition", pos_click);
                        _Compute.Dispatch(_KernelIDEmit, _NumThreadGrpEmit, 1, 1);
                    }
                }

                _TimeCounter -= _EmitFpsInverse;

            }

            // 4. 지금까지 Update에서 업데이트된 append buffer의 개수만큰 _BufferRenderArgs 개수를 업데이트 한다.
            // _BufferRenderArgs는 다음 단계의 compute shader에서 또 사용된다. 
            ComputeBuffer.CopyCount(_BufferParticle.Current, _BufferRenderArgs, 4);






            // 6. Render

            //  이 버퍼 자체가 업데이트 되기 때문에, 이 SetBuffer를 Update에서 해 주어야 하나 보다.
            //  Init에서만 하면 안된다.
            //_BufferRenderArgs.SetCounterValue(0);


            MaterialInstance.SetBuffer("_BufferParticle", _BufferParticle.Current);


            Graphics.DrawMeshInstancedIndirect
            (
                mesh: InstanceMesh,
                submeshIndex: 0,
                material: MaterialInstance,
                bounds: _Bounds,
                bufferWithArgs: _BufferRenderArgs,
                argsOffset: 0,
                properties: null,
                castShadows: UnityEngine.Rendering.ShadowCastingMode.On,
                receiveShadows: true
            //lightProbeUsage: LightProbeUsage.BlendProbe
            );





            // 5. 다음 frame에서 DispatchIndirect()를 실행하기 위한 compute update args buffer를 준비한다. 
            _Compute.Dispatch(_KernelIDUpdateComputeArgs, 1, 1, 1);


        }





        void ReleaseBuffer(ComputeBuffer computeBuffer)
        {
            if (computeBuffer != null)
            {
                computeBuffer.Release();
                computeBuffer = null;
            }
        }


        private void Start()
        {
            InitCompute();
        }

        private void Update()
        {
            UpdateCompute();
        }

        private void OnDestroy()
        {

            ReleaseBuffer(_BufferComputeUpdateArgs);
            ReleaseBuffer(_BufferRenderArgs);
            ReleaseBuffer(_BufferNextId);
            _BufferParticle.Dispose();
        }
    }

}
