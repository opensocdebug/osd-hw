
interface dii_channel;
   logic [15:0] data;
   logic        first;
   logic        last;
   logic        valid;
   logic        ready;
   
   modport master (output data,
                   output first,
                   output last,
                   output valid,
                   input  ready);

   modport slave (input  data,
                  input  first,
                  input  last,
                  input  valid,
                  output ready);
   
endinterface // ddi_channel


