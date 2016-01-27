
module osd_dem_uart
  (input clk, rst,

   dii_channel debug_in,
   dii_channel debug_out,

   input [7:0]  out_char,
   input        out_valid,
   output       out_ready,

   output [7:0] in_char,
   output       in_valid,
   input        in_ready);

endmodule // osd_dem_uart

   
