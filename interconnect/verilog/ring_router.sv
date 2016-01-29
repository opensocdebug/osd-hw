
module ring_router
  #(parameter BUFFER_SIZE=4)
   (
    input         clk, rst,

    input [9:0]   id,

    input [17:0]  ring_in0_down,
    output        ring_in0_up,

    input [17:0]  ring_in1_down,
    output        ring_in1_up,
    
    output [17:0] ring_out0_down,
    input         ring_out0_up,

    output [17:0] ring_out1_down,
    input         ring_out1_up,
                  
    input [17:0]  local_in_down,
    output        local_in_up,

    output [17:0] local_out_down,
    input         local_out_up
    );

   dii_channel c_ring_in0();
   dii_channel c_ring_in1();
   dii_channel c_ring_out0();
   dii_channel c_ring_out1();
   dii_channel c_local_in();
   dii_channel c_local_out();

//   assign ring_in0_up = c_ring_in0.assemble_up(ring_in0_down);
   assign { c_ring_in0.valid, c_ring_in0.last, c_ring_in0.data } = ring_in0_down;
   assign ring_in0_up = c_ring_in0.ready;
//   assign ring_in1_up = c_ring_in1.assemble_up(ring_in1_down);
   assign { c_ring_in1.valid, c_ring_in1.last, c_ring_in1.data } = ring_in1_down;
   assign ring_in1_up = c_ring_in1.ready;
//   assign local_in_up = c_local_in.assemble_up(local_in_down);
   assign { c_local_in.valid, c_local_in.last, c_local_in.data } = local_in_down;
   assign local_in_up = c_local_in.ready;

//   assign ring_out0_down = c_ring_out0.assemble_down(ring_out0_up);
   assign ring_out0_down = { c_ring_out0.valid, c_ring_out0.last, c_ring_out0.data };
   assign c_ring_out0.ready = ring_out0_up;
//   assign ring_out1_down = c_ring_out1.assemble_down(ring_out1_up);
   assign ring_out1_down = { c_ring_out1.valid, c_ring_out1.last, c_ring_out1.data };
   assign c_ring_out1.ready = ring_out1_up;
//   assign local_out_down = c_local_out.assemble_down(local_out_up);
   assign local_out_down = { c_local_out.valid, c_local_out.last, c_local_out.data };
   assign c_local_out.ready = local_out_up;
   
   dii_channel c_ring1fwd();
   dii_channel c_ring0fwd();
   dii_channel c_ring1local();
   dii_channel c_ring0local();
   dii_channel c_ring0muxed();

   ring_router_demux
     u_demux0(.*,
              .in        (c_ring_in0),
              .out_local (c_ring0local),
              .out_ring  (c_ring0fwd));

   ring_router_demux
     u_demux1(.*,
              .in        (c_ring_in1),
              .out_local (c_ring1local),
              .out_ring  (c_ring1fwd));
   
   ring_router_mux_rr
     u_mux_local(.*,
                 .in0 (c_ring0local),
                 .in1 (c_ring1local),
                 .out (c_local_out));
   
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
             .out         (c_ring_out1));
   
endmodule
