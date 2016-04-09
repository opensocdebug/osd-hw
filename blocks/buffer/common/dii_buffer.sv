
import dii_package::dii_flit;
import dii_package::dii_flit_assemble;

module dii_buffer
  #(
    parameter BUF_SIZE = 4,                     // length of the buffer
    parameter FULLPACKET = 0
    )
   (
    input                               clk, rst,
    output logic [$clog2(BUF_SIZE):0]   packet_size,

    input  dii_flit                     flit_in,
    output                              flit_in_ready,
    output dii_flit                     flit_out,
    input                               flit_out_ready
     );
   

   localparam ID_W = $clog2(BUF_SIZE); // the width of the index

   // internal shift register
   dii_flit [BUF_SIZE-1:0]   data;
   reg [ID_W:0]              rp; // read pointer
   logic                     reg_out_valid;  // local output valid
   logic                     flit_in_fire, flit_out_fire;

   assign flit_in_ready = (rp != BUF_SIZE - 1) || !reg_out_valid;
   assign flit_in_fire = flit_in.valid && flit_in_ready;
   assign flit_out_fire = flit_out.valid && flit_out_ready;

   always_ff @(posedge clk)
     if(rst)
       reg_out_valid <= 0;
     else if(flit_in.valid)
       reg_out_valid <= 1;
     else if(flit_out_ready && rp == 0)
       reg_out_valid <= 0;

   always_ff @(posedge clk)
     if(rst)
       rp <= 0;
     else if(flit_in_fire && !flit_out_fire && reg_out_valid)
       rp <= rp + 1;
     else if(flit_out_fire && !flit_in_fire && rp != 0)
       rp <= rp - 1;

   always @(posedge clk)
     if(flit_in_fire)
       data <= {data, flit_in};

   generate                     // SRL does not allow parallel read
      if(FULLPACKET != 0) begin
         logic [BUF_SIZE-1:0] data_last_buf;

         always @(posedge clk)
           if(rst)
             data_last_buf = 0;
           else begin
              if(flit_out_fire)
                data_last_buf[rp] = 1'b0;
              if(flit_in_fire)
                data_last_buf = {data_last_buf, flit_in.last && flit_in.valid};
           end

         // extra logic to get the packet size in a stable manner
         logic [BUF_SIZE:0] data_last_shifted;
         assign data_last_shifted = {1'b0,data_last_buf} << BUF_SIZE - rp;

         function logic [ID_W:0] find_first_one(input logic [BUF_SIZE:0] data);
            automatic int i;
            for(i=BUF_SIZE; i>0; i--)
              if(data[i]) return i;
            return BUF_SIZE;
         endfunction // size_count

         assign packet_size = BUF_SIZE + 1 - find_first_one(data_last_shifted);
         assign flit_out = dii_flit_assemble(|data_last_buf, data[rp].last, data[rp].data);
      end else begin // if (FULLPACKET)
         assign packet_size = 0;
         assign flit_out = dii_flit_assemble(reg_out_valid, data[rp].last, data[rp].data);
      end
   endgenerate

endmodule // dii_buffer
