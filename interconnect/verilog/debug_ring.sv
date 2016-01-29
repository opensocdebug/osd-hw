
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
         assign in[i].last  = dii_in.last[i];
         assign dii_in.ready[i] = in[i].ready;
         assign dii_out.data[i] = out[i].data;
         assign dii_out.valid[i] = out[i].valid;
         assign dii_out.last[i] = out[i].last;
         assign out[i].ready = dii_out.ready[i];
      end
   endgenerate

   logic [PORTS-1:0][17:0] ring_chan0_down;
   logic [PORTS-1:0]       ring_chan0_up;
   logic [PORTS-1:0][17:0] ring_chan1_down;
   logic [PORTS-1:0]       ring_chan1_up;

   /* Drop wrongly addressed packets */
   assign ring_chan1_up[PORTS-1] = 1;
   
   generate
      ring_router
        #(.BUFFER_SIZE(BUFFER_SIZE))
      u_router0(.clk (clk),
                .rst (rst),
                .id  (10'(0)),
                .ring_in0_down ({1'b0, 17'bx}),
                .ring_in0_up   (),
                .ring_in1_down (ring_chan0_down[PORTS-1][17:0]),
                .ring_in1_up   (ring_chan0_up[PORTS-1]),
                .ring_out0_down (ring_chan0_down[0]),
                .ring_out0_up   (ring_chan0_up[0]),
                .ring_out1_down (ring_chan1_down[0]),
                .ring_out1_up   (ring_chan1_up[0]),
                .local_in_down ({in[0].valid, in[0].last, in[0].data}),
                .local_in_up   (in[0].ready),
                .local_out_down ({out[0].valid, out[0].last, out[0].data}),
                .local_out_up (out[0].ready));
                
      for ( i = 1; i < PORTS; i = i + 1 ) begin
         ring_router
                #(.BUFFER_SIZE(BUFFER_SIZE))
         u_router(.clk       (clk),
                  .rst       (rst),
                  .id        (10'(i)),
                  .ring_in0_down (ring_chan0_down[i-1]),
                  .ring_in0_up   (ring_chan0_up[i-1]),
                  .ring_in1_down (ring_chan1_down[i-1]),
                  .ring_in1_up   (ring_chan1_up[i-1]),
                  .ring_out0_down (ring_chan0_down[i]),
                  .ring_out0_up   (ring_chan0_up[i]),
                  .ring_out1_down (ring_chan1_down[i]),
                  .ring_out1_up   (ring_chan1_up[i]),
                  .local_in_down ({in[i].valid, in[i].last, in[i].data}),
                  .local_in_up   (in[i].ready),
                  .local_out_down ({out[i].valid, out[i].last, out[i].data}),
                  .local_out_up (out[i].ready));

      end
   endgenerate
   
endmodule // Ring
