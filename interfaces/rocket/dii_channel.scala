
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

class DiiBBoxIO extends DiiBundle {
  val dii_in = UInt(INPUT, width=(new DiiFlit).getWidth + 1)
  val dii_in_ready = Bool(OUTPUT)
  val dii_out = UInt(OUTPUT, width=(new DiiFlit).getWidth + 1)
  val dii_out_ready = Bool(INPUT)
}

class DiiBBoxPort extends DiiModule {
  val io = new bundle {
    val bbox = (new DiiBBoxIO)
    val chisel = (new DiiIO).flip
  }

  io.bbox.dii_out := Cat(io.chisel.dii_out.valid, io.chisel.dii_out.bits)
  io.chisel.dii_out.ready := io.bbox.dii_out_ready

  val w = (new DiiFlit).getWidth
  io.chisel.dii_in.valid := io.bbox.dii_in(w)
  io.chisel.dii_in.bits := io.bbox.dii_in
  io.bbox.dii_in_ready := io.chisel.dii_in.ready
}

class DiiPort extends DiiModule {
  val io = new bundle {
    val chisel = (new DiiIO)
    val bbox = (new DiiBBoxIO).flip
  }

  io.bbox.dii_in := Cat(io.chisel.dii_in.valid, io.chisel.dii_in.bits)
  io.chisel.dii_in.ready := io.bbox.dii_in_ready

  val w = (new DiiFlit).getWidth
  io.chisel.dii_out.valid := io.bbox.dii_out(w)
  io.chisel.dii_out.bits := io.bbox.dii_out
  io.bbox.dii_out_ready := io.chisel.dii_out.ready
}


