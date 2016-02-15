package open_soc_debug

import Chisel._

/** Generic buffer (Register Queue) for debug network
  * @param width Number of parallel queues
  * @param length Depth of each queue (in unit of flit)
  */
class DebugNetworkBufferLike(width:Int, length:Int) extends
    DebugNetworkConnector(width, width)
{
  io.ip zip io.op map ((i,o) => o <> Queue(i, length))
}

class DebugNetworkBuffer(length:Int) extends DebugNetworkBufferLike(1, length)
