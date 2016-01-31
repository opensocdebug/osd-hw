
module dii_divider
  #(parameter N = 1)
   (
    dii_channel i,
    dii_channel o0, o1, o2, o3, o4, o5, o6, o7
    );

   generate
      if(N>=1) begin
         assign i.ready[0] = o0.ready;
         assign o0.valid = i.valid[0];
         assign o0.last = i.last[0];
         assign o0.data = i.data[0];
      end
      if(N>=2) begin
         assign i.ready[1] = o1.ready;
         assign o1.valid = i.valid[1];
         assign o1.last = i.last[1];
         assign o1.data = i.data[1];
      end
      if(N>=3) begin
         assign i.ready[2] = o2.ready;
         assign o2.valid = i.valid[2];
         assign o2.last = i.last[2];
         assign o2.data = i.data[2];
      end
      if(N>=4) begin
         assign i.ready[3] = o3.ready;
         assign o3.valid = i.valid[3];
         assign o3.last = i.last[3];
         assign o3.data = i.data[3];
      end
      if(N>=5) begin
         assign i.ready[4] = o4.ready;
         assign o4.valid = i.valid[4];
         assign o4.last = i.last[4];
         assign o4.data = i.data[4];
      end
      if(N>=6) begin
         assign i.ready[5] = o5.ready;
         assign o5.valid = i.valid[5];
         assign o5.last = i.last[5];
         assign o5.data = i.data[5];
      end
      if(N>=7) begin
         assign i.ready[6] = o6.ready;
         assign o6.valid = i.valid[6];
         assign o6.last = i.last[6];
         assign o6.data = i.data[6];
      end
      if(N>=8) begin
         assign i.ready[7] = o7.ready;
         assign o7.valid = i.valid[7];
         assign o7.last = i.last[7];
         assign o7.data = i.data[7];
      end
   endgenerate

endmodule // dii_divider
