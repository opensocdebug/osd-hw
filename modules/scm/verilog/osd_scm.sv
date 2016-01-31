
module osd_scm
  #(parameter SYSTEMID='x,
    parameter NUM_MOD='x,
    parameter MAX_PKT_LEN=0)
   (input clk, rst,

    input [9:0] id,

    dii_channel debug_in,
    dii_channel debug_out);

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
                 .stall (),
                 .debug_in (debug_in),
                 .debug_out (debug_out));
   
   always @(*) begin
      reg_ack = 1;
      reg_rdata = 'x;
      reg_err = 0;

      case (reg_addr)
        16'h200: reg_rdata = SYSTEMID;
        16'h201: reg_rdata = NUM_MOD;
        16'h202: reg_rdata = MAX_PKT_LEN;
        default: reg_err = reg_request;
      endcase // case (reg_addr)
   end
endmodule
