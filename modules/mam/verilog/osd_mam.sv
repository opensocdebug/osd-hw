import dii_package::dii_flit;

module osd_mam
  #(parameter DATA_WIDTH = 16, // in bits, must be multiple of 16
    parameter ADDR_WIDTH = 32,
    parameter MEM_SIZE = 'x,
    parameter BASE_ADDR = 0,
    parameter MAX_PKT_LEN = 'x
    )
   (
    input                       clk, rst,

    input                       dii_flit debug_in, output debug_in_ready,
    output                      dii_flit debug_out, input debug_out_ready,

    input [9:0]                 id,

    output                      req_valid, // Start a new memory access request
    input                       req_ready, // Acknowledge the new memory access request
    output reg                  req_rw, // 0: Read, 1: Write
    output reg [ADDR_WIDTH-1:0] req_addr, // Request base address
    output reg                  req_burst, // 0 for single beat access, 1 for incremental burst
    output reg [13:0]           req_beats, // Burst length in number of words

    output                      write_valid, // Next write data is valid
    output reg [DATA_WIDTH-1:0] write_data, // Write data
    output [DATA_WIDTH/8-1:0]   write_strb, // Byte strobe if req_burst==0
    input                       write_ready, // Acknowledge this data item
   
    input                       read_valid, // Next read data is valid
    input [DATA_WIDTH-1:0]      read_data, // Read data
    output                      read_ready // Acknowledge this data item
   );

   logic        reg_request;
   logic        reg_write;
   logic [15:0] reg_addr;
   logic [1:0]  reg_size;
   logic [15:0] reg_wdata;
   logic        reg_ack;
   logic        reg_err;
   logic [15:0] reg_rdata;

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

   assign reg_ack = 1;

   logic [63:0] base_addr;
   assign base_addr = 64'(BASE_ADDR);
   logic [63:0] mem_size;
   assign mem_size = 64'(MEM_SIZE);
   
   always_comb @(*) begin
      reg_err = 0;
      reg_rdata = 16'hx;
      
      case (reg_addr)
        16'h200: reg_rdata = 16'(DATA_WIDTH);
        16'h201: reg_rdata = 16'(ADDR_WIDTH);
        16'h202: reg_rdata = base_addr[15:0];
        16'h203: reg_rdata = base_addr[31:16];
        16'h204: reg_rdata = base_addr[47:32];
        16'h205: reg_rdata = base_addr[63:48];
        16'h206: reg_rdata = mem_size[15:0];
        16'h207: reg_rdata = mem_size[31:16];
        16'h208: reg_rdata = mem_size[47:32];
        16'h209: reg_rdata = mem_size[63:48];
        default: reg_err = 1;
      endcase
   end

   enum {
         STATE_INACTIVE, STATE_CMD_SKIP, STATE_CMD, STATE_ADDR,
         STATE_REQUEST, STATE_WRITE_PACKET, STATE_WRITE, STATE_WRITE_WAIT,
         STATE_READ_PACKET, STATE_READ, STATE_READ_WAIT
         } state, nxt_state;

   // The counter is used to count flits
   reg [$clog2(MAX_PKT_LEN)-1:0] counter;
   logic [$clog2(MAX_PKT_LEN)-1:0] nxt_counter;

   // This counter is used to count words (that can span packets)
   reg [$clog2(DATA_WIDTH/16)-1:0] wcounter;
   logic [$clog2(DATA_WIDTH/16)-1:0] nxt_wcounter;

   // Stores whether we are inside a packet
   reg                               in_packet;
   logic                             nxt_in_packet;

   // Combinational part of interface
   logic [13:0] nxt_req_beats;
   logic        nxt_req_rw;
   logic        nxt_req_burst;
   logic [ADDR_WIDTH-1:0] nxt_req_addr;
   logic [DATA_WIDTH-1:0] nxt_write_data;

   // This is the number of (16 bit) words needed to form an address
   localparam ADDR_WORDS = ADDR_WIDTH >> 4;
   
   always_ff @(posedge clk) begin
      if (rst) begin
         state <= STATE_INACTIVE;
      end else begin
         state <= nxt_state;
      end

      req_beats <= nxt_req_beats;
      req_rw <= nxt_req_rw;
      req_burst <= nxt_req_burst;
      req_addr <= nxt_req_addr;
      counter <= nxt_counter;
      write_data <= nxt_write_data;
      wcounter <= nxt_wcounter;
      in_packet <= nxt_in_packet;
   end

   integer i;
   always_comb @(*) begin
      nxt_state = state;
      nxt_counter = counter;
      nxt_req_beats = req_beats;
      nxt_write_data = write_data;
      nxt_wcounter = wcounter;
      nxt_in_packet = in_packet;
      
      nxt_req_addr = req_addr;
      
      dp_in_ready = 0;
      dp_out.valid = 0;
      dp_out.data = 16'hx;
      dp_out.last = 0;
      req_valid = 0;
      write_valid = 0;

      case (state)
         STATE_INACTIVE: begin
            dp_in_ready = 1;
            if (dp_in.valid) begin
               nxt_state = STATE_CMD_SKIP;
            end
         end
        STATE_CMD_SKIP: begin
           dp_in_ready = 1;
           if (dp_in.valid) begin
              nxt_state = STATE_CMD;
           end
        end
        STATE_CMD: begin
           dp_in_ready = 1;
           nxt_req_beats = dp_in.data[13:0];
           nxt_req_rw = dp_in.data[15];
           nxt_req_burst = dp_in.data[14];
           
           if (dp_in.valid) begin
              nxt_state = STATE_ADDR;
              nxt_counter = 0;
           end
        end
        STATE_ADDR: begin
           dp_in_ready = 1;
           nxt_req_addr[(counter+1)*16-1 -: 16] = dp_in.data;
           if (dp_in.valid) begin
              nxt_counter = counter + 1;
              if (counter == ADDR_WORDS - 1) begin
                 nxt_state = STATE_REQUEST;
              end
           end
        end
        STATE_REQUEST: begin
           req_valid = 1;
           if (req_ready) begin
              if (req_rw) begin
                 nxt_state = STATE_WRITE_PACKET;
              end else begin
                 nxt_state = STATE_READ_PACKET;
              end
              nxt_wcounter = 0;
              nxt_counter = 0;
              nxt_in_packet = 0;
           end
        end
        STATE_WRITE_PACKET: begin
           dp_in_ready = 1;
           if (dp_in.valid) begin
              nxt_counter = counter + 1;
              if (counter == 1) begin
                 nxt_state = STATE_WRITE;
              end
           end
        end
        STATE_WRITE: begin
           dp_in_ready = 1;
           nxt_write_data[(DATA_WIDTH/16-wcounter)*16-1 -: 16] = dp_in.data;
           if (dp_in.valid) begin
              nxt_wcounter = wcounter + 1;
              if (wcounter == DATA_WIDTH/16 - 1) begin
                 nxt_state = STATE_WRITE_WAIT;
                 nxt_in_packet = !dp_in.last;
                 nxt_wcounter = 0;
              end else if (dp_in.last) begin
                 nxt_counter = 0;
                 nxt_state = STATE_WRITE_PACKET;
              end
           end
        end // case: STATE_WRITE
        STATE_WRITE_WAIT: begin
           write_valid = 1;
           if (write_ready) begin
              nxt_req_beats = req_beats - 1;
              if (req_beats == 1) begin
                 nxt_state = STATE_INACTIVE;
              end else begin
                 if (in_packet) begin
                    nxt_state = STATE_WRITE;
                 end else begin
                    nxt_counter = 0;
                    nxt_state = STATE_WRITE_PACKET;
                 end
              end
           end
        end // case: STATE_WRITE_WAIT
        STATE_READ_PACKET: begin
           dp_out.valid = 1;
           if (counter == 0) begin
              dp_out.data = 16'h0;
           end else begin
              dp_out.data = { 2'b01, 4'b1111, id };
           end
           if (dp_out_ready) begin
              nxt_counter = counter + 1;
              if (counter == 1) begin
                 nxt_state = STATE_READ;
              end
           end
        end // case: STATE_READ_PACKET
        STATE_READ: begin
           if (read_valid) begin
              dp_out.valid = 1;
              dp_out.last = (counter == MAX_PKT_LEN) ||
                            ((wcounter == DATA_WIDTH/16 - 1) && (req_beats == 1));
              dp_out.data = read_data[DATA_WIDTH-wcounter*16-1 -: 16];
              if (dp_out_ready) begin
                 if (wcounter == DATA_WIDTH/16-1) begin
                    nxt_req_beats = req_beats - 1;

                    read_ready = 1;

                    if (req_beats == 1) begin
                       nxt_state = STATE_INACTIVE;
                    end else begin
                       if (counter == MAX_PKT_LEN - 1) begin
                          nxt_state = STATE_READ_PACKET;
                          nxt_counter = 0;
                       end else begin
                          nxt_counter = counter + 1;
                       end
                    end
                 end else begin
                    if (counter == MAX_PKT_LEN - 1) begin
                       nxt_state = STATE_READ_PACKET;
                       nxt_counter = 0;
                    end else begin
                       nxt_counter = counter + 1;
                    end
                 end
              end
           end
        end
      endcase
   end
   
   
endmodule // osd_dem_uart
