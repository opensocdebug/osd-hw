
module debug_ring
  #(parameter PORTS = 1,
    parameter BUFFER_SIZE = 4)
   (input clk, rst,
    
    input [PORTS*16-1:0]  in_flat_data,
    input [PORTS-1:0]     in_flat_valid,
    input [PORTS-1:0]     in_flat_first,
    input [PORTS-1:0]     in_flat_last,
    output [PORTS-1:0]    in_flat_ready,
    output [PORTS*16-1:0] out_flat_data,
    output [PORTS-1:0]    out_flat_valid,
    output [PORTS-1:0]    out_flat_first,
    output [PORTS-1:0]    out_flat_last,
    input [PORTS-1:0]     out_flat_ready
   );

   /* Router->Module */
   dii_channel out [PORTS-1:0];
   /* Module->Router */
   dii_channel in [PORTS-1:0];

   genvar i;
   generate
      for (i = 0; i < PORTS; i = i + 1) begin
         assign in[i].data  = in_flat_data[(i+1)*16-1:i*16];
         assign in[i].valid = in_flat_valid[i];
         assign in[i].first = in_flat_first[i];
         assign in[i].last  = in_flat_last[i];
         assign in_flat_ready[i] = in[i].ready;
         assign out_flat_data[(i+1)*16-1:i*16] = out[i].data;
         assign out_flat_valid[i] = out[i].valid;
         assign out_flat_first[i] = out[i].first;
         assign out_flat_last[i] = out[i].last;
         assign out[i].ready = out_flat_ready[i];
      end
   endgenerate

   dii_channel ring_chan0 [PORTS-1:0];
   dii_channel ring_chan1 [PORTS-1:0];

   dii_channel tie;

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
