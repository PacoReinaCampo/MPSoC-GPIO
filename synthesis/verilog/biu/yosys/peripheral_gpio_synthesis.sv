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
//              Universal Asynchronous Receiver-Transmitter                   //
//              AMBA3 AHB-Lite Bus Interface                                  //
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
  parameter HADDR_SIZE = 8,
  parameter HDATA_SIZE = 32,
  parameter PADDR_SIZE = 8,
  parameter PDATA_SIZE = 32,
  parameter SYNC_DEPTH = 3
) (
  // Common signals
  input HRESETn,
  input HCLK,

  // UART AHB3
  input                         gpio_HSEL,
  input      [HADDR_SIZE  -1:0] gpio_HADDR,
  input      [HDATA_SIZE  -1:0] gpio_HWDATA,
  output reg [HDATA_SIZE  -1:0] gpio_HRDATA,
  input                         gpio_HWRITE,
  input      [             2:0] gpio_HSIZE,
  input      [             2:0] gpio_HBURST,
  input      [             3:0] gpio_HPROT,
  input      [             1:0] gpio_HTRANS,
  input                         gpio_HMASTLOCK,
  output reg                    gpio_HREADYOUT,
  input                         gpio_HREADY,
  output reg                    gpio_HRESP
);

  //////////////////////////////////////////////////////////////////////////////
  // Variables
  //////////////////////////////////////////////////////////////////////////////

  wire [PADDR_SIZE     -1:0] gpio_PADDR;
  wire [PDATA_SIZE     -1:0] gpio_PWDATA;
  wire                       gpio_PSEL;
  wire                       gpio_PENABLE;
  wire                       gpio_PWRITE;
  wire                       gpio_PSTRB;
  wire [PDATA_SIZE     -1:0] gpio_PRDATA;
  wire                       gpio_PREADY;
  wire                       gpio_PSLVERR;

  wire [PDATA_SIZE     -1:0] gpio_i;
  reg  [PDATA_SIZE     -1:0] gpio_o;

  reg  [PDATA_SIZE     -1:0] gpio_oe;

  //////////////////////////////////////////////////////////////////////////////
  // Body
  //////////////////////////////////////////////////////////////////////////////

  // DUT AHB3
  peripheral_apb42ahb3 #(
    .HADDR_SIZE(HADDR_SIZE),
    .HDATA_SIZE(HDATA_SIZE),
    .PADDR_SIZE(PADDR_SIZE),
    .PDATA_SIZE(PDATA_SIZE),
    .SYNC_DEPTH(SYNC_DEPTH)
  ) apb42ahb3 (
    // AHB Slave Interface
    .HRESETn(HRESETn),
    .HCLK   (HCLK),

    .HSEL     (gpio_HSEL),
    .HADDR    (gpio_HADDR),
    .HWDATA   (gpio_HWDATA),
    .HRDATA   (gpio_HRDATA),
    .HWRITE   (gpio_HWRITE),
    .HSIZE    (gpio_HSIZE),
    .HBURST   (gpio_HBURST),
    .HPROT    (gpio_HPROT),
    .HTRANS   (gpio_HTRANS),
    .HMASTLOCK(gpio_HMASTLOCK),
    .HREADYOUT(gpio_HREADYOUT),
    .HREADY   (gpio_HREADY),
    .HRESP    (gpio_HRESP),

    // APB Master Interface
    .PRESETn(HRESETn),
    .PCLK   (HCLK),

    .PSEL   (gpio_PSEL),
    .PENABLE(gpio_PENABLE),
    .PPROT  (),
    .PWRITE (gpio_PWRITE),
    .PSTRB  (gpio_PSTRB),
    .PADDR  (gpio_PADDR),
    .PWDATA (gpio_PWDATA),
    .PRDATA (gpio_PRDATA),
    .PREADY (gpio_PREADY),
    .PSLVERR(gpio_PSLVERR)
  );

  peripheral_gpio_apb4 #(
    .PADDR_SIZE(PADDR_SIZE),
    .PDATA_SIZE(PDATA_SIZE)
  ) gpio_apb4 (
    .PRESETn(HRESETn),
    .PCLK   (HCLK),

    .PSEL   (gpio_PSEL),
    .PENABLE(gpio_PENABLE),
    .PWRITE (gpio_PWRITE),
    .PSTRB  (gpio_PSTRB),
    .PADDR  (gpio_PADDR),
    .PWDATA (gpio_PWDATA),
    .PRDATA (gpio_PRDATA),
    .PREADY (gpio_PREADY),
    .PSLVERR(gpio_PSLVERR),

    .irq_o(irq_o),

    .gpio_i(gpio_i),
    .gpio_o(gpio_o),

    .gpio_oe(gpio_oe)
  );
endmodule
