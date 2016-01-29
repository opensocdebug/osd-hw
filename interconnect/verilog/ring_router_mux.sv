
module ring_router_mux
  (
   input clk, rst,
   dii_channel in_ring,
   dii_channel in_local,
   dii_channel out
   );

   enum         { NOWORM, WORM_LOCAL, WORM_RING } state, nxt_state;
   
   always_ff @(posedge clk) begin
      if (rst) begin
         state <= NOWORM;
      end else begin
         state <= nxt_state;
      end
   end

   always_comb begin
      nxt_state = state;
      out.valid = 0;
      out.data = 'x;
      out.last = 'x;
      in_ring.ready = 0;
      in_local.ready = 0;
      
      case (state)
        NOWORM: begin
           if (in_ring.valid) begin
              in_ring.ready = out.assemble({1'b1, in_ring.last, in_ring.data});

              if (!in_ring.last) begin
                 nxt_state = WORM_RING;
              end
           end else if (in_local.valid) begin
              in_local.ready = out.assemble({1'b1, in_local.last, in_local.data});

              if (!in_local.last) begin
                 nxt_state = WORM_LOCAL;
              end
           end // if (in_local.valid)
        end // case: NOWORM
        WORM_RING: begin
           in_ring.ready = out.assemble({in_ring.valid, in_ring.last, in_ring.data});

           if (out.last & out.valid & out.ready) begin
              nxt_state = NOWORM;
           end
        end
        WORM_LOCAL: begin
           in_local.ready = out.assemble({in_local.valid, in_local.last, in_local.data});

           if (out.last & out.valid & out.ready) begin
              nxt_state = NOWORM;
           end
        end          
      endcase // case (state)
   end
   
endmodule // ring_router_mux
