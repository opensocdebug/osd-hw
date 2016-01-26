
module ring_router
  #(parameter BUFFER_SIZE=4)
   (
    input clk, rst,

    input [9:0] id,

    dii_channel.slave ring_in0,
    dii_channel.slave ring_in1,

    dii_channel.master ring_out0,
    dii_channel.master ring_out1,

    dii_channel.slave  local_in,    
    dii_channel.master local_out
    );

   dii_channel c_ring1fwd;
   dii_channel c_ring0fwd;
   dii_channel c_ring1local;
   dii_channel c_ring0local;
   dii_channel c_ring0muxed;

   ring_router_demux
     u_demux0(.*,
              .in        (ring_in0),
              .out_local (c_ring0local),
              .out_ring  (c_ring0fwd));

   ring_router_demux
     u_demux1(.*,
              .in        (ring_in1),
              .out_local (c_ring1local),
              .out_ring  (c_ring1fwd));
   
   ring_router_mux_rr
     u_mux_local(.*,
                 .in0 (c_ring0local),
                 .in1 (c_ring1local),
                 .out (local_out));
   
   ring_router_mux
     u_mux_ring0(.*,
                 .in_ring  (c_ring0fwd),
                 .in_local (local_in),
                 .out      (c_ring0muxed));
                 
   dii_buffer
     #(.WIDTH(16), .SIZE(BUFFER_SIZE))
   u_buffer0(.*,
             .in  (c_ring0muxed),
             .out (ring_out0));
   
   dii_buffer
     #(.WIDTH(16), .SIZE(BUFFER_SIZE))
   u_buffer1(.*,
             .in  (c_ring1fwd),
             .out (ring_out1));
   
endmodule
