
module osd_scm
  #(parameter SYSTEMID='x,
    parameter NUM_MOD='x)
   (input clk, rst,

    input [9:0] id,

    dii_channel debug_in,
    dii_channel debug_out);
   
   osd_statctrlif
     #(.MODID(16'hbeef), .MODVERSION(16'h1))
   u_statctrlif(.*,
                 .id (id),
                 .debug_in (debug_in),
                 .debug_out (debug_out));
   

endmodule
