import dii_package::dii_flit;

module osd_stm
   (
    input                  clk, rst,

    input [9:0]            id,

    input  dii_flit        debug_in,
    output                 debug_in_ready,
    output dii_flit        debug_out,
    input                  debug_out_ready,

    input                  trace_valid,
    input [15:0]           trace_id,
    input [63:0]           trace_value
    );

endmodule // osd_stm
