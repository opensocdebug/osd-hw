
import dii_package::dii_flit;

module osd_ctm
  #(
    parameter ADDR_WIDTH = 64,  // width of memory addresses
    parameter DATA_WIDTH = 64   // system word length
    )
   (
    input                  clk, rst,

    input [9:0]            id,

    input                  dii_flit debug_in,
    output                 debug_in_ready,
    output                 dii_flit debug_out,
    input                  debug_out_ready,

    input                  trace_valid,
    input [ADDR_WIDTH-1:0] trace_pc,
    input [ADDR_WIDTH-1:0] trace_npc,
    input                  trace_jal,
    input                  trace_jalr,
    input                  trace_branch,
    input                  trace_load,
    input                  trace_store,
    input                  trace_trap,
    input                  trace_xcpt,
    input                  trace_csr,
    input                  trace_br_taken,
    input [1:0]            trace_prv,
    input [ADDR_WIDTH-1:0] trace_addr,
    input [DATA_WIDTH-1:0] trace_rdata,
    input [DATA_WIDTH-1:0] trace_wdata,
    input [DATA_WIDTH-1:0] trace_time
    );

endmodule // osd_ctm
