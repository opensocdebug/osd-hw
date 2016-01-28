
interface dii_channel
  #(parameter N = 1);
   logic [N-1:0][15:0] data;
   logic [N-1:0]       first;
   logic [N-1:0]       last;
   logic [N-1:0]       valid;
   logic [N-1:0]       ready;
   
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

   // a helper function to ease the assembly of interface signals
   function logic assemble (input logic [15:0] m_data,
                            input logic m_first,
                            input logic m_last,
                            input logic m_valid,
                            input int index = 0);
      data[index] = m_data;
      first[index] = m_first;
      last[index] = m_last;
      valid[index] = m_valid;
      return ready[index];
   endfunction // assemble

   
endinterface // ddi_channel


