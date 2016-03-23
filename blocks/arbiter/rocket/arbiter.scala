
package open_soc_debug

import Chisel._

/** wormhole arbiter
  * @param T The type of wormhole flit
  * @param A The type of arbiter
  * @param gen Parameter to specify T
  * @param n Number of input ports
  * @param arb Arbiter generation function
  */
abstract class DebugWormholeArbiterLike[T <: DiiFlit](gen: T, n:Int)
    extends Module
{
  val io = new ArbiterIO(gen, n)

  val chosen = Reg(Vec(n, Bool()))
  val arb_in  = Wire(Vec(n,  Decoupled(gen)))
  val arb_out = Wire(Decoupled(gen))

  chosen.zipWithIndex.foreach{ case (c, i) => {
    c := arb_in(i).fire() && !io.in(i).bits.last

    arb_in(i).valid := io.in(i).valid || c
    arb_in(i).bits := io.in(i).bits
    io.in(i).ready := arb_in(i).ready
  }}

  io.out.valid := Mux(chosen.toBits.orR,
    (io.in, chosen).zipped.map(_.valid && _).reduce(_||_),
    arb_out.valid)

  io.out.bits := arb_out.bits
  arb_out.ready := io.out.ready

  def connect(arb: ArbiterIO[T]) = {
    (0 until n).foreach ( i => {
      arb.in(i).valid := arb_in(i).valid
      arb.in(i).bits := arb_in(i).bits
      arb_in(i).ready := arb.in(i).ready
    })
    arb_out.valid := arb.out.valid
    arb_out.bits := arb.out.bits
    arb.out.ready := arb_out.ready
  }
}

/** Static priority arbiter
  */
class DebugWormholeArbiter[T <: DiiFlit](gen: T, n:Int) extends
    DebugWormholeArbiterLike(gen,n)
{
  val arbiter = Module(new Arbiter(gen,n,true))
  connect(arbiter.io)
}

/** Round-robin arbiter
  */
class DebugWormholeRRArbiter[T <: DiiFlit](gen: T, n:Int) extends
    DebugWormholeArbiterLike(gen,n)
{
  val arbiter = Module(new RRArbiter(gen,n,true))
  connect(arbiter.io)
}
