
module ring_router_demux
  (
   input       clk, rst,
   input [9:0] id,
   dii_channel.slave in,
   dii_channel.master out_local,
   dii_channel.master out_ring
   );

   assign out_local.data = in.data;
   assign out_local.first = in.first;
   assign out_local.last = in.last;
   assign out_ring.data = in.data;
   assign out_ring.first = in.first;
   assign out_ring.last = in.last;

   reg         worm;
   reg         worm_local;

   logic       is_local = (in.data[9:0] == id);
   
   always_ff @(posedge clk) begin
      if (rst) begin
         worm <= 0;
         worm_local <= 1'bx;
      end else begin
         if (!worm) begin
            worm_local <= is_local;
            if (in.ready & in.valid & !in.last) begin
               worm <= 1;
            end
         end else begin
            if (in.ready & in.valid & in.last) begin
               worm <= 0;
            end
         end   
      end
   end

   logic switch_local = worm ? worm_local : is_local;
   
   assign out_ring.valid = !switch_local & in.valid;
   
   assign out_local.valid = switch_local & in.valid;
   
   assign in.ready = switch_local ? out_local.ready : out_ring.ready;

endmodule // ring_router_demux
