
module osd_scm
  #(parameter SYSTEMID='x,
    parameter NUM_MOD='x)
   (input clk, rst,

    input [9:0] id,

    dii_channel debug_in,
    dii_channel debug_out);

   dii_channel debug_in_fwd();
   assign debug_in.ready = debug_in_fwd.assemble(debug_in.data, debug_in.first, debug_in.last, debug_in.valid);
   
   
   osd_statctrlif
     #(.MODID(16'hbeef), .MODVERSION(16'h1))
   u_statctrlif(.*,
                 .id (id),
                 .debug_in (debug_in_fwd),
                 .debug_out (debug_out));
   

endmodule
