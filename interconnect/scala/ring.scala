
package open_soc_debug

import Chisel._


/** Ring router
    Basic element for a ring network
    1 local node, 2 expandible ports
  */

class DebugRingRouter extends ExpandibleDebugNetwork(nodes=1, eps=2)
