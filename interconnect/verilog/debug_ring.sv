
module debug_ring
  #(parameter PORTS = 1,
    parameter BUFFER_SIZE = 4)
   (input clk, rst,
    dii_channel dii_in,
    dii_channel dii_out
   );

   /* Router->Module */
   dii_channel out [PORTS-1:0] ();
   /* Module->Router */
   dii_channel in [PORTS-1:0] ();

   genvar i;
   generate
      for (i = 0; i < PORTS; i = i + 1) begin
         assign in[i].data  = dii_in.data[i];
         assign in[i].valid = dii_in.valid[i];
         assign in[i].first = dii_in.first[i];
         assign in[i].last  = dii_in.last[i];
         assign dii_in.ready[i] = in[i].ready;
         assign dii_out.data[i] = out[i].data;
         assign dii_out.valid[i] = out[i].valid;
         assign dii_out.first[i] = out[i].first;
         assign dii_out.last[i] = out[i].last;
         assign out[i].ready = dii_out.ready[i];
      end
   endgenerate

   dii_channel ring_chan0 [PORTS-1:0] ();
   dii_channel ring_chan1 [PORTS-1:0] ();

   dii_channel tie ();
   assign tie.valid = 0;

   /* Drop wrongly addressed packets */
   assign ring_chan1[PORTS-1].ready = 1;
   
   generate
      ring_router
        #(.BUFFER_SIZE(BUFFER_SIZE))
      u_router0(.clk (clk),
                .rst (rst),
                .id  (10'(0)),
                .ring_in0 (tie),
                .ring_in1 (ring_chan0[PORTS-1]),
                .ring_out0 (ring_chan0[0]),
                .ring_out1 (ring_chan1[0]),
                .local_in  (in[0]),
                .local_out (out[0]));
                
      for ( i = 1; i < PORTS; i = i + 1 ) begin
         ring_router
                #(.BUFFER_SIZE(BUFFER_SIZE))
         u_router(.clk       (clk),
                  .rst       (rst),
                  .id        (10'(i)),
                  .ring_in0  (ring_chan0[i-1]),
                  .ring_in1  (ring_chan1[i-1]),
                  .ring_out0 (ring_chan0[i]),
                  .ring_out1 (ring_chan1[i]),
                  .local_in  (in[i]),
                  .local_out (out[i]));
      end
   endgenerate
   
endmodule // Ring
