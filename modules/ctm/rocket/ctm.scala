package open_soc_debug

import Chisel._

class CoreTrace extends DebugModuleBundle {
  val pc        = UInt(width=sysWordLength)
  val npc       = UInt(width=sysWordLength)
  val jal       = Bool()
  val jalr      = Bool()
  val br        = Bool()
  val load      = Bool()
  val store     = Bool()
  val trap      = Bool()
  val xcpt      = Bool()
  val csr       = Bool()
  val mem       = Bool()
  val taken     = Bool()
  val prv       = UInt(width=2)
  val addr      = UInt(width=sysWordLength)
  val rdata     = UInt(width=sysWordLength)
  val wdata     = UInt(width=sysWordLength)
  val time      = UInt(width=sysWordLength)
}

class CoreTraceIO extends DebugModuleBBoxIO {
  val trace = (new ValidIO(new CoreTrace)).flip
  trace.valid.setName("trace_valid")
  trace.bits.pc.setName("trace_pc")
  trace.bits.npc.setName("trace_npc")
  trace.bits.jal.setName("trace_jal")
  trace.bits.jalr.setName("trace_jalr")
  trace.bits.br.setName("trace_branch")
  trace.bits.load.setName("trace_load")
  trace.bits.store.setName("trace_store")
  trace.bits.trap.setName("trace_trap")
  trace.bits.xcpt.setName("trace_xcpt")
  trace.bits.mem.setName("trace_mem")
  trace.bits.csr.setName("trace_csr")
  trace.bits.taken.setName("trace_br_taken")
  trace.bits.prv.setName("trace_prv")
  trace.bits.addr.setName("trace_addr")
  trace.bits.rdata.setName("trace_rdata")
  trace.bits.wdata.setName("trace_wdata")
  trace.bits.time.setName("trace_time")
}

// black box wrapper
class osd_ctm extends BlackBox with HasDebugModuleParameters {
  val io = new CoreTraceIO

  addClock(Driver.implicitClock)
  renameReset("rst")
}

class RocketCoreTraceIO extends DebugModuleIO {
  val wb_valid = Bool(INPUT)
  val wb_pc = UInt(INPUT, width=sysWordLength)
  val wb_wdata = UInt(INPUT, width=sysWordLength)
  val wb_jal = Bool(INPUT)
  val wb_jalr = Bool(INPUT)
  val wb_br = Bool(INPUT)
  val wb_mem = Bool()
  val wb_mem_cmd = UInt(INPUT, width=memOpSize)
  val wb_xcpt = Bool(INPUT)
  val wb_csr = Bool()
  val wb_csr_cmd = UInt(INPUT, width=csrCmdWidth)
  val wb_csr_addr = UInt(INPUT, width=csrAddrWidth)

  val mem_br_taken = Bool(INPUT)
  val mem_npc = UInt(INPUT, width=sysWordLength)

  val csr_eret = Bool(INPUT)
  val csr_xcpt = Bool(INPUT)
  val csr_prv = UInt(INPUT, width=2)
  val csr_wdata = UInt(INPUT, width=sysWordLength)
  val csr_evec = UInt(INPUT, width=sysWordLength)
  val csr_time = UInt(INPUT, width=sysWordLength)

  val dmem_replay = Bool()
  val dmem_rdata = UInt(INPUT, width=sysWordLength)
  val dmem_wdata = UInt(INPUT, width=sysWordLength)
  val dmem_addr = UInt(INPUT, width=sysWordLength)

}

class RocketCoreTracer(coreid:Int,
  isRead:UInt => Bool,
  isWrite:UInt => Bool,
  isCsrRead:(UInt, UInt) => Bool,
  isCsrWrite:(UInt, UInt) => Bool,
  isCsrTrap:(UInt, UInt) => Bool,
  latch:Boolean = false)
    extends DebugModuleModule(coreid)
{
  val io = new RocketCoreTraceIO

  val tracer = Module(new osd_ctm)
  val trace = tracer.io.trace.bits
  val bbox_port = Module(new DiiPort)
  io.net <> bbox_port.io.chisel
  bbox_port.io.bbox <> tracer.io.net
  tracer.io.id := UInt(baseID + coreid*subIDSize + ctmID)

  def input_latch[T <: Data](in:T):T = if(latch) RegNext(in) else in

  val wb_valid        = input_latch(io.wb_valid)
  val wb_pc           = input_latch(io.wb_pc)
  val wb_wdata        = input_latch(io.wb_wdata)
  val wb_jal          = input_latch(io.wb_jal)
  val wb_jalr         = input_latch(io.wb_jalr)
  val wb_br           = input_latch(io.wb_br)
  val wb_mem          = input_latch(io.wb_mem)
  val wb_mem_cmd      = input_latch(io.wb_mem_cmd)
  val wb_xcpt         = input_latch(io.wb_xcpt)
  val wb_csr          = input_latch(io.wb_csr)
  val wb_csr_cmd      = input_latch(io.wb_csr_cmd)
  val wb_csr_addr     = input_latch(io.wb_csr_addr)
  val wb_br_taken     = RegNext(input_latch(io.mem_br_taken))
  val wb_xcpt_npc     = input_latch(io.csr_evec)
  val wb_br_npc       = RegNext(input_latch(io.mem_npc))

  val csr_eret        = input_latch(io.csr_eret)
  val csr_xcpt        = input_latch(io.csr_xcpt)
  val csr_prv         = input_latch(io.csr_prv)
  val csr_wdata       = input_latch(io.csr_wdata)
  val csr_time        = input_latch(io.csr_time)

  val dmem_replay     = input_latch(io.dmem_replay)
  val dmem_rdata      = input_latch(io.dmem_rdata)
  val dmem_wdata      = input_latch(io.dmem_wdata)
  val dmem_addr       = input_latch(io.dmem_addr)

  when(wb_valid || csr_xcpt || csr_eret) { // an instruction is retired
    tracer.io.trace.valid := wb_valid && (wb_jal || wb_jalr || wb_br || wb_xcpt || wb_mem || wb_csr) || csr_xcpt || csr_reset
    trace.pc := wb_pc
    trace.npc := Mux(wb_xcpt || csr_xcpt || csr_eret, wb_xcpt_npc, wb_br_npc)
    trace.jal := wb_jal
    trace.jalr := wb_jalr
    trace.br := wb_br
    trace.load := wb_mem && isRead(wb_mem_cmd) || wb_csr && isCsrRead(wb_csr_cmd, wb_csr_addr)
    trace.store := wb_mem && isWrite(wb_mem_cmd) || wb_csr && isCsrWrite(wb_csr_cmd, wb_csr_addr)
    trace.trap := csr_xcpt && isCsrTrap(wb_csr_cmd, wb_csr_addr)
    trace.xcpt := wb_xcpt || csr_xcpt && !isTrap(wb_csr_cmd, wb_csr_addr)
    trace.csr := wb_csr
    trace.mem := wb_mem
    trace.taken := wb_br_taken
    trace.prv := csr_prv
    trace.addr := dmem_addr
    trace.rdata := Mux(wb_mem, dmem_rdata, wb_wdata)
    trace.wdata := Mux(wb_mem, dmem_wdata, csr_wdata)
    trace.time := csr_time
  }

  // handle cache miss

}
