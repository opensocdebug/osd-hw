
module ring_router
  #(parameter BUFFER_SIZE=4)
   (
    input         clk, rst,

    input [9:0]   id,

    dii_channel   ring_in0,
    dii_channel   ring_in1,
    
    dii_channel   ring_out0,
    dii_channel   ring_out1,
                  
    dii_channel   local_in,
    dii_channel   local_out
    );

   dii_channel ring_fwd0();
   dii_channel ring_fwd1();
   dii_channel ring_local0();
   dii_channel ring_local1();
   dii_channel ring_muxed();

   ring_router_demux
     u_demux0(.*,
              .in        ( ring_in0    ),
              .out_local ( ring_local0 ),
              .out_ring  ( ring_fwd0   )
              );

   ring_router_demux
     u_demux1(.*,
              .in        ( ring_in1    ),
              .out_local ( ring_local1 ),
              .out_ring  ( ring_fwd1   )
              );

   ring_router_mux_rr
     u_mux_local(.*,
                 .in0    ( ring_local0 ),
                 .in1    ( ring_local1 ),
                 .out    ( local_out   )
                 );

   ring_router_mux
     u_mux_ring0(.*,
                 .in_ring  ( ring_fwd0  ),
                 .in_local ( local_in   ),
                 .out      ( ring_muxed )
                 );

   dii_buffer
     #(.WIDTH(16), .SIZE(BUFFER_SIZE))
   u_buffer0(.*,
             .packet_size (            ),
             .in          ( ring_muxed ),
             .out         ( ring_out0  )
             );

   dii_buffer
     #(.WIDTH(16), .SIZE(BUFFER_SIZE))
   u_buffer1(.*,
             .packet_size (            ),
             .in          ( ring_fwd1  ),
             .out         ( ring_out1  )
             );

endmodule
