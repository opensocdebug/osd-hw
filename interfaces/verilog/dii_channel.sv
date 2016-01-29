
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

   // a helper function to ease the assembly of interface signals
   function logic assemble (input logic [17:0] m,
                            input int index = 0);
      {valid[index], last[index], data[index]} = m;
      return ready[index];
   endfunction // assemble

   function logic[17:0] disassemble(input logic m_ready,
                                    input int index = 0);
      ready[index] = m_ready;
      return {valid, last, data};
   endfunction // disassemble

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

   function dii_flit get_flit(input int index = 0);
      get_flit.last = last[index];
      get_flit.data = data[index];
   endfunction // get_flit

   function void put_flit(input dii_flit d,
                          input index = 0);
      last[index] = d.last;
      data[index] = d.data;
   endfunction // put_flit
   
endinterface // ddi_channel


