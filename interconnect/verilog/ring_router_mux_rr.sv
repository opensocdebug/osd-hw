
module ring_router_mux_rr
  (
   input clk, rst,
   dii_channel.slave in0,
   dii_channel.slave in1,
   dii_channel.master out
   );

   enum         { NOWORM0, NOWORM1, WORM0, WORM1 } state, nxt_state;
   
   always_ff @(posedge clk) begin
      if (rst) begin
         state <= NOWORM0;
      end else begin
         state <= nxt_state;
      end
   end

   always_comb @(*) begin
      nxt_state = state;
      out.valid = 0;
      out.data = 'x;
      out.first = 'x;
      out.last = 'x;
      in0.ready = 0;
      in1.ready = 0;
      
      case (state)
        NOWORM0: begin
           if (in0.valid && in0.first) begin
              in0.ready = out.ready;
              out.valid = 1;
              out.data = in0.data;
              out.first = in0.first;
              out.last = in0.last;

              if (!in0.last) begin
                 nxt_state = WORM0;
              end
           end else if (in1.valid && in1.first) begin
              in1.ready = out.ready;
              out.valid = 1;
              out.data = in1.data;
              out.first = in1.first;
              out.last = in1.last;

              if (!in1.last) begin
                 nxt_state = WORM1;
              end
           end
        end
        NOWORM1: begin
           if (in1.valid && in1.first) begin
              in1.ready = out.ready;
              out.valid = 1;
              out.data = in1.data;
              out.first = in1.first;
              out.last = in1.last;

              if (!in1.last) begin
                 nxt_state = WORM1;
              end
           end else if (in0.valid && in0.first) begin
              in0.ready = out.ready;
              out.valid = 1;
              out.data = in0.data;
              out.first = in0.first;
              out.last = in0.last;

              if (!in0.last) begin
                 nxt_state = WORM0;
              end
           end
        end
        WORM0: begin
           in0.ready = out.ready;
           out.valid = in0.valid;
           out.data = in0.data;
           out.first = in0.first;
           out.last = in0.last;

           if (out.last & out.valid & out.ready) begin
              nxt_state = NOWORM1;
           end
        end
        WORM1: begin
           in1.ready = out.ready;
           out.valid = in1.valid;
           out.data = in1.data;
           out.first = in1.first;
           out.last = in1.last;

           if (out.last & out.valid & out.ready) begin
              nxt_state = NOWORM0;
           end
        end          
      endcase // case (state)
   end
   
endmodule // ring_router_mux
