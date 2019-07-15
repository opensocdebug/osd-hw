// Copyright 2016 by the authors
//
// Copyright and related rights are licensed under the Solderpad
// Hardware License, Version 0.51 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a
// copy of the License at http://solderpad.org/licenses/SHL-0.51.
// Unless required by applicable law or agreed to in writing,
// software, hardware and materials distributed under this License is
// distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the
// License.
//
// Authors:
//    Stefan Wallentowitz <stefan@wallentowitz.de>

/* NOTE: This is a WiP!
 * 
 * A couple of important points about the current state of the FIFO
 * implementation.
 * 
 * 1. The ordering of any data musn't ever change. No data may be lost.
 * 
 * 2. We have to be able to receive 2 chars (16-bit) in a single cycle to
 *    avoid unnecessary stalling of the DI.
 *    
 * 3. The bus side is only capable of sending/receiving one char (8-bit) at a time.
 * 
 * -> We therefore need a buffering mechanism to convert between 8-bit & 16-bit width
 * 
 * 4. If the osd_event_packetization module is used to create outgoing
 *    DI packets, we have to know exactly how many chars (8-bit) we want
 *    to send when event_available is asserted.
 * 
 * 5. If some sort of out_char_bypass is used to buffer outgoing chars (8-bit)
 *    before they enter they FIFO or get sent over the DI, access to it must be synchronized.
 *    
 * As of my current knowledge, it seems the best way to address all these issues would be to
 * make use of 2 8-bit Buffer for each direction (4 in total). Whenever only a single char is received,
 * the MSB-LSB ordering of the 2 8-bit buffers is swapped, so that any follow up data won't leave an
 * 8-bit gap in the buffer (like a 16-bit buffer would do). The new type of FIFO could be packaged into
 * a new module nicely, see the comment below for more.
 **/

import dii_package::dii_flit;

module osd_dem_uart
  (input clk, rst,

   input            dii_flit debug_in, output debug_in_ready,
   output           dii_flit debug_out, input debug_out_ready,

   input [15:0]     id,

   output           drop,

   input [7:0]      out_char,
   input            out_valid,
   output reg       out_ready,

   output reg [7:0] in_char,
   output reg       in_valid,
   input            in_ready
   );

   localparam TYPE_EVENT          = 2'b10;
   localparam TYPE_SUB_EVENT_LAST = 4'b0000;

   logic         stall;
   assign drop = stall;

   dii_flit     c_uart_out, c_uart_in;
   logic        c_uart_out_ready, c_uart_in_ready;

   reg [15:0]   event_dest;
   reg [7:0]    out_char_buf;

   osd_regaccess_layer
     #(.MOD_VENDOR(16'h1), .MOD_TYPE(16'h2), .MOD_VERSION(16'h0),
       .MAX_REG_SIZE(16), .CAN_STALL(1), .MOD_EVENT_DEST_DEFAULT(16'h0))
   u_regaccess(.clk (clk), .rst (rst), .id (id),
               .debug_in (debug_in),
               .debug_in_ready (debug_in_ready),
               .debug_out (debug_out),
               .debug_out_ready (debug_out_ready),
               .module_in (c_uart_out),
               .module_in_ready (c_uart_out_ready),
               .module_out (c_uart_in),
               .module_out_ready (c_uart_in_ready),
               .stall (stall),
               .event_dest(event_dest),
               .reg_request (),
               .reg_write (),
               .reg_addr (),
               .reg_size (),
               .reg_wdata (),
               .reg_ack (1'b0),
               .reg_err (1'b0),
               .reg_rdata (16'h0));

   // ---------------------------------------------------------------
   logic [2:0]    mod_type_sub;
   logic          event_available;
   logic          event_consumed;
   reg   [3:0]    data_num_words;
   logic          data_reg_idx;
   logic          data_reg_valid;
   logic [15:0]   data;

   osd_event_packetization
      #(.MAX_PKT_LEN(1), .MAX_DATA_NUM_WORDS(16))
   u_event_packetization(.clk(clk), .rst(rst),
                         .debug_out(c_uart_out),
                         .debug_out_ready(c_uart_out_ready),
                         .id(id),
                         .dest(event_dest),
                         .overflow(1'b0),
                         .mod_type_sub(mod_type_sub),
                         .event_available(event_available),
                         .event_consumed(event_consumed),
                         .data_num_words(data_num_words),
                         .data_reg_idx(data_reg_idx),
                         .data_reg_valid(data_reg_valid),
                         .data(data));

/* The entire tx/rx FIFO-logic could/should be a new module 'osd_dem_uart_fifo'
 * that wraps 2 (or 4) fwft-FIFO and allows for 8 or 16 bit reads/writes.
 * Internally the module should take care of swapping MSB & LSB whenever
 * only 8 bit are written/read. The interface to the outside would be almost
 * identical to a standard FIFO, except for a read_single_char & write_single_char
 * input flag.
 **/
      
// ------------------------ TX LOGIC ---------------------------------
   logic tx_fifo0_din;
   logic tx_fifo0_wr_en;
   logic tx_fifo0_full;
   logic tx_fifo0_dout;
   logic tx_fifo0_rd_en;
   logic tx_fifo0_empty;
   logic tx_fifo0_count;
   logic tx_fifo1_din;
   logic tx_fifo1_wr_en;
   logic tx_fifo1_full;
   logic tx_fifo1_dout;
   logic tx_fifo1_rd_en;
   logic tx_fifo1_empty;
   logic tx_fifo1_count;

   fifo_singleclock_fwft
      #(.WIDTH(16), .DEPTH(16))
   u_tx_fifo0(.clk(clk), .rst(rst),
             .din(tx_fifo0_din),
             .wr_en(tx_fifo0_wr_en),
             .full(tx_fifo0_full),
             .prog_full(),
             .dout(tx_fifo0_dout),
             .rd_en(tx_fifo0_rd_en),
             .empty(tx_fifo0_empty),
             .count(tx_fifo0_count));

   fifo_singleclock_fwft
      #(.WIDTH(16), .DEPTH(16))
   u_tx_fifo1(.clk(clk), .rst(rst),
             .din(tx_fifo1_din),
             .wr_en(tx_fifo1_wr_en),
             .full(tx_fifo1_full),
             .prog_full(),
             .dout(tx_fifo1_dout),
             .rd_en(tx_fifo1_rd_en),
             .empty(tx_fifo1_empty),
             .count(tx_fifo1_count));
   
   // 0 = fifo0, 1 = fifo1
	logic tx_fifo_select, nxt_tx_fifo_select;
   logic tx_fifo_select1, nxt_tx_fifo_select1;

   enum {STATE_IDLE, STATE_DELAY, STATE_XFER}
         tx_state, nxt_tx_state;

   always @(posedge clk) begin
      if (rst) begin
         tx_fifo_select <= 1'b0;
         tx_fifo_select <= 1'b0;
         tx_state <= STATE_IDLE;
      end else begin
			tx_fifo_select <= nxt_tx_fifo_select;
			tx_fifo_select1 <= nxt_tx_fifo_select1;
			tx_state <= nxt_tx_state;
      end
   end
   
   reg tx_delay_couter;
   reg last;

   always_comb begin
      tx_fifo0_din   = 8'h0;
      tx_fifo0_wr_en = 1'b0;
      tx_fifo1_din   = 8'h0;
      tx_fifo1_wr_en = 1'b0;
      out_ready      = 1'b0;

		if (tx_fifo_select) begin
         tx_fifo0_din   = out_char;
         tx_fifo0_wr_en = out_valid;
         out_ready = !tx_fifo0_full;
         if (out_valid & out_ready) begin
            nxt_tx_fifo_select = 1'b0;
         end
		end else begin
		   tx_fifo1_din   = out_char;
         tx_fifo1_wr_en = out_valid;
         out_ready = !tx_fifo1_full;
         if (out_valid & out_ready) begin
            nxt_tx_fifo_select = 1'b1;
         end
		end
		
		case (tx_state)
		   STATE_IDLE:
		      if (!tx_fifo01_empty) begin
		         nxt_tx_state = STATE_DELAY;
		      end
		   end
		   STATE_DELAY:
		      // TODO: Magic numbers
		      if (tx_delay_couter > 20 | tx_fifo01_count > 8) begin
		         event_available = 1'b1;
		         nxt_tx_state = STATE_XFER;
		         data_num_words = (tx_fifo0_count + tx_fifo1_count) / 2;
		         mod_type_sub = {(tx_fifo0_count == tx_fifo1_count), 2'b00};
		      end else begin
		         tx_delay_couter = tx_delay_couter + 1;
            end
		   end
		   STATE_XFER:
		      if (data_reg_valid) begin
               // TODO: Properly send data_num_words chars using the osd_event_packetization module.
		         // XXX: Current data_word_idx + nxt
		         // XXX: We need a tx_fifo_select1
		      end

		      if (event_consumed) begin
		         nxt_tx_state = STATE_IDLE;
		      end
         end
      endcase
   end
// ------------------------- TX LOGIC END -------------------------


// ------------------------- RX LOGIC -----------------------------
   logic rx_fifo0_din;
   logic rx_fifo0_wr_en;
   logic rx_fifo0_full;
   logic rx_fifo0_dout;
   logic rx_fifo0_rd_en;
   logic rx_fifo0_empty;
   logic rx_fifo0_count;
   logic rx_fifo1_din;
   logic rx_fifo1_wr_en;
   logic rx_fifo1_full;
   logic rx_fifo1_dout;
   logic rx_fifo1_rd_en;
   logic rx_fifo1_empty;
   logic rx_fifo1_count;

   fifo_singleclock_fwft
      #(.WIDTH(16), .DEPTH(16))
   u_rx_fifo0(.clk(clk), .rst(rst),
             .din(rx_fifo0_din),
             .wr_en(rx_fifo0_wr_en),
             .full(rx_fifo0_full),
             .prog_full(),
             .dout(rx_fifo0_dout),
             .rd_en(rx_fifo0_rd_en),
             .empty(rx_fifo0_empty),
             .count(rx_fifo0_count));

   fifo_singleclock_fwft
      #(.WIDTH(16), .DEPTH(16))
   u_rx_fifo1(.clk(clk), .rst(rst),
             .din(rx_fifo1_din),
             .wr_en(rx_fifo1_wr_en),
             .full(rx_fifo1_full),
             .prog_full(),
             .dout(rx_fifo1_dout),
             .rd_en(rx_fifo1_rd_en),
             .empty(rx_fifo1_empty),
             .count(rx_fifo1_count));

   logic rx_fifo_select, nxt_rx_fifo_select;
   logic rx_fifo_select1, nxt_rx_fifo_select1;

   enum         { STATE_IDLE, STATE_HDR_SRC, STATE_HDR_FLAGS,
                  STATE_XFER } rx_state, nxt_rx_state;

   always @(posedge clk) begin
      if (rst) begin
         rx_fifo_select <= 1'b0;
         rx_fifo_select1 <= 1'b0;
         rx_state <= STATE_IDLE;
      end else begin
         rx_fifo_select <= nxt_rx_fifo_select;
         rx_fifo_select1 <= nxt_rx_fifo_select1;
         rx_state <= nxt_rx_state;
      end
   end

   reg is_single_char;

   always_comb begin
      in_char  = 8'h0;
      in_valid = 1'b0;
      
      if (rx_fifo_select) begin
         in_char  = rx_fifo0_dout;
         in_valid = !rx_fifo0_empty;
         rx_fifo0_rd_en = in_ready;
         if (in_valid & in_ready) begin
            nxt_rx_fifo_select = 1'b0;
         end
      end else begin
         in_char  = rx_fifo1_dout;
         in_valid = !rx_fifo1_empty;
         rx_fifo1_rd_en = in_ready;
         if (in_valid & in_ready) begin
            nxt_rx_fifo_select = 1'b01;
         end
      end

      c_uart_in_ready = 0;
      nxt_rx_fifo_select = 1'b0;
      rx_fifo0_wr_en = 1'b0;
      rx_fifo0_din = 8'h0;
      rx_fifo1_wr_en = 1'b0;
      rx_fifo1_din = 8'h0;

      case (rx_state)
         STATE_IDLE: begin
            c_uart_in_ready = 1;
            if (c_uart_in.valid) begin
               nxt_rx_state = STATE_HDR_SRC;
            end
         end
         STATE_HDR_SRC: begin
            c_uart_in_ready = 1;
            if (c_uart_in.valid) begin
               nxt_rx_state = STATE_HDR_FLAGS;
            end
         end
         STATE_HDR_FLAGS: begin
            c_uart_in_ready = 1;
            is_single_char  = c_uart_in.data[12];   // XXX: Choose correct bit
            if (c_uart_in.valid) begin
               nxt_rx_state = STATE_XFER;
            end
         end
         STATE_XFER: begin
            // XXX: Simplify this block
            if (c_uart_in.last) begin
               if (is_single_char) begin
                  if (rx_fifo_select1) begin
                     c_uart_in_ready = !rx_fifo1_full;
                     
                     rx_fifo1_wr_en = c_uart_in.valid;
                     rx_fifo1_din = c_uart_in.data[7:0];
                     nxt_rx_fifo_select1 = 1'b0;
                  end else begin
                     c_uart_in_ready = !rx_fifo0_full;
                     
                     rx_fifo0_wr_en = c_uart_in.valid;
                     rx_fifo0_din = c_uart_in.data[7:0];
                     nxt_rx_fifo_select1 = 1'b1;
                  end
               end else begin
                  if (rx_fifo_select1) begin
                     c_uart_in_ready = !rx_fifo0_full & !rx_fifo1_full;
                     
                     rx_fifo0_wr_en = c_uart_in.valid;
                     rx_fifo0_din = c_uart_in.data[15:8];
                     rx_fifo1_wr_en = c_uart_in.valid;
                     rx_fifo1_din = c_uart_in.data[7:0];
                  end else begin
                     c_uart_in_ready = !rx_fifo0_full & !rx_fifo1_full;
                     
                     rx_fifo0_wr_en = c_uart_in.valid;
                     rx_fifo0_din = c_uart_in.data[7:0];
                     rx_fifo1_wr_en = c_uart_in.valid;
                     rx_fifo1_din = c_uart_in.data[15:8];
                  end
               end
            end else begin
               if (rx_fifo_select1) begin
                  c_uart_in_ready = !rx_fifo0_full & !rx_fifo1_full;
                  
                  rx_fifo0_wr_en = c_uart_in.valid;
                  rx_fifo0_din = c_uart_in.data[15:8];
                  rx_fifo1_wr_en = c_uart_in.valid;
                  rx_fifo1_din = c_uart_in.data[7:0];
               end else begin
                  c_uart_in_ready = !rx_fifo0_full & !rx_fifo1_full;
                  
                  rx_fifo0_wr_en = c_uart_in.valid;
                  rx_fifo0_din = c_uart_in.data[7:0];
                  rx_fifo1_wr_en = c_uart_in.valid;
                  rx_fifo1_din = c_uart_in.data[15:8];
               end
            end
         
            if (c_uart_in.valid && c_uart_in.last) begin
               nxt_rx_state = STATE_IDLE;
            end
         end
      endcase
   end
// ------------------------ RX LOGIC END ---------------------------

// ---------------------- OLD CODE ---------------------------------
// The previous implementation without any FIFOs or the osd_event_packetization module.
   enum         { STATE_IDLE, STATE_HDR_DEST, STATE_HDR_SRC, STATE_HDR_FLAGS,
                  STATE_XFER } state_rx;

   always @(posedge clk) begin
      if (rst) begin
         state_tx <= STATE_IDLE;
         state_rx <= STATE_IDLE;
      end else begin
         case (state_tx)
           STATE_IDLE: begin
              if (out_valid & !stall) begin
                 state_tx <= STATE_HDR_DEST;
                 out_char_buf <= out_char;
              end
           end
           STATE_HDR_DEST: begin
              if (c_uart_out_ready) begin
                 state_tx <= STATE_HDR_SRC;
              end
           end
           STATE_HDR_SRC: begin
              if (c_uart_out_ready) begin
                 state_tx <= STATE_HDR_FLAGS;
              end
           end
           STATE_HDR_FLAGS: begin
              if (c_uart_out_ready) begin
                 state_tx <= STATE_XFER;
              end
           end
           STATE_XFER: begin
              if (c_uart_out_ready) begin
                 state_tx <= STATE_IDLE;
              end
           end
         endcase

         case (state_rx)
           STATE_IDLE: begin
              if (c_uart_in.valid) begin
                 state_rx <= STATE_HDR_SRC;
              end
           end
           STATE_HDR_SRC: begin
              if (c_uart_in.valid) begin
                 state_rx <= STATE_HDR_FLAGS;
              end
           end
           STATE_HDR_FLAGS: begin
              if (c_uart_in.valid) begin
                 state_rx <= STATE_XFER;
              end
           end
           STATE_XFER: begin
              if (c_uart_in.valid & in_ready) begin
                 state_rx <= STATE_IDLE;
              end
           end
         endcase
      end
   end

   always_comb begin
      c_uart_out.valid = 0;
      c_uart_out.last = 0;
      c_uart_out.data = 16'h0;
      out_ready = 0;

      case (state_tx)
        STATE_IDLE: begin
           out_ready = !stall;
        end
        STATE_HDR_DEST: begin
           c_uart_out.valid = 1;
           c_uart_out.data = event_dest;
        end
        STATE_HDR_SRC: begin
           c_uart_out.valid = 1;
           c_uart_out.data = id;
        end
        STATE_HDR_FLAGS: begin
           c_uart_out.valid = 1;
           c_uart_out.data = {TYPE_EVENT, TYPE_SUB_EVENT_LAST, 10'h0};
        end
        STATE_XFER: begin
           c_uart_out.valid = 1;
           c_uart_out.data = {8'h0, out_char_buf};
           c_uart_out.last = 1;
        end
      endcase

      c_uart_in_ready = 0;
      in_valid = 0;
      in_char = 8'h0;

      case (state_rx)
        STATE_IDLE: begin
           c_uart_in_ready = 1;
        end
        STATE_HDR_SRC: begin
           c_uart_in_ready = 1;
        end
        STATE_HDR_FLAGS: begin
           c_uart_in_ready = 1;
        end
        STATE_XFER: begin
           c_uart_in_ready = in_ready;
           in_valid = c_uart_in.valid;
           in_char = c_uart_in.data[7:0];
        end
      endcase
   end

endmodule // osd_dem_uart
