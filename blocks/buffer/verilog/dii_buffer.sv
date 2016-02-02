
import dii_package::dii_flit;
import dii_package::dii_flit_assemble;

module dii_buffer
  #(
    parameter BUF_SIZE = 4,                     // length of the buffer
    parameter FULLPACKET = 0
    )
   (
    input                               clk, rst,
    output logic [$clog2(BUF_SIZE)-1:0] packet_size,

    input  dii_flit                     flit_in,
    output reg                          flit_in_ready,
    output dii_flit                     flit_out,
    input                               flit_out_ready
     );
   

   localparam ID_W = $clog2(BUF_SIZE); // the width of the index

   // internal shift register
   dii_flit [BUF_SIZE-1:0]   data;
   reg [ID_W:0]              rp; // read pointer
   logic                     reg_out_valid;  // local output valid

   assign flit_in_ready = (rp != BUF_SIZE - 1) || !reg_out_valid;

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
     else if(flit_in.valid && flit_in_ready && (!flit_out.valid || !flit_out_ready) && reg_out_valid)
       rp <= rp + 1;
     else if(flit_out.valid && flit_out_ready && (!flit_in.valid  || !flit_in_ready) && rp != 0)
       rp <= rp - 1;

   always @(posedge clk)
     if(flit_in.valid && flit_in_ready)
       data <= {data, flit_in};

   generate                     // SRL does not allow parallel read
      if(FULLPACKET) begin
         logic [BUF_SIZE-1:0] data_last_buf;

         always @(posedge clk)
           if(rst)
             data_last_buf <= 0;
           else if(flit_in.valid && flit_in_ready)
             data_last_buf <= {data_last_buf, flit_in.last && flit_in.valid};

         // Calculate packet size
         function int count_first(input logic [BUF_SIZE-1:0] data);
            int i;
            for(i=0; i<BUF_SIZE; i++)
              if(data[i])
                return i+1;
         endfunction // count_first

         assign packet_size = count_first(data_last_buf);
         assign flit_out = dii_flit_assemble(|data_last_buf, data[rp].last, data[rp].data);

      end else begin // if (FULLPACKET)
         assign packet_size = 0;
         assign flit_out = dii_flit_assemble(reg_out_valid, data[rp].last, data[rp].data);
      end
   endgenerate

endmodule // dii_buffer

