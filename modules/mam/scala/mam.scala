package open_soc_debug

import Chisel._
//import cde.{Parameters, Field}

case object MamIODataWidth extends Field[Int]
case object MamIOAddrWidth extends Field[Int]
case object MamIOBusrtMax extends Field[Int]

//trait HasMamParameters {
trait HasMamParameters extends UsesParameters {
//  implicit val p: Parameters
//  val mamDataWidth = p(MamIODataWidth)
  val mamDataWidth = params(MamIODataWidth)
  val mamByteWidth = mamDataWidth / 8
//  val mamAddrWidth = p(MamIOAddrWidth)
  val mamAddrWidth = params(MamIOAddrWidth)
//  val mamBurstSizeWidth = log2Up(p(MamIOBusrtMax))
  val mamBurstSizeWidth = log2Up(params(MamIOBusrtMax))
//  val mamBurstByteSizeWidth = log2Up(p(MamIOBusrtMax) * mamByteWidth)
  val mamBurstByteSizeWidth = log2Up(params(MamIOBusrtMax) * mamByteWidth)
  require(isPow2(mamDataWidth))
}

//abstract class MamModule(implicit val p: Parameters) extends Module
abstract class MamModule extends Module
  with HasMamParameters
//abstract class MamBundle(implicit val p: Parameters) extends ParameterizedBundle()(p)
abstract class MamBundle extends Bundle
  with HasMamParameters

//class MamReq(implicit p: Parameters) extends MamBundle()(p) {
class MamReq extends MamBundle {
  val rw = Bool() // 0: Read, 1: Write
  val addr = UInt(width = mamAddrWidth)
  val burst = Bool() // 0: single, 1: incremental burst
  val size = UInt(width = mamBurstSizeWidth)
}

//class MamData(implicit p: Parameters) extends MamBundle()(p) {
class MamData extends MamBundle {
  val data = UInt(width = mamDataWidth)
}

//class MamWData(implicit p: Parameters) extends MamData()(p) {
class MamWData extends MamData {
  val strb = UInt(width = mamByteWidth)
}

//class MamRData(implicit p: Parameters) extends MamData()(p)
class MamRData extends MamData

//class MamIOReqChannel (implicit val p:Parameters) extends ParameterizedBundle()(p) {
class MamIOReqChannel extends Bundle {
  val req = Decoupled(new MamReq)
}

//class MamIO(implicit val p:Parameters) extends MamIOReqChannel()(p) {
class MamIO extends MamIOReqChannel {
  val wdata = Decoupled(new MamWData)
  val rdata = Decoupled(new MamRData).flip
}
