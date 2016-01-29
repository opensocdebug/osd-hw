
module ring_router
  #(parameter BUFFER_SIZE=4)
   (
    input clk, rst,

    input [9:0] id,

    dii_channel ring_in0,
    dii_channel ring_in1,

    dii_channel ring_out0,
    dii_channel ring_out1,

    dii_channel  local_in,    
    dii_channel local_out
    );

   dii_channel c_ring1fwd();
   dii_channel c_ring0fwd();
   dii_channel c_ring1local();
   dii_channel c_ring0local();
   dii_channel c_ring0muxed();

   dii_channel c_local_in();
//   assign local_in.ready = c_local_in.assemble(local_in.data, local_in.first, local_in.last, local_in.valid);
   assign local_in.ready = c_local_in.ready;
   assign c_local_in.valid = local_in.valid;
   assign c_local_in.data = local_in.data;
   assign c_local_in.first = local_in.first;
   assign c_local_in.last = local_in.last;

   dii_channel c_ring_in0();
//   assign ring_in0.ready = c_ring_in0.assemble(ring_in0.data, ring_in0.first, ring_in0.last, ring_in0.valid);
   assign ring_in0.ready = c_ring_in0.ready;
   assign c_ring_in0.valid = ring_in0.valid;
   assign c_ring_in0.data = ring_in0.data;
//   assign c_ring_in0.first = ring_in0.first;
   assign c_ring_in0.last = ring_in0.last;

   dii_channel c_ring_out0();
//   assign c_ring_out0.ready = ring_out0.assemble(c_ring_out0.data, c_ring_out0.first, c_ring_out0.last, c_ring_out0.valid);
   assign c_ring_out0.ready = ring_out0.ready;
   assign ring_out0.valid = c_ring_out0.valid;
   assign ring_out0.first = c_ring_out0.first;
   assign ring_out0.last = c_ring_out0.last;
   assign ring_out0.data = c_ring_out0.data;
   
   ring_router_demux
     u_demux0(.*,
              .in        (c_ring_in0),
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
                 .in_local (c_local_in),
                 .out      (c_ring0muxed));
                 
   dii_buffer
     #(.WIDTH(16), .SIZE(BUFFER_SIZE))
   u_buffer0(.*,
             .packet_size (),
             .in          (c_ring0muxed),
             .out         (c_ring_out0));
   
   dii_buffer
     #(.WIDTH(16), .SIZE(BUFFER_SIZE))
   u_buffer1(.*,
             .packet_size (),
             .in          (c_ring1fwd),
             .out         (ring_out1));
   
endmodule
