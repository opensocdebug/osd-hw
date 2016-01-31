
typedef struct {
   logic        last;
   logic [15:0] data;
} dii_flit;

interface dii_channel
  #(parameter N = 1);
   logic [N-1:0]       valid;
   logic [N-1:0]       last;
   logic [N-1:0][15:0] data;
   logic [N-1:0]       ready;
   
   modport master (output data,
                   output last,
                   output valid,
                   input  ready);

   modport slave (input  data,
                  input  last,
                  input  valid,
                  output ready);

   function logic assemble_up (input logic [17:0] m_down,
                               input int index = 0);
      data[index] = m_down[15:0];
      last[index] = m_down[16];
      valid[index] = m_down[17];
      return ready[index];
   endfunction // assemble_up

   function logic [17:0] assemble_down (input logic m_up,
                                        input int index = 0);
      ready[index] = m_up;
      return {valid, last, data};
   endfunction // assemble_down

endinterface // ddi_channel


