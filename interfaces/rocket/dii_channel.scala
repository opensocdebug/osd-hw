
package open_soc_debug

import Chisel._
//import cde.{Parameters, Field}

case object DiiIOWidth extends Field[Int]

//trait HasDiiParameters {
trait HasDiiParameters extends UsesParameters {
  //implicit val p: Parameters
  //val diiWidth = p(DiiIOWidth)
  val diiWidth = params(DiiIOWidth)
}

//abstract class DiiModule(implicit val p: Parameters) extends Module
abstract class DiiModule extends Module
  with HasDiiParameters
//abstract class DiiBundle(implicit val p: Parameters) extends ParameterizedBundle()(p)
abstract class DiiBundle extends Bundle
  with HasDiiParameters

//class DiiFlit(implicit p: Parameters) extends DiiBundle()(p) {
class DiiFlit extends DiiBundle {
  val last = Bool()
  val data = UInt(width = diiWidth)
}

//class DiiIO(implicit val p:Parameters) extends ParameterizedBundle()(p) {
class DiiIO extends Bundle {
  val dii_out = Decoupled(new DiiFlit)
  val dii_in = Decoupled(new DiiFlit).flip
}

class DiiIOBBox extends DiiBundle {
  val dii_in = UInt(INPUT, width=(new DiiFlit).getWidth + 1)
  val dii_in_ready = Bool(OUTPUT)
  val dii_out = UInt(OUTPUT, width=(new DiiFlit).getWidth + 1)
  val dii_out_ready = Bool(INPUT)
}

class DiiBBoxPort extends DiiModule {
  val io = new bundle {
    val bbox = (new DiiIOBBox).flip
    val chisel = (new DiiIO).flip
  }

  val w = (new DiiFlit).getWidth + 1
  io.bbox.dii_in := Cat(io.chisel.dii_in.valid, io.chisel.dii_in.bits.last, io.chisel.dii_in.bits.data)
  io.chisel.dii_in.ready := io.bbox.dii_in_ready
  io.bbox.dii_out_ready := io.chisel.dii_out.ready
  io.chisel.dii_out.valid := io.bbox.dii_out(w-1)
  io.chisel.dii_out.bits.last := io.bbox.dii_out(w-2)
  io.chisel.dii_out.bits.data := io.bbox.dii_out
}


