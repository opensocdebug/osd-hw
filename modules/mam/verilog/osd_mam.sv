
import dii_package::dii_flit;

module osd_mam
  #(parameter DATA_WIDTH = 16, // in bits, must be multiple of 16
    parameter MEM_SIZE = 'x,
    parameter ADDR_BASE = 'x
    )
   (
    input                                   clk, rst,

    input                                   dii_flit debug_in, output debug_in_ready,
    output                                  dii_flit debug_out, input debug_out_ready,

    input [9:0]                             id,

    output                                  req_valid, // Start a new memory access request
    input                                   req_ready, // Acknowledge the new memory access request
    output                                  req_rw, // 0: Read, 1: Write
    output [$clog2(MEM_SIZE+ADDR_BASE)-1:0] req_addr, // Request base address
    output                                  req_burst, // 0 for single beat access, 1 for incremental burst
    output [15:0]                           req_size, // Burst size in number of words

    output                                  write_valid, // Next write data is valid
    output [DATA_WIDTH-1:0]                 write_data, // Write data
    output [$clog2(DATA_WIDTH/8)-1:0]       write_strb, // Byte strobe if req_burst==0
    input                                   write_ready, // Acknowledge this data item
   
    input                                   read_valid, // Next read data is valid
    input [DATA_WIDTH-1:0]                  read_data, // Read data
    output                                  read_ready // Acknowledge this data item
   );
   
   
   logic        reg_request;
   logic        reg_write;
   logic [15:0] reg_addr;
   logic [13:0] reg_size;
   logic [15:0] reg_wdata;
   logic        reg_ack;
   logic        reg_err;
   logic [15:0] reg_rdata;

   assign reg_ack = 0;
   assign reg_err = 0;
   assign reg_rdata = 0;
   
   logic        stall;

   dii_flit dp_out, dp_in;
   logic        dp_out_ready, dp_in_ready;
   
   osd_regaccess_layer
     #(.MODID(16'h3), .MODVERSION(16'h0),
       .MAX_REG_SIZE(16), .CAN_STALL(0))
   u_regaccess(.*,
               .module_in (dp_out),
               .module_in_ready (dp_out_ready),
               .module_out (dp_in),
               .module_out_ready (dp_in_ready));

   
endmodule // osd_dem_uart

   
