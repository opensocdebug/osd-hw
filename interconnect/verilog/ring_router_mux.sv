
module ring_router_mux
  (
   input clk, rst,
   dii_channel.slave in_ring,
   dii_channel.slave in_local,
   dii_channel.master out
   );

   enum         { NOWORM, WORM_LOCAL, WORM_RING } state, nxt_state;
   
   always_ff @(posedge clk) begin
      if (rst) begin
         state <= NOWORM;
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
      in_ring.ready = 0;
      in_local.ready = 0;
      
      case (state)
        NOWORM: begin
           if (in_ring.valid && in_ring.first) begin
              in_ring.ready = out.ready;
              out.valid = 1;
              out.data = in_ring.data;
              out.first = in_ring.first;
              out.last = in_ring.last;

              if (!in_ring.last) begin
                 nxt_state = WORM_RING;
              end
           end else if (in_local.valid && in_local.first) begin
              in_local.ready = out.ready;
              
              out.valid = 1;
              out.data = in_local.data;
              out.first = in_local.first;
              out.last = in_local.last;

              if (!in_local.last) begin
                 nxt_state = WORM_LOCAL;
              end
           end // if (in_local.valid && in_local.first)
        end // case: NOWORM
        WORM_RING: begin
           in_ring.ready = out.ready;
           out.valid = in_ring.valid;
           out.data = in_ring.data;
           out.first = in_ring.first;
           out.last = in_ring.last;

           if (out.last & out.valid & out.ready) begin
              nxt_state = NOWORM;
           end
        end
        WORM_LOCAL: begin
           in_local.ready = out.ready;
           out.valid = in_local.valid;
           out.data = in_local.data;
           out.first = in_local.first;
           out.last = in_local.last;

           if (out.last & out.valid & out.ready) begin
              nxt_state = NOWORM;
           end
        end          
      endcase // case (state)
   end
   
endmodule // ring_router_mux
