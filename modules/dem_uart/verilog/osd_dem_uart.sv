
module osd_dem_uart
  (input clk, rst,

   dii_channel debug_in,
   dii_channel debug_out,

   input [9:0]  id,

   input [7:0]  out_char,
   input        out_valid,
   output reg   out_ready,

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

   assign reg_ack = 0;
   assign reg_err = 0;
   assign reg_rdata = 0;
   
   logic        stall;

   dii_channel c_ctrlstat_out();
   dii_channel c_uart_out();
   
   osd_statctrlif
     #(.MODID(16'h2), .MODVERSION(16'h0),
       .MAX_REG_SIZE(16), .CAN_STALL(1))
   u_statctrlif(.*,
                 .debug_in (debug_in),
                 .debug_out (c_ctrlstat_out));

   ring_router_mux
     u_mux(.*,
           .in_local (c_uart_out),
           .in_ring (c_ctrlstat_out),
           .out    (debug_out));

   reg [1:0]    state;
   
   always @(posedge clk) begin
      if (rst) begin
         state <= 0;
      end else begin
         case (state)
           0: begin
              if (out_valid & !stall & c_uart_out.ready) begin
                 state <= 1;
              end
           end
           1: begin
              if (c_uart_out.ready) begin
                 state <= 2;
              end
           end
           2: begin
              if (c_uart_out.ready) begin
                 state <= 0;
              end
           end
         endcase
      end
   end

   always @(*) begin
      c_uart_out.valid = 0;
      c_uart_out.last = 0;
      c_uart_out.data = 'x;
      out_ready = 0;
                  
      case (state)
        0: begin
           c_uart_out.valid = out_valid & !stall;
           c_uart_out.data = 0;
        end
        1: begin
           c_uart_out.valid = 1;
           c_uart_out.data = {4'b1000, 2'b00, 10'(id)};
        end
        2: begin
           c_uart_out.valid = 1;
           c_uart_out.data = {8'h0, out_char};
           c_uart_out.last = 1;
           out_ready = c_uart_out.ready;
        end
      endcase // case (state)
   end
   
endmodule // osd_dem_uart

   
