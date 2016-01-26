
module dii_buffer
  #(parameter WIDTH=16,
    parameter SIZE=4,
    parameter FULLPACKET=0)
   (
    input clk,
    input rst,

    dii_channel.slave in,
    dii_channel.master out
    );

   // Signals for fifo
   logic [WIDTH-1:0] fifo_data [0:SIZE-1]; //actual fifo
   logic [SIZE-1:0]  fifo_first; //actual fifo
   logic [SIZE-1:0]  fifo_last; //actual fifo
   logic [WIDTH-1:0] nxt_fifo_data [0:SIZE-1];
   logic [SIZE-1:0]  nxt_fifo_first;
   logic [SIZE-1:0]  nxt_fifo_last;
   
   reg [SIZE:0]      fifo_write_ptr;
   
   logic             pop;
   logic             push;
   logic             full_packet;

   logic [SIZE-1:0]   valid;
   always_comb @(*) begin : valid_comb
      integer i;
      // Set first element
      valid[SIZE-1] = fifo_write_ptr[SIZE];
      for (i = SIZE - 2; i >= 0; i = i - 1) begin
         valid[i] = fifo_write_ptr[i+1] | valid[i+1];
      end
   end
   
   assign full_packet = |(fifo_last & valid); 

   assign pop = out.valid & out.ready;
   assign push = in.valid & in.ready;

   assign out.data = fifo_data[0][WIDTH-1:0];
   assign out.first = fifo_data[0][WIDTH+1];
   assign out.last = fifo_data[0][WIDTH];   
   assign out.valid = !FULLPACKET ? !fifo_write_ptr[0] : full_packet;

   assign in.ready = !fifo_write_ptr[SIZE];

   always @(posedge clk) begin
      if (rst) begin
         fifo_write_ptr <= {{SIZE{1'b0}},1'b1};
      end else if (push & !pop) begin
         fifo_write_ptr <= fifo_write_ptr << 1;
      end else if (!push & pop) begin
         fifo_write_ptr <= fifo_write_ptr >> 1;
      end
   end

   always @(*) begin : shift_register_comb
      integer i;
      for (i=0;i<SIZE;i=i+1) begin
         if (pop) begin
            if (push & fifo_write_ptr[i+1]) begin
               nxt_fifo_data[i] = in.data;
               nxt_fifo_first[i] = in.first;
               nxt_fifo_last[i] = in.last;
            end else if (i<SIZE-1) begin
               nxt_fifo_data[i] = fifo_data[i+1];
            end else begin
               nxt_fifo_data[i] = fifo_data[i];
            end
         end else if (push & fifo_write_ptr[i]) begin
            nxt_fifo_data[i] = in.data;
            nxt_fifo_first[i] = in.first;
            nxt_fifo_last[i] = in.last;
         end else begin
            nxt_fifo_data[i] = fifo_data[i];
         end
      end
   end

   always @(posedge clk) begin : shift_register_seq
      integer i;
      for (i=0;i<SIZE;i=i+1) begin
         fifo_data[i] <= nxt_fifo_data[i];
         fifo_first[i] <= nxt_fifo_first[i];
         fifo_last[i] <= nxt_fifo_last[i];
      end
   end
   
endmodule // dii_buffer

