
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

   // a helper function to ease the assembly of interface signals
   function logic assemble (logic [15:0] m_data,
                            logic m_first,
                            logic m_last,
                            logic m_valid);
      data = m_data;
      first = m_first;
      last = m_last;
      valid = m_valid;
      return ready;
   endfunction // assemble

   
endinterface // ddi_channel


