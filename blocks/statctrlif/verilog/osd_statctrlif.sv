
module osd_statctrlif
  #(parameter MODID = 'x,
    parameter MODVERSION = 'x,
    parameter CAN_STALL = 0,
    parameter MAX_REG_SIZE = 16)
   (input clk, rst,

    input [9:0]   id,

    dii_channel debug_in,
    dii_channel debug_out,

    output reg    reg_request,
    output        reg_write,
    output [15:0] reg_addr,
    output        reg_size,
    output [15:0] reg_wdata,
    input         reg_ack,
    input         reg_err,
    input [15:0]  reg_rdata,


    output        stall);

   localparam REQ_SIZE_16 = 2'b01;
   localparam REQ_SIZE_32 = 2'b10;
   localparam REQ_SIZE_64 = 2'b11;

   localparam REG_MODID   = 0;
   localparam REG_VERSION = 1;
   localparam REG_CS      = 3;

   localparam CS_STALL = 5'h1;

   // Registers
   reg          mod_cs_stall;
   logic        nxt_mod_cs_stall;

   assign stall = CAN_STALL ? mod_cs_stall : 0;
   
   // State machine
   reg [3:0]    state;
   reg [3:0]    nxt_state;

   // Local request/response data
   reg                      req_write;
   reg                      req_burst;
   reg [1:0]                req_size;
   reg [15:0]               req_addr;
   reg [MAX_REG_SIZE-1:0]   reqresp_value;
   reg [9:0]                resp_dest;
   reg                      resp_error;
   logic                    nxt_req_write;
   logic                    nxt_req_burst;
   logic [1:0]              nxt_req_size;
   logic [15:0]             nxt_req_addr;
   logic [MAX_REG_SIZE-1:0] nxt_reqresp_value;
   logic [9:0]              nxt_resp_dest;
   logic                    nxt_resp_error;

   logic                    addr_is_ext;
   logic [8:0]  addr_internal;
   assign addr_is_ext = (debug_in.data[0][15:9] != 0);
   assign addr_internal = debug_in.data[0][8:0];

   assign reg_write = req_write;
   assign reg_addr = req_addr;
   assign reg_size = req_size;
   assign reg_wdata = reqresp_value;
   
   localparam STATE_IDLE       = 0;
   localparam STATE_START      = 1;
   localparam STATE_ADDR       = 2;
   localparam STATE_WRITE      = 3;
   localparam STATE_RESP_START = 4;
   localparam STATE_RESP_SRC   = 5;
   localparam STATE_RESP_VALUE = 6;
   localparam STATE_DROP       = 7;
   localparam STATE_EXT_START  = 8;
   localparam STATE_EXT_WAIT   = 9;
   
   always @(posedge clk) begin
      if (rst) begin
         state <= STATE_IDLE;
         mod_cs_stall <= 0;
      end else begin
         state <= nxt_state;
         mod_cs_stall <= nxt_mod_cs_stall;
      end
      resp_dest <= nxt_resp_dest;
      reqresp_value <= nxt_reqresp_value;
      resp_error <= nxt_resp_error;
      req_write <= nxt_req_write;
      req_burst <= nxt_req_burst;
      req_size <= nxt_req_size;
      req_addr <= nxt_req_addr;
   end
   
   always @(*) begin
      nxt_state = state;

      nxt_req_write = req_write;
      nxt_req_burst = req_burst;
      nxt_req_size = req_size;
      nxt_resp_dest = resp_dest;
      nxt_reqresp_value = reqresp_value;
      nxt_resp_error = resp_error;

      debug_in.ready = 0;
      debug_out.valid = 0;
      debug_out.data = 0;
      debug_out.last = 0;

      reg_request = 0;
      
      case (state)
        STATE_IDLE: begin
           debug_in.ready = 1;
           if (debug_in.valid) begin
              nxt_state = STATE_START;
           end
        end
        STATE_START: begin
           debug_in.ready = 1;
           nxt_req_write = (debug_in.data[0][12]);
           nxt_req_burst = (debug_in.data[0][13]);
           nxt_req_size = debug_in.data[0][11:10];
           nxt_resp_dest = debug_in.data[0][9:0];
           nxt_resp_error = 0;
           
           if (debug_in.valid) begin
              if (|debug_in.data[0][15:14]) begin
                 nxt_state = STATE_DROP;
              end else begin
                 nxt_state = STATE_ADDR;
              end
           end
        end // case: STATE_START
        STATE_ADDR: begin
           debug_in.ready = 1;

           if (addr_is_ext) begin
              nxt_req_addr = debug_in.data[0];
              nxt_state = STATE_EXT_START;
           end else begin
              if (nxt_req_write) begin
                 // LOCAL WRITE
                 if (req_size != REQ_SIZE_16) begin
                    nxt_resp_error = 1;
                 end else begin
                    case (debug_in.data)
                      REG_CS: begin
                         nxt_reqresp_value[4:0] = debug_in.data[0][15:11];
                         if (debug_in.data[0][15:11] == CS_STALL) begin
                            if (!CAN_STALL) begin
                               nxt_resp_error = 1;
                            end
                         end else begin
                            nxt_resp_error = 1;
                         end
                      end
                      default: nxt_resp_error = 1;
                    endcase // case (debug_in.data)
                 end
              end else begin // if (nxt_req_write)
                 // LOCAL READ
                 case (debug_in.data)
                   REG_MODID: nxt_reqresp_value = 16'(MODID);
                   REG_VERSION: nxt_reqresp_value = 16'(MODVERSION);
                   default: nxt_resp_error = 1;
                 endcase // case (debug_in.data)
              end

              if (debug_in.valid) begin
                 if (nxt_req_write) begin
                    if (debug_in.last) begin
                       nxt_resp_error = 1;
                       nxt_state = STATE_RESP_START;
                    end else if (nxt_resp_error) begin
                       nxt_state = STATE_DROP;
                    end else begin
                       nxt_state = STATE_WRITE;
                    end
                 end else begin
                    if (debug_in.last) begin
                       nxt_state = STATE_RESP_START;
                    end else begin
                       nxt_state = STATE_DROP;
                    end
                 end
              end
           end
        end // case: STATE_ADDR
        STATE_WRITE: begin
           if (debug_in.valid) begin
              case (reqresp_value[4:0])
                CS_STALL: begin
                   nxt_mod_cs_stall = debug_in.data[0][0];
                end
              endcase // case (nxt_rest_value[4:0])
           end

           if (debug_in.valid) begin
              if (debug_in.last) begin
                 nxt_state = STATE_RESP_START;
              end else begin
                 nxt_state = STATE_DROP;
              end
           end
        end
        STATE_RESP_START: begin
           debug_out.valid = 1;
           debug_out.data = {6'h0, resp_dest};

           if (debug_out.ready) begin
              nxt_state = STATE_RESP_SRC;
           end
        end
        STATE_RESP_SRC: begin
           debug_out.valid = 1;
           debug_out.data = {4'h0, req_write, resp_error, 10'(id)};

           debug_out.last = resp_error | req_write;

           if (debug_out.ready) begin
              if (req_write) begin
                 nxt_state = STATE_IDLE;
              end else begin
                 nxt_state = STATE_RESP_VALUE;
              end
           end
        end
        STATE_RESP_VALUE: begin
           debug_out.valid = 1;
           debug_out.data = reqresp_value[15:0];
           debug_out.last = 1;
           if (debug_out.ready) begin
              nxt_state = STATE_IDLE;
           end
        end

        STATE_EXT_START: begin
           reg_request = 1;
           nxt_reqresp_value = reg_rdata;
           if (reg_ack | reg_err) begin
              nxt_resp_error = reg_err;
              nxt_state = STATE_RESP_START;
           end
        end

        STATE_DROP: begin
           debug_in.ready = 1;
           if (debug_in.valid & debug_in.last) begin
              nxt_state = STATE_IDLE;
           end
        end
      endcase // case (state)
   end

endmodule