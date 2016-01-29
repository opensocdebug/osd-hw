
module osd_dem_uart
  (input clk, rst,

   dii_channel debug_in,
   dii_channel debug_out,

   input [9:0]  id,

   input [7:0]  out_char,
   input        out_valid,
   output       out_ready,

   output [7:0] in_char,
   output       in_valid,
   input        in_ready);

   logic        reg_request;
   logic        reg_write;
   logic [15:0] reg_addr;
   logic        reg_size;
   logic [15:0] reg_wdata;
   logic        reg_ack;
   logic        reg_err;
   logic [15:0] reg_rdata;

   logic        stall;
   
   osd_statctrlif
     #(.MODID(16'h2), .MODVERSION(16'h0),
       .MAX_REG_SIZE(16), .CAN_STALL(1))
   u_statctrlif(.*,
                 .debug_in (debug_in),
                 .debug_out (debug_out));

   
   
endmodule // osd_dem_uart

   
