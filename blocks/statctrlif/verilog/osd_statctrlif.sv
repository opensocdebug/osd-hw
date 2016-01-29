
module osd_statctrlif
  #(parameter MODID = 'x,
    parameter MODVERSION = 'x)
   (input clk, rst,

    input [9:0] id,
                
    dii_channel debug_in,
    dii_channel debug_out);

   localparam REQ_READ_REG = 4'b0010;

   localparam REG_MODID   = 0;
   localparam REG_VERSION = 1;   
   
   reg [3:0]    state;
   reg [9:0]    dest;
   reg [15:0]   value;
   reg [3:0]    nxt_state;
   reg [9:0]    nxt_dest;   
   reg [15:0]   nxt_value;   
   
   localparam STATE_IDLE   = 0;
   localparam STATE_PACKET = 1;
   localparam STATE_READ1  = 2;
   localparam STATE_READ2  = 3;
   localparam STATE_READ3  = 4;
   localparam STATE_READ4  = 5;
   localparam STATE_DROP   = 6;
   
   always @(posedge clk) begin
      if (rst) begin
         state <= STATE_IDLE;
      end else begin
         state <= nxt_state;
      end
      dest <= nxt_dest;
      value <= nxt_value;
   end
   
   always @(*) begin
      nxt_state = state;
      nxt_dest = dest;
      nxt_value = value;

      debug_in.ready = 0;
      debug_out.valid = 0;
      debug_out.data = 0;
      debug_out.last = 0;
      
      case (state)
        STATE_IDLE: begin
           debug_in.ready = 1;
           if (debug_in.valid) begin
              nxt_state = STATE_PACKET;
           end
        end
        STATE_PACKET: begin
           debug_in.ready = 1;
           nxt_dest = debug_in.data[0][9:0];
           
           if (debug_in.valid) begin
              if (debug_in.data[0][15:12] == REQ_READ_REG) begin
                 nxt_state = STATE_READ1;
              end else begin
                 nxt_state = STATE_DROP;
              end
           end
        end // case: STATE_PACKET
        STATE_READ1: begin
           debug_in.ready = 1;

           case (debug_in.data)
             REG_MODID: nxt_value = 16'(MODID);
             REG_VERSION: nxt_value = 16'(MODVERSION);
             default: begin
                nxt_value = 0;
                // TODO: Error
             end
           endcase // case (debug_in.data)
           
           if (debug_in.valid) begin
              if (debug_in.last) begin
                 nxt_state = STATE_READ2;
              end else begin
                 nxt_state = STATE_DROP;
              end
           end
        end // case: STATE_READ1
        STATE_READ2: begin
           debug_out.valid = 1;
           debug_out.data = {6'h0, dest};

           if (debug_out.ready) begin
              nxt_state = STATE_READ3;
           end
        end
        STATE_READ3: begin
           debug_out.valid = 1;
           debug_out.data = {6'h0, 10'(id)};
           if (debug_out.ready) begin
              nxt_state = STATE_READ4;
           end
        end
        STATE_READ4: begin
           debug_out.valid = 1;
           debug_out.data = value;
           debug_out.last = 1;
           if (debug_out.ready) begin
              nxt_state = STATE_IDLE;
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
