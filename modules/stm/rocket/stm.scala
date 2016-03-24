package open_soc_debug

import Chisel._

class SoftwareTrace extends DebugModuleBundle {
  val id    = UInt(width=16)
  val value = UInt(width=regWidth)
}

class SoftwareTraceIO extends DebugModuleBBoxIO {
  val trace = (new ValidIO(new SoftwareTrace)).flip

  net.dii_in.setName("debug_in")
  net.dii_in_ready.setName("debug_in_ready")
  net.dii_out.setName("debug_out")
  net.dii_out_ready.setName("debug_out_ready")

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
  val reg_wdata = UInt(INPUT, width=regWidth)
  val reg_waddr = UInt(INPUT, width=regAddrWidth)
  val reg_wen = Bool(INPUT)
  val csr_wdata = UInt(INPUT, width=regWidth)
  val csr_waddr = UInt(INPUT, width=csrAddrWidth)
  val csr_wen = Bool(INPUT)
}

class RocketSoftwareTracer(latch:Boolean = false) extends DebugModuleModule {
  val io = new RocketSoftwareTraceIO

  val tracer = Module(new osd_stm)
  val bbox_port = Module(new DiiPort)
  io.net <> bbox_port.io.chisel
  bbox_port.io.bbox <> tracer.io.net
  tracer.io.trace.valid := Bool(false)
  tracer.io.trace.bits.id := UInt(0)
  tracer.io.trace.bits.value := UInt(0)

  def input_latch[T <: Data](in:T):T = if(latch) RegNext(in) else in

  val retire_m    = input_latch(io.retire)
  val reg_wdata_m = input_latch(io.reg_wdata)
  val reg_waddr_m = input_latch(io.reg_waddr)
  val reg_wen_m   = input_latch(io.reg_wen)
  val csr_wdata_m = input_latch(io.csr_wdata)
  val csr_waddr_m = input_latch(io.csr_waddr)
  val csr_wen_m   = input_latch(io.csr_wen)

  val user_reg   = RegEnable(reg_wdata_m,
    retire_m && reg_wen_m && reg_waddr_m === UInt(stmUserRegAddr))
  val thread_ptr = RegEnable(reg_wdata_m,
    retire_m && reg_wen_m && reg_waddr_m === UInt(stmThreadPtrAddr))

  // change of thread pointer
  when(retire_m && reg_wen_m && reg_waddr_m === UInt(stmThreadPtrAddr)) {
    tracer.io.trace.valid := Bool(true)
    tracer.io.trace.bits.value := thread_ptr
    tracer.io.trace.bits.id := UInt(stmCsrAddr)
  }

  // a software trace is triggered
  when(csr_wen_m && csr_waddr_m === UInt(stmCsrAddr)) {
    tracer.io.trace.valid := Bool(true)
    tracer.io.trace.bits.value := user_reg
    tracer.io.trace.bits.id := csr_wdata_m
  }
}
