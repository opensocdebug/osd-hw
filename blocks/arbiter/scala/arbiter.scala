
package open_soc_debug

import Chisel._

/** wormhole arbiter
  * @param T The type of wormhole flit
  * @param A The type of arbiter
  * @param gen Parameter to specify T
  * @param n Number of input ports
  * @param arb Arbiter generation function
  */
abstract class DebugWormholeArbiterLike[T <: DiiFlit, A <: LockingArbiterLike](gen: T, n:Int)(arb: () => A)
    extends Module
{
  val io = new ArbiterIO(gen, n)

  val chosen = Vec(n, Reg(init=Bool(false)))
  val arbiter = new Module(new arb)

  chosen.zipWithIndex.map( (c, i) => {
    c := arbiter.in(i).fire() && !io.in(i).bits.last

    arbiter.in(i).valid := io.in(i).valid || c
    arbiter.in(i).bits := io.in(i).bits
    io.in(i).ready := arbiter.in(i).ready
  })

  io.out.valid := Mux(chosen.orR, (io.in chosen).zipped.map(_||_).reduce(_||_), arbiter.io.out.valid)
  io.out.bits := arbiter.io.out.bits
  arbiter.io.out.ready := io.out.ready
}

/** Static priority arbiter
  */
class DebugWormholeArbiter[T <: DiiFlit](gen: T, n:Int) extends
    DebugWormholeArbiterLike(gen,n)(Arbiter(gen,n,true))

/** Round-robin arbiter
  */
class DebugWormholeArbiter[T <: DiiFlit](gen: T, n:Int) extends
    DebugWormholeArbiterLike(gen,n)(RRArbiter(gen,n,true))

