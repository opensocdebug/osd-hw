// Copyright 2016 by the authors
//
// Copyright and related rights are licensed under the Solderpad
// Hardware License, Version 0.51 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a
// copy of the License at http://solderpad.org/licenses/SHL-0.51.
// Unless required by applicable law or agreed to in writing,
// software, hardware and materials distributed under this License is
// distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the
// License.
//
// Authors:
//    Stefan Wallentowitz <stefan@wallentowitz.de>

import dii_package::dii_flit;
import opensocdebug::mor1kx_trace_exec;

module osd_stm_mor1kx
   (
    input                        clk, rst,

    input [9:0]                  id,

    input  dii_flit              debug_in,
    output                       debug_in_ready,
    output dii_flit              debug_out,
    input                        debug_out_ready,

    input mor1kx_trace_exec      trace_port
    );

   localparam XLEN = 64;
   localparam REG_ADDR_WIDTH = 5;

   logic                         trace_valid;
   logic [15:0]                  trace_id;
   logic [XLEN-1:0]              trace_value;

   logic                         trace_reg_enable;
   logic [REG_ADDR_WIDTH-1:0]    trace_reg_addr;

   osd_stm
     #(.REG_ADDR_WIDTH(REG_ADDR_WIDTH), .XLEN(XLEN))
   u_stm
     (.*);


endmodule // osd_stm_mor1kx
