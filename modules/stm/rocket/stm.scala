package open_soc_debug

import Chisel._

class SoftwareTrace extends DebugModuleBundle {
  val id    = UInt(width=16)
  val value = UInt(width=sysWordLength)
}

class SoftwareTraceIO extends DebugModuleBBoxIO {
  val trace = (new ValidIO(new SoftwareTrace)).flip

  trace.valid.setName("trace_valid")
  trace.bits.id.setName("trace_id")
  trace.bits.value.setName("trace_value")
}

// black box wrapper
class osd_stm extends BlackBox with HasDebugModuleParameters {
  val io = new SoftwareTraceIO

  addClock(Driver.implicitClock)
  renameReset("rst")
}

class RocketSoftwareTraceIO extends DebugModuleIO {
  val retire = Bool(INPUT)
  val reg_wdata = UInt(INPUT, width=sysWordLength)
  val reg_waddr = UInt(INPUT, width=regAddrWidth)
  val reg_wen = Bool(INPUT)
  val csr_wdata = UInt(INPUT, width=sysWordLength)
  val csr_waddr = UInt(INPUT, width=csrAddrWidth)
  val csr_wen = Bool(INPUT)
}

class RocketSoftwareTracer(coreid:Int, latch:Boolean = false)(rst:Bool = null) extends DebugModuleModule(coreid)(rst) {
  val io = new RocketSoftwareTraceIO

  val tracer = Module(new osd_stm)
  val bbox_port = Module(new DiiPort)
  io.net <> bbox_port.io.chisel
  bbox_port.io.bbox <> tracer.io.net
  tracer.io.id := UInt(baseID + coreid*subIDSize + stmID)

  def input_latch[T <: Data](in:T):T = if(latch) RegNext(in) else in

  val retire      = input_latch(io.retire)
  val reg_wdata   = input_latch(io.reg_wdata)
  val reg_waddr   = input_latch(io.reg_waddr)
  val reg_wen     = input_latch(io.reg_wen)
  val csr_wdata   = input_latch(io.csr_wdata)
  val csr_waddr   = input_latch(io.csr_waddr)
  val csr_wen     = input_latch(io.csr_wen)

  val user_reg   = RegEnable(reg_wdata,
    retire && reg_wen && reg_waddr === UInt(stmUserRegAddr))

  val thread_change = retire && reg_wen && reg_waddr === UInt(stmThreadPtrAddr)
  val software_trigger = retire && csr_wen && csr_waddr === UInt(stmCsrAddr)
  tracer.io.trace.valid := thread_change || software_trigger
  tracer.io.trace.bits.value := Mux(thread_change, reg_wdata, user_reg)
  tracer.io.trace.bits.id := Mux(thread_change, UInt(0x8000), csr_wdata)
}
