package open_soc_debug

import Chisel._
import cde.{Parameters, Field}

case object MamIODataWidth extends Field[Int]
case object MamIOAddrWidth extends Field[Int]
case object MamIOBusrtMax extends Field[Int]

trait HasMamParameters {
  implicit val p: Parameters
  val mamDataWidth = p(MamIODataWidth)
  val mamByteWidth = mamDataWidth / 8
  val mamAddrWidth = p(MamIOAddrWidth)
  val mamBurstSizeWidth = log2Up(p(MamIOBusrtMax))
  val mamBurstByteSizeWidth = log2Up(p(MamIOBusrtMax) * mamByteWidth)
  require(isPow2(mamDataWidth))
}

abstract class MamModule(implicit val p: Parameters) extends Module
  with HasMamParameters
abstract class MamBundle(implicit val p: Parameters) extends ParameterizedBundle()(p)
  with HasMamParameters

class MamReq(implicit p: Parameters) extends MamBundle()(p) {
  val rw = Bool() // 0: Read, 1: Write
  val addr = UInt(width = mamAddrWidth)
  val burst = Bool() // 0: single, 1: incremental burst
  val size = UInt(width = mamBurstSizeWidth)
}

class MamData(implicit p: Parameters) extends MamBundle()(p) {
  val data = UInt(width = mamDataWidth)
}

class MamWData(implicit p: Parameters) extends MamData()(p) {
  val strb = UInt(width = mamByteWidth)
}

class MamRData(implicit p: Parameters) extends MamData()(p)

class MamIOReqChannel (implicit val p:Parameters) extends ParameterizedBundle()(p) {
  val req = Decoupled(new MamReq)
}

class MamIO(implicit val p:Parameters) extends MamIOReqChannel()(p) {
  val wdata = Decoupled(new MamWData)
  val rdata = Decoupled(new MamRData).flip
}
