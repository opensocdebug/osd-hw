
package open_soc_debug

import Chisel._

trait HasDebugNetworkParameters extends UseParameters

abstract class DebugNetworkModule extends Module with HasDebugNetworkParameters
abstract class DebugNetworkBundle extends Bundle with HasDebugNetworkParameters

/** Expandible debug network
  * Base module for all debug networks
  * @param nodes Number of end nodes connected to this network
  * @param eps Number of expandible ports (bidirectional) 
  */
class ExpandibleDebugNetwork(nodes:Int, eps:Int) extends DebugNetworkModule {
  val io = new Bundle {
    val loc = Vec(nodes, new DiiIO).flip
    val net = Vec(eps, new DiiIO)
  }
}

/** Link connector base class
  * @param ips Number of input ports
  * @param ops Number of output ports
  */
class DebugNetworkConnector(ips:Int, ops:Int) extends DebugNetworkModule {
  val io = new Bundle {
    val ip = Vec(ips, new DecoupledIO(new DiiFlit)).flip
    val op = Vec(ops, new DecoupledIO(new DiiFlit))
  }
}

/** Multiplexer for debug network (static)
  * @param ips Number of input ports
  */
class DebugNetworkMultiplexer(ips:Int) extends DebugNetworkConnector(ips,1) {
  val arb = Module(new DebugWormholeArbiter(new DiiFlit,ips))
  io.ip <> arb.in
  io.op(0) <> arb.out
}

/** Multiplexer for debug network (round-robin)
  * @param ips Number of input ports
  */
class DebugNetworkMultiplexerRR(ips:Int) extends DebugNetworkConnector(ips,1) {
  val arb = Module(new DebugWormholeRRArbiter(new DiiFlit,ips))
  io.ip <> arb.in
  io.op(0) <> arb.out
}

/** Demultiplexer for debug network
  * @param ops Number of output ports
  */
class DebugNetworkDemultiplexer(ops:Int)(route: DiiFlit => UInt) extends DebugNetworkConnector(1,ops) {
  val selection = route(io.ip(0).bits)
  io.op.zipWithIndex.map ( (o, i) => {
    o.valid := selection === UInt(i)
    o.bits := io.ip(0)
  })
  io.ip(0).ready := io.op(selection).ready
}
