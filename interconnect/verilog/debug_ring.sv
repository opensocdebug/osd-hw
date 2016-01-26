
module debug_ring
  #(parameter PORTS = 1,
    parameter BUFFER_SIZE = 4)
   (input clk, rst,
    
    dii_channel.master out [PORTS-1:0],
    dii_channel.slave in [PORTS-1:0] 
    );
      
   dii_channel ring_chan0 [PORTS-1:0];
   dii_channel ring_chan1 [PORTS-1:0];

   dii_channel tie;

   genvar i;

   generate
      ring_router
        #(.BUFFER_SIZE(BUFFER_SIZE))
      u_router0(.clk (clk),
                .rst (rst),
                .id  (10'(1)),
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
                  .id        (10'(i+1)),
                  .ring_in0  (ring_chan0[i-1]),
                  .ring_in1  (ring_chan1[i-1]),
                  .ring_out0 (ring_chan0[i]),
                  .ring_out1 (ring_chan1[i]),
                  .local_in  (in[i]),
                  .local_out (out[i]));
      end
   endgenerate
   
endmodule // Ring
