////////////////////////////////////////////////////////////////////////////////
//                                            __ _      _     _               //
//                                           / _(_)    | |   | |              //
//                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              //
//               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              //
//              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              //
//               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              //
//                  | |                                                       //
//                  |_|                                                       //
//                                                                            //
//                                                                            //
//              MPSoC-RISCV CPU                                               //
//              Master Slave Interface Tesbench                               //
//              Wishbone Bus Interface                                        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2018-2019 by the author(s)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
////////////////////////////////////////////////////////////////////////////////
// Author(s):
//   Paco Reina Campo <pacoreinacampo@queenfield.tech>

module peripheral_gpio_synthesis #(
  parameter WB_DATA_WIDTH         = 32,
  parameter WB_ADDR_WIDTH         = 8,
  parameter GPIO_WIDTH            = 32,
  parameter USE_IO_PAD_CLK        = "DISABLED",
  parameter REGISTER_GPIO_OUTPUTS = "DISABLED",
  parameter REGISTER_GPIO_INPUTS  = "DISABLED"
) (
  input clk,
  input rst,

  // WISHBONE interface
  input                      wb_cyc_i,  // cycle valid input
  input  [WB_ADDR_WIDTH-1:0] wb_adr_i,  // address bus inputs
  input  [WB_DATA_WIDTH-1:0] wb_dat_i,  // input data bus
  input  [              3:0] wb_sel_i,  // byte select inputs
  input                      wb_we_i,   // indicates write transfer
  input                      wb_stb_i,  // strobe input
  output [WB_DATA_WIDTH-1:0] wb_dat_o,  // output data bus
  output                     wb_ack_o,  // normal termination
  output                     wb_err_o,  // termination w/ error
  output                     wb_inta_o  // Interrupt request output
);

  //////////////////////////////////////////////////////////////////////////////
  // Variables
  //////////////////////////////////////////////////////////////////////////////

  // Auxiliary Inputs Interface
  wire [GPIO_WIDTH-1:0] aux_i;  // Auxiliary inputs

  // External GPIO Interface
  wire [GPIO_WIDTH-1:0] ext_pad_i;  // GPIO Inputs

  wire [GPIO_WIDTH-1:0] ext_pad_o;    // GPIO Outputs
  wire [GPIO_WIDTH-1:0] ext_padoe_o;  // GPIO output drivers enables

  //////////////////////////////////////////////////////////////////////////////
  // Body
  //////////////////////////////////////////////////////////////////////////////

  // DUT WB
  peripheral_gpio_wb #(
    .WB_DATA_WIDTH(WB_DATA_WIDTH),
    .WB_ADDR_WIDTH(WB_ADDR_WIDTH)
  ) gpio_wb (
    // WISHBONE Interface
    .wb_clk_i(clk),  // Clock
    .wb_rst_i(rst),  // Reset

    .wb_cyc_i(wb_cyc_i),  // cycle valid input
    .wb_adr_i(wb_adr_i),  // address bus inputs
    .wb_dat_i(wb_dat_i),  // input data bus
    .wb_sel_i(wb_sel_i),  // byte select inputs
    .wb_we_i (wb_we_i),   // indicates write transfer
    .wb_stb_i(wb_stb_i),  // strobe input
    .wb_dat_o(wb_rdt_o),  // output data bus
    .wb_ack_o(wb_ack_o),  // normal termination
    .wb_err_o(wb_err_o),  // termination w/ error

    .wb_inta_o(wb_inta_o),  // Interrupt request output

    // Auxiliary Inputs Interface
    .aux_i(aux_i),  // Auxiliary inputs

    // External GPIO Interface
    .ext_pad_i(ext_pad_i),  // GPIO Inputs

    .ext_pad_o  (ext_pad_o),    // GPIO Outputs
    .ext_padoe_o(ext_padoe_o)   // GPIO output drivers enables
  );
endmodule
