
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
