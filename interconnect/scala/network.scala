
package open_soc_debug

import Chisel._

trait HasDebugNetworkParameters extends UseParameters

abstract class DebugNetworkModule extends Module with HasDebugNetworkParameters
abstract class DebugNetworkBundle extends Bundle with HasDebugNetworkParameters

/** Expandible debug network
    Base module for all debug networks
  @param nodes Number of end nodes connected to this network
  @param eps Number of expandible ports (bidirectional) 
  */
class ExpandibleDebugNetwork(nodes:Int, eps:Int) extends DebugNetworkModule {
  val io = new Bundle {
    loc = Vec(nodes, (new DiiIO).flip)
    net = Vec(eps, new DiiIO)
  }
}
