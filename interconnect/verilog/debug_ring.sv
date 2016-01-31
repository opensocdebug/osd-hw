
module debug_ring
  #(parameter PORTS = 1,
    parameter BUFFER_SIZE = 4)
   (input clk, rst,
    dii_channel dii_in,
    dii_channel dii_out
   );

   genvar i;

   logic [1:0][PORTS:0][15:0] chain_data;
   logic [1:0][PORTS:0]       chain_ready, chain_valid, chain_last;

   generate
      for(i=0; i<PORTS; i++) begin
         // local router channels
         dii_channel ring_in0(), ring_in1(), ring_out0(), ring_out1(), local_in(), local_out();

         // connect router channels
         assign ring_in0.valid = chain_valid[0][i];
         assign ring_in0.last = chain_last[0][i];
         assign ring_in0.data = chain_data[0][i];
         assign chain_ready[0][i] = ring_in0.ready;

         assign ring_in1.valid = chain_valid[1][i];
         assign ring_in1.last = chain_last[1][i];
         assign ring_in1.data = chain_data[1][i];
         assign chain_ready[1][i] = ring_in1.ready;
         
         assign chain_valid[0][i+1] = ring_out0.valid;
         assign chain_last[0][i+1] = ring_out0.last;
         assign chain_data[0][i+1] = ring_out0.data;
         assign ring_out0.ready = chain_ready[0][i+1];

         assign chain_valid[1][i+1] = ring_out1.valid;
         assign chain_last[1][i+1] = ring_out1.last;
         assign chain_data[1][i+1] = ring_out1.data;
         assign ring_out1.ready = chain_ready[1][i+1];

         assign local_in.valid = dii_in.valid[i];
         assign local_in.last = dii_in.last[i];
         assign local_in.data = dii_in.data[i];
         assign dii_in.ready[i] = local_in.ready;
         
         assign dii_out.valid[i] = local_out.valid;
         assign dii_out.last[i] = local_out.last;
         assign dii_out.data[i] = local_out.data;
         assign local_out.ready = dii_out.ready[i];

         // local router instances
         ring_router
           #(.BUFFER_SIZE(BUFFER_SIZE))
         u_router(
                  .*,
                  .id        ( i         ),
                  .ring_in0  ( ring_in0  ),
                  .ring_in1  ( ring_in1  ),
                  .ring_out0 ( ring_out0 ),
                  .ring_out1 ( ring_out1 ),                  
                  .local_in  ( local_in  ),
                  .local_out ( local_out )
                  );
      end // for (i=0; i<PORTS, i++)
   endgenerate

   // special connections
   // empty input for chain 0
   assign chain_valid[0][0] = 1'b0;

   // connect the ends of chain 0 & 1
   assign chain_valid[1][0] = chain_valid[0][PORTS];
   assign chain_last[1][0] = chain_last[0][PORTS];
   assign chain_data[1][0] = chain_data[0][PORTS];
   assign chain_ready[0][PORTS] = chain_ready[1][0];

   // dump chain 1
   assign chain_ready[1][PORTS] = 1'b1;

endmodule // Ring
