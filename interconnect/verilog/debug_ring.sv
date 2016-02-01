
import dii_package::dii_flit;

module debug_ring
  #(parameter PORTS = 1,
    parameter BUFFER_SIZE = 4)
   (input clk, rst,
    input dii_flit [PORTS-1:0] dii_in, output [PORTS-1:0] dii_in_ready,
    output dii_flit [PORTS-1:0] dii_out, input [PORTS-1:0] dii_out_ready
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
                  .id              ( i                   ),
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

   // empty input for chain 0
   assign chain[0][0].valid = 1'b0;

   // connect the ends of chain 0 & 1
   assign chain[1][0] = chain[0][PORTS];
   assign chain_ready[0][PORTS] = chain_ready[1][0];

   // dump chain 1
   assign chain_ready[1][PORTS] = 1'b1;

endmodule // Ring
