
module dii_combiner
  #(parameter N = 1)
   (
    dii_channel i0, i1, i2, i3, i4, i5, i6, i7,
    dii_channel o
    );

   generate
      if(N>=1) begin
         assign i0.ready = o.ready[0];
         assign o.valid[0] = i0.valid;
         assign o.last[0] = i0.last;
         assign o.data[0] = i0.data;
      end
      if(N>=2) begin
         assign i1.ready = o.ready[1];
         assign o.valid[1] = i1.valid;
         assign o.last[1] = i1.last;
         assign o.data[1] = i1.data;
      end
      if(N>=3) begin
         assign i2.ready = o.ready[2];
         assign o.valid[2] = i2.valid;
         assign o.last[2] = i2.last;
         assign o.data[2] = i2.data;
      end
      if(N>=4) begin
         assign i3.ready = o.ready[3];
         assign o.valid[3] = i3.valid;
         assign o.last[3] = i3.last;
         assign o.data[3] = i3.data;
      end
      if(N>=5) begin
         assign i4.ready = o.ready[4];
         assign o.valid[4] = i4.valid;
         assign o.last[4] = i4.last;
         assign o.data[4] = i4.data;
      end
      if(N>=6) begin
         assign i5.ready = o.ready[5];
         assign o.valid[5] = i5.valid;
         assign o.last[5] = i5.last;
         assign o.data[5] = i5.data;
      end
      if(N>=7) begin
         assign i6.ready = o.ready[6];
         assign o.valid[6] = i6.valid;
         assign o.last[6] = i6.last;
         assign o.data[6] = i6.data;
      end
      if(N>=8) begin
         assign i7.ready = o.ready[7];
         assign o.valid[7] = i7.valid;
         assign o.last[7] = i7.last;
         assign o.data[7] = i7.data;
      end
   endgenerate

   
endmodule // dii_combiner
