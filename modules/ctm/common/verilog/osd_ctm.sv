
import dii_package::dii_flit;

module osd_ctm
  #(
    parameter ADDR_WIDTH = 64,  // width of memory addresses
    parameter DATA_WIDTH = 64,  // system word length
    parameter INST_WIDTH = 32,  // instruction size
    parameter RFA_WIDTH = 5     // address width of register file
    )
   (
    input                  clk, rst,

    input [9:0]            id,

    input  dii_flit        debug_in,
    output                 debug_in_ready,
    output dii_flit        debug_out,
    input                  debug_out_ready,

    input                  trace_valid,
    input [ADDR_WIDTH-1:0] trace_pc,
    input [INST_WIDTH-1:0] trace_instr,
    input [DATA_WIDTH-1:0] trace_wdata
    );

endmodule // osd_ctm
