
package open_soc_debug

import Chisel._

/** wormhole arbiter
  * @param T The type of wormhole flit
  * @param A The type of arbiter
  * @param gen Parameter to specify T
  * @param n Number of input ports
  * @param arb Arbiter generation function
  */
abstract class DebugWormholeArbiterLike[T <: DiiFlit](gen: T, n:Int)(arb: LockingArbiterLike[T])
    extends Module
{
  val io = new ArbiterIO(gen, n)

  val chosen = Vec(n, Reg(init=Bool(false)))
  val arbiter = Module(arb)

  chosen.zipWithIndex.foreach{ case (c, i) => {
    c := arbiter.io.in(i).fire() && !io.in(i).bits.last

    arbiter.io.in(i).valid := io.in(i).valid || c
    arbiter.io.in(i).bits := io.in(i).bits
    io.in(i).ready := arbiter.io.in(i).ready
  }}

  io.out.valid := Mux(chosen.toBits.orR,
    (io.in, chosen).zipped.map(_.valid && _).reduce(_||_),
    arbiter.io.out.valid)

  io.out.bits := arbiter.io.out.bits
  arbiter.io.out.ready := io.out.ready
}

/** Static priority arbiter
  */
class DebugWormholeArbiter[T <: DiiFlit](gen: T, n:Int) extends
    DebugWormholeArbiterLike(gen,n)(new Arbiter(gen,n,true))

/** Round-robin arbiter
  */
class DebugWormholeRRArbiter[T <: DiiFlit](gen: T, n:Int) extends
    DebugWormholeArbiterLike(gen,n)(new RRArbiter(gen,n,true))
