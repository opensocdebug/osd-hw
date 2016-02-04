
package open_soc_debug

import Chisel._
import cde.{Parameters, Field}

case object DiiIOWidth extends Field[Int]

trait HasDiiParameters {
  implicit val p: Parameters
  val diiWidth = p(DiiIOWidth)
}

abstract class DiiModule(implicit val p: Parameters) extends Module
  with HasDiiParameters
abstract class DiiBundle(implicit val p: Parameters) extends ParameterizedBundle()(p)
  with HasDiiParameters

class DiiFlit(implicit p: Parameters) extends DiiBundle()(p) {
  val last = Bool()
  val data = UInt(width = diiWidth)
}

class DiiIO(implicit val p:Parameters) extends ParameterizedBundle()(p) {
  val dii_out = Decoupled(new DiiFlit)
  val dii_in = Decoupled(new DiiFlit).flip
}
