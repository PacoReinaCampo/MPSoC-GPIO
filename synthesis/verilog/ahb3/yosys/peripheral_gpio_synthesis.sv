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
//              Wishbone Bus Interface                                        //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/* Copyright (c) 2018-2019 by the author(s)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * =============================================================================
 * Author(s):
 *   Paco Reina Campo <pacoreinacampo@queenfield.tech>
 */

module peripheral_gpio_synthesis #(
  parameter HADDR_SIZE =  8,
  parameter HDATA_SIZE = 32,
  parameter APB_ADDR_WIDTH =  8,
  parameter APB_DATA_WIDTH = 32,
  parameter SYNC_DEPTH =  3
)
  (
    //Common signals
    input                         HRESETn,
    input                         HCLK,
								  
    //UART AHB3
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

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //Common signals
  logic [APB_ADDR_WIDTH -1:0] gpio_PADDR;
  logic [APB_DATA_WIDTH -1:0] gpio_PWDATA;
  logic                       gpio_PWRITE;
  logic                       gpio_PSEL;
  logic                       gpio_PENABLE;
  logic [APB_DATA_WIDTH -1:0] gpio_PRDATA;
  logic                       gpio_PREADY;
  logic                       gpio_PSLVERR;

  logic                       gpio_rx_i;  // Receiver input
  logic                       gpio_tx_o;  // Transmitter output

  logic                       gpio_event_o;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //DUT AHB3
  peripheral_bridge_apb2ahb #(
    .HADDR_SIZE ( HADDR_SIZE     ),
    .HDATA_SIZE ( HDATA_SIZE     ),
    .PADDR_SIZE ( APB_ADDR_WIDTH ),
    .PDATA_SIZE ( APB_DATA_WIDTH ),
    .SYNC_DEPTH ( SYNC_DEPTH     )
  )
  bridge_apb2ahb (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      ( gpio_HSEL      ),
    .HADDR     ( gpio_HADDR     ),
    .HWDATA    ( gpio_HWDATA    ),
    .HRDATA    ( gpio_HRDATA    ),
    .HWRITE    ( gpio_HWRITE    ),
    .HSIZE     ( gpio_HSIZE     ),
    .HBURST    ( gpio_HBURST    ),
    .HPROT     ( gpio_HPROT     ),
    .HTRANS    ( gpio_HTRANS    ),
    .HMASTLOCK ( gpio_HMASTLOCK ),
    .HREADYOUT ( gpio_HREADYOUT ),
    .HREADY    ( gpio_HREADY    ),
    .HRESP     ( gpio_HRESP     ),

    //APB Master Interface
    .PRESETn ( HRESETn ),
    .PCLK    ( HCLK    ),

    .PSEL    ( gpio_PSEL    ),
    .PENABLE ( gpio_PENABLE ),
    .PPROT   (              ),
    .PWRITE  ( gpio_PWRITE  ),
    .PSTRB   (              ),
    .PADDR   ( gpio_PADDR   ),
    .PWDATA  ( gpio_PWDATA  ),
    .PRDATA  ( gpio_PRDATA  ),
    .PREADY  ( gpio_PREADY  ),
    .PSLVERR ( gpio_PSLVERR )
  );

  peripheral_apb4_gpio #(
    .APB_ADDR_WIDTH ( APB_ADDR_WIDTH ),
    .APB_DATA_WIDTH ( APB_DATA_WIDTH )
  )
  apb4_gpio (
    .RSTN ( HRESETn ),
    .CLK  ( HCLK    ),

    .PADDR   ( gpio_PADDR   ),
    .PWDATA  ( gpio_PWDATA  ),
    .PWRITE  ( gpio_PWRITE  ),
    .PSEL    ( gpio_PSEL    ),
    .PENABLE ( gpio_PENABLE ),
    .PRDATA  ( gpio_PRDATA  ),
    .PREADY  ( gpio_PREADY  ),
    .PSLVERR ( gpio_PSLVERR ),

    .rx_i ( gpio_rx_i ),
    .tx_o ( gpio_tx_o ),

    .event_o ( gpio_event_o )
  );
endmodule
