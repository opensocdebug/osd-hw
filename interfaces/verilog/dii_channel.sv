
package dii_package;

   typedef struct packed unsigned {
      logic       valid;
      logic       last;
      logic [15:0] data;
   } dii_flit;

   function dii_flit
     dii_flit_assemble(
                       logic m_valid,
                       logic m_last,
                       logic m_data
                       );
      dii_flit_assemble.valid = m_valid;
      dii_flit_assemble.last = m_last;
      dii_flit_assemble.data = m_data;
   endfunction // dii_flit_assemble

endpackage // dii_package

