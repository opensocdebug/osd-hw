
import dii_package::dii_flit;

module debug_ring
  #(parameter PORTS = 1,
    parameter BUFFER_SIZE = 4)
   (input clk, rst,
    input dii_flit [PORTS-1:0] dii_in, output [PORTS-1:0] dii_in_ready,
    output dii_flit [PORTS-1:0] dii_out, input [PORTS-1:0] dii_out_ready
   );

   dii_flit [1:0][1:0] ext_port;
   logic [1:0][1:0]    ext_port_ready;

   debug_ring_expand #(.PORTS(PORTS), .BUFFER_SIZE(BUFFER_SIZE), .ID_BASE(0))
   ring (
         .*,
         .ext_in        ( ext_port[0]       ),
         .ext_in_ready  ( ext_port_ready[0] ),
         .ext_out       ( ext_port[1]       ),
         .ext_out_ready ( ext_port_ready[1] )
         );

   // empty input for chain 0
   assign ext_port[0][0].valid = 1'b0;

   // connect the ends of chain 0 & 1
   assign ext_port[0][1] = ext_port[1][0];
   assign ext_port_ready[1][0] = ext_port_ready[0][1];

   // dump chain 1
   assign ext_port_ready[1][1] = 1'b1;

endmodule // Ring

module debug_ring_expand
  #(parameter PORTS = 1,
    parameter BUFFER_SIZE = 4,
    parameter ID_BASE = 0)
   (input clk, rst,
    input dii_flit [PORTS-1:0] dii_in, output [PORTS-1:0] dii_in_ready,
    output dii_flit [PORTS-1:0] dii_out, input [PORTS-1:0] dii_out_ready,
    input dii_flit [1:0] ext_in, output [1:0] ext_in_ready, // extension input ports
    output dii_flit [1:0] ext_out, input [1:0] ext_out_ready // extension output ports
   );

   genvar i;

   dii_flit [1:0][PORTS:0] chain;
   logic [1:0][PORTS:0] chain_ready;
   
   generate
      for(i=0; i<PORTS; i++) begin
         ring_router
           #(.BUFFER_SIZE(BUFFER_SIZE))
         u_router(
                  .*,
                  .id              ( ID_BASE + i         ),
                  .ring_in0        ( chain[0][i]         ),
                  .ring_in0_ready  ( chain_ready[0][i]   ),
                  .ring_in1        ( chain[1][i]         ),
                  .ring_in1_ready  ( chain_ready[1][i]   ),
                  .ring_out0       ( chain[0][i+1]       ),
                  .ring_out0_ready ( chain_ready[0][i+1] ),
                  .ring_out1       ( chain[1][i+1]       ),
                  .ring_out1_ready ( chain_ready[1][i+1] ),
                  .local_in        ( dii_in[i]           ),
                  .local_in_ready  ( dii_in_ready[i]     ),
                  .local_out       ( dii_out[i]          ),
                  .local_out_ready ( dii_out_ready[i]    )
                  );
      end // for (i=0; i<PORTS, i++)
   endgenerate

   // the expanded ports
   generate
      for(i=0; i<2; i++) begin
         assign chain[i][0] = ext_in[i];
         assign ext_in_ready[i] = chain_ready[i][0];
         assign ext_out[i] = chain[i][PORTS];
         assign chain_ready[i][PORTS] = ext_out_ready[i];
      end
   endgenerate

endmodule
