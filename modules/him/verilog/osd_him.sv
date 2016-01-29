
module osd_him
  (input clk, rst,
   glip_channel glip_in,
   glip_channel glip_out,

   dii_channel dii_out,
   dii_channel dii_in);

   localparam BUF_SIZE = 8;

   logic ingress_active;
   logic [4:0] ingress_size;

   logic [15:0] ingress_data_be;
   assign ingress_data_be[7:0] = glip_in.data[15:8];
   assign ingress_data_be[15:8] = glip_in.data[7:0];

   assign glip_in.ready = !ingress_active | dii_out.ready;
   assign dii_out.data  = ingress_data_be;
   assign dii_out.valid = ingress_active & glip_in.valid;
   assign dii_out.last  = ingress_active & (ingress_size == 0);

   always @(posedge clk) begin
      if (rst) begin
         ingress_active <= 0;
      end else begin
         if (!ingress_active) begin
            if (glip_in.valid & glip_in.ready) begin
               ingress_size <= ingress_data_be[4:0] - 1;
               ingress_active <= 1;
            end
         end else begin
            if (glip_in.valid & glip_in.ready) begin
               ingress_size <= ingress_size - 1;
               if (ingress_size == 0) begin
                  ingress_active <= 0;
               end
            end
         end
      end
   end

   dii_channel dii_egress();
   logic [$clog2(BUF_SIZE)-1:0] egress_packet_size;

   logic       egress_active;

   logic [15:0] egress_data_be;
   assign egress_data_be = !egress_active ? {11'h0, egress_packet_size} : dii_egress.data;

   assign glip_out.data = {egress_data_be[7:0], egress_data_be[15:8]};
   assign glip_out.valid = dii_egress.valid;
   assign dii_egress.ready = egress_active & glip_out.ready;

   always @(posedge clk) begin
      if (rst) begin
         egress_active <= 0;
      end else begin
         if (!egress_active) begin
            if (dii_egress.valid & glip_out.ready) begin
               egress_active <= 1;
            end
         end else begin 
            if (dii_egress.ready & dii_egress.last) begin
               egress_active <= 0;
            end
         end
      end
   end
   
   dii_buffer
     #(.SIZE(BUF_SIZE), .FULLPACKET(1))
   u_egress_buffer(.*,
                   .packet_size (egress_packet_size),
                   .in (dii_in),
                   .out (dii_egress));
   
   
endmodule // osd_him

