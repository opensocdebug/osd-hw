package open_soc_debug

import Chisel._

case object MamIODataWidth extends Field[Int]
case object MamIOAddrWidth extends Field[Int]
case object MamIOBeatsBits extends Field[Int]

trait HasMamParameters extends UsesParameters {
  val mamBits = params(MamIODataWidth)
  val mamBytes = mamBits / 8
  val mamAddrBits = params(MamIOAddrWidth)
  val mamBeatsBits = params(MamIOBeatsBits)
  val mamBytesBits = mamBeatsBits + log2Up(mamBytes)
  require(isPow2(mamBits))
}

abstract class MamModule extends Module
  with HasMamParameters
abstract class MamBundle extends Bundle
  with HasMamParameters

class MamReq extends MamBundle {
  val rw = Bool() // 0: Read, 1: Write
  val addr = UInt(width = mamAddrBits)
  val burst = Bool() // 0: single, 1: incremental burst
  val beats = UInt(width = mamBeatsBits)
}

class MamData extends MamBundle {
  val data = UInt(width = mamBits)
}

class MamWData extends MamData {
  val strb = UInt(width = mamBytes)
}

class MamRData extends MamData

class MamIOReqChannel extends Bundle {
  val req = Decoupled(new MamReq)
}

class MamIO extends MamIOReqChannel {
  val wdata = Decoupled(new MamWData)
  val rdata = Decoupled(new MamRData).flip
}
