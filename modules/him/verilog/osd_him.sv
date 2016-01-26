
module osd_him
  (input clk, rst,
   glip_channel.slave glip_in,
   glip_channel.master glip_out,

   dii_channel.master dii_out,
   dii_channel.slave dii_in);

   logic ingress_active;
   logic ingress_first;
   logic [4:0] ingress_size;

   logic [15:0] ingress_data_be;
   assign ingress_data_be[7:0] = glip_in.data[15:8];
   assign ingress_data_be[15:8] = glip_in.data[7:0];

   assign glip_in.ready = !ingress_active | dii_out.ready;
   assign dii_out.data  = ingress_data_be;
   assign dii_out.valid = ingress_active & glip_in.valid;
   assign dii_out.first = ingress_active & ingress_first;
   assign dii_out.last  = ingress_active & (ingress_size == 0);

   always @(posedge clk) begin
      if (rst) begin
         ingress_active <= 0;
      end else begin
         if (!ingress_active) begin
            ingress_first <= 1;
            if (glip_in.valid & glip_in.ready) begin
               ingress_size <= ingress_data_be[4:0] - 1;
               ingress_active <= 1;
            end
         end else begin
            if (glip_in.valid & glip_in.ready) begin
               ingress_size <= ingress_size - 1;
               ingress_first <= 0;
               if (ingress_size == 0) begin
                  ingress_active <= 0;
               end
            end
         end
      end
   end
   
   
endmodule // osd_him

