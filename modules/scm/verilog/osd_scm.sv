
import dii_package::dii_flit;

module osd_scm
  #(parameter SYSTEMID='x,
    parameter NUM_MOD='x,
    parameter MAX_PKT_LEN=0)
   (input clk, rst,

    input [9:0] id,

    input dii_flit debug_in, output debug_in_ready,
    output dii_flit debug_out, input debug_out_ready);

   logic        reg_request;
   logic        reg_write;
   logic [15:0] reg_addr;
   logic [1:0]  reg_size;
   logic [15:0] reg_wdata;
   logic        reg_ack;
   logic        reg_err;
   logic [15:0] reg_rdata;
   
   osd_statctrlif
     #(.MODID(16'h1), .MODVERSION(16'h0),
       .MAX_REG_SIZE(16))
   u_statctrlif(.*,
                 .stall ());
   
   always @(*) begin
      reg_ack = 1;
      reg_rdata = 'x;
      reg_err = 0;

      case (reg_addr)
        16'h200: reg_rdata = 16'(SYSTEMID);
        16'h201: reg_rdata = 16'(NUM_MOD);
        16'h202: reg_rdata = 16'(MAX_PKT_LEN);
        default: reg_err = reg_request;
      endcase // case (reg_addr)
   end
endmodule
