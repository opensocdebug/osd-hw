
package dii_package;

   typedef struct packed unsigned {
      logic       valid;
      logic       last;
      logic [15:0] data;
   } dii_flit;

endpackage // dii_package

