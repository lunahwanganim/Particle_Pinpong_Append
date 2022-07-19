using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

using UnityEngine;

namespace ParticleSolver
{

    public class PingPongBuffer : System.IDisposable {

        #region Accessors

        public ComputeBuffer Previous { get { return buffers[previous]; } }
        public ComputeBuffer Current { get { return buffers[current]; } }

        #endregion

        private int previous = 0, current = 1;
        protected ComputeBuffer[] buffers;

        public PingPongBuffer(int count, System.Type type)
        {
            buffers = new ComputeBuffer[2];
            buffers[0] = new ComputeBuffer(count, Marshal.SizeOf(type), ComputeBufferType.Default);
            buffers[1] = new ComputeBuffer(count, Marshal.SizeOf(type), ComputeBufferType.Default);
        }

        public void Swap()
        {
            int tmp = previous;
            previous = current;
            current = tmp;
        }

        public void Dispose()
        {
            buffers[0].Dispose();
            buffers[1].Dispose();
        }

    }

}


