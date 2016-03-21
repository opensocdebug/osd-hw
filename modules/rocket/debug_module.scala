package open_soc_debug

import Chisel._

case object DebugCtmID extends Field[Int]
case object DebugStmID extends Field[Int]

trait HasDebugModuleParameters extends UsesParameters {
  val regWidth = 64               // system word length
  val regAddrWidth = 5            // 32 user registers
  val csrAddrWidth = 12           // address width of CSRs
  val stmUserRegAddr = 10         // the address of the user register for software trace
  val stmThreadPtrAddr = 4        // the address of the thread pointer for software trace
  val stmThreadPtrChgID = 0       // the software trace id when thread pointer changed
  val stmCsrAddr = 0              // the CSR used for software trace
  val ctmID = params(DebugCtmID)  // the debug module ID of the core trace module
  val stmID = params(DebugStmID)  // the debug module ID of the software trace module
}

abstract class DebugModuleModule extends Module with HasDebugModuleParameters
abstract class DebugModuleBundle extends Bundle with HasDebugModuleParameters


class DebugModuleIO extends DebugModuleBundle {
  val net = new DiiIOBBox
}
