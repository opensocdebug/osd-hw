package open_soc_debug

import Chisel._

case object UseDebug extends Field[Boolean]
case object DebugCtmID extends Field[Int]
case object DebugStmID extends Field[Int]
case object DebugCtmScorBoardSize extends Field[Int]
case object DebugStmCsrAddr extends Field[Int]
case object DebugBaseID extends Field[Int]
case object DebugSubIDSize extends Field[Int]
case object DebugRouterBufferSize extends Field[Int]

trait HasDebugModuleParameters extends UsesParameters {
  val sysWordLength = 64          // system word length
  val regAddrWidth = 5            // 32 user registers
  val csrAddrWidth = 12           // address width of CSRs
  val csrCmdWidth = 3             // size of CSR commends
  val memOpSize = 5               // size of memory operations
  val ctmScoreBoardSize = params(DebugCtmScorBoardSize)
                                  // size of scoreboard in CTM, the same as L1 MISHS
  val stmUserRegAddr = 10         // the address of the user register for software trace
  val stmThreadPtrChgID = 0x8000  // the software trace id for register tracking
  val stmCsrAddr = params(DebugStmCsrAddr)
                                  // the CSR used for software trace
  val ctmID = params(DebugCtmID)  // the debug module ID of the core trace module
  val stmID = params(DebugStmID)  // the debug module ID of the software trace module
  val baseID = params(DebugBaseID)
                                  // the starting ID for rocket cores
  val subIDSize = params(DebugSubIDSize)
                                  // the section size of each core
  val bufSize = params(DebugRouterBufferSize)
                                  // the size of buffer of the ring network
}

abstract class DebugModuleModule(coreid:Int)(rst:Bool = null) extends Module(_reset = rst) with HasDebugModuleParameters
abstract class DebugModuleBundle extends Bundle with HasDebugModuleParameters


class DebugModuleIO extends DebugModuleBundle {
  val net = new DiiIO
}

class DebugModuleBBoxIO extends DebugModuleBundle {
  val net = new DiiBBoxIO
  net.dii_in.setName("debug_in")
  net.dii_in_ready.setName("debug_in_ready")
  net.dii_out.setName("debug_out")
  net.dii_out_ready.setName("debug_out_ready")

  val id = UInt(INPUT, width=10)
  id.setName("id")
}

class RocketDebugNetwork(coreid:Int)(rst:Bool = null) extends DebugModuleModule(coreid)(rst) {
  val io = new Bundle {
    val net = Vec(2, new DiiIO)
    val ctm = (new DiiIO).flip
    val stm = (new DiiIO).flip
  }

  def idAssign: Int => Int = _ match {
    case 0 => baseID + coreid*subIDSize + ctmID
    case 1 => baseID + coreid*subIDSize + stmID
  }

  val network = Module(new ExpandibleRingNetwork(idAssign, 2, bufSize))

  network.io.loc(0) <> io.ctm
  network.io.loc(1) <> io.stm
  network.io.net <> io.net
}
