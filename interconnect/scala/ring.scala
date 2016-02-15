
package open_soc_debug

import Chisel._


/** Ring router
  * Basic element for a ring network
  * 1 local node, 2 expandible ports
  */

class DebugRingRouter(id:Int, buf_len:Int) extends ExpandibleDebugNetwork(1,2) {
  /*
   *       /|--------------buffer-out1
   *  in1 -||
   *       \|---+
   *            |
   *       /|---|-------|\
   *  in0 -||   |       ||-buffer-out0
   *       \|-+ |     +-|/
   *          | |     |
   *          ---     |
   *          \_/     |
   *           |      |
   *         buffer   |
   *           |      |
   *          out    in
   */

  // route function
  def local_id_route(flit: DiiFlit):UInt = {
    if (flit.data(9,0) === UInt(id)) UInt(0)
    else UInt(1)
  }

  val ring0_demux = Module(new DebugNetworkDemultiplexer(2)(local_id_route))
  val ring1_demux = Module(new DebugNetworkDemultiplexer(2)(local_id_route))
  val ring0_mux = Module(new DebugNetworkMultiplexer(2))
  val local_mux = Module(new DebugNetworkMultiplexerRR(2))
  val ring0_buffer = Module(new DebugNetworkBuffer(buf_len))
  val local_buffer = Module(new DebugNetworkBuffer(buf_len))

  io.net(0).dii_in <> ring0_demux.io.ip(0)
  io.net(0).dii_out <> ring0_buffer.io.op(0)
  io.net(1).dii_in <> ring1_demux.io.ip(0)
  io.net(1).dii_out <> ring1_demux.io.op(1)

  io.loc(0).dii_in <> local_buffer.io.op(0)
  io.loc(0).dii_out <> ring0_mux.io.ip(1)

  ring0_demux.io.op(1) <> ring0_mux.io.ip(0)
  ring0_demux.io.op(0) <> local_mux.io.ip(0)
  ring1_demux.io.op(0) <> local_mux.io.ip(1)

  ring0_mux.io.op(0) <> ring0_buffer.io.ip(0)
  local_mux.io.op(0) <> local_buffer.io.ip(0)
}
