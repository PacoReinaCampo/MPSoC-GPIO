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
//              AMBA3 AHB-Lite Bus Interface                                  //
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
 *   Francisco Javier Reina Campo <frareicam@gmail.com>
 */

module mpsoc_msi_testbench;

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //

  // AHB3 GPIO Interface
  parameter HADDR_SIZE  = 32;
  parameter HDATA_SIZE  = 32;
  parameter PADDR_SIZE  = 10;
  parameter PDATA_SIZE  = 8;
  parameter SYNC_DEPTH  = 3;

  // WB GPIO Interface
  parameter WB_DATA_WIDTH         = 32;
  parameter WB_ADDR_WIDTH         = 8;
  parameter GPIO_WIDTH            = 32;
  parameter USE_IO_PAD_CLK        = "DISABLED";
  parameter REGISTER_GPIO_OUTPUTS = "DISABLED";
  parameter REGISTER_GPIO_INPUTS  = "DISABLED";

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  // Common signals
  wire                        HRESETn;
  wire                        HCLK;

  // AHB3 GPIO Interface
  wire                        mst_gpio_HSEL;
  wire  [HADDR_SIZE     -1:0] mst_gpio_HADDR;
  wire  [HDATA_SIZE     -1:0] mst_gpio_HWDATA;
  wire  [HDATA_SIZE     -1:0] mst_gpio_HRDATA;
  wire                        mst_gpio_HWRITE;
  wire  [                2:0] mst_gpio_HSIZE;
  wire  [                2:0] mst_gpio_HBURST;
  wire  [                3:0] mst_gpio_HPROT;
  wire  [                1:0] mst_gpio_HTRANS;
  wire                        mst_gpio_HMASTLOCK;
  wire                        mst_gpio_HREADY;
  wire                        mst_gpio_HREADYOUT;
  wire                        mst_gpio_HRESP;

  wire  [PADDR_SIZE     -1:0] gpio_PADDR;
  wire  [PDATA_SIZE     -1:0] gpio_PWDATA;
  wire                        gpio_PSEL;
  wire                        gpio_PENABLE;
  wire                        gpio_PWRITE;
  wire                        gpio_PSTRB;
  wire  [PDATA_SIZE     -1:0] gpio_PRDATA;
  wire                        gpio_PREADY;
  wire                        gpio_PSLVERR;

  wire  [PDATA_SIZE     -1:0] gpio_i;
  reg   [PDATA_SIZE     -1:0] gpio_o;
  reg   [PDATA_SIZE     -1:0] gpio_oe;

  // WB GPIO Interface
  wire                        wb_cyc_i;   // cycle valid input
  wire   [WB_ADDR_WIDTH-1:0]  wb_adr_i;   // address bus inputs
  wire   [WB_DATA_WIDTH-1:0]  wb_dat_i;   // input data bus
  wire   [              3:0]  wb_sel_i;   // byte select inputs
  wire                        wb_we_i;    // indicates write transfer
  wire                        wb_stb_i;   // strobe input
  wire   [WB_DATA_WIDTH-1:0]  wb_dat_o;   // output data bus
  wire                        wb_ack_o;   // normal termination
  wire                        wb_err_o;   // termination w/ error
  wire                        wb_inta_o;  // Interrupt request output

  // Auxiliary Inputs Interface
  wire   [GPIO_WIDTH-1:0]  aux_i;  // Auxiliary inputs

  // External GPIO Interface
  wire   [GPIO_WIDTH-1:0]  ext_pad_i;  // GPIO Inputs

  wire   [GPIO_WIDTH-1:0]  ext_pad_o;    // GPIO Outputs
  wire   [GPIO_WIDTH-1:0]  ext_padoe_o;  // GPIO output drivers enables

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //DUT AHB3
  mpsoc_ahb3_peripheral_bridge #(
    .HADDR_SIZE ( HADDR_SIZE ) ,
    .HDATA_SIZE ( HDATA_SIZE ),
    .PADDR_SIZE ( PADDR_SIZE ),
    .PDATA_SIZE ( PDATA_SIZE ),
    .SYNC_DEPTH ( SYNC_DEPTH )
  )
  gpio_ahb3_bridge (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      ( mst_gpio_HSEL      ),
    .HADDR     ( mst_gpio_HADDR     ),
    .HWDATA    ( mst_gpio_HWDATA    ),
    .HRDATA    ( mst_gpio_HRDATA    ),
    .HWRITE    ( mst_gpio_HWRITE    ),
    .HSIZE     ( mst_gpio_HSIZE     ),
    .HBURST    ( mst_gpio_HBURST    ),
    .HPROT     ( mst_gpio_HPROT     ),
    .HTRANS    ( mst_gpio_HTRANS    ),
    .HMASTLOCK ( mst_gpio_HMASTLOCK ),
    .HREADYOUT ( mst_gpio_HREADYOUT ),
    .HREADY    ( mst_gpio_HREADY    ),
    .HRESP     ( mst_gpio_HRESP     ),

    //APB Master Interface
    .PRESETn ( HRESETn ),
    .PCLK    ( HCLK    ),

    .PSEL    ( gpio_PSEL    ),
    .PENABLE ( gpio_PENABLE ),
    .PPROT   (              ),
    .PWRITE  ( gpio_PWRITE  ),
    .PSTRB   ( gpio_PSTRB   ),
    .PADDR   ( gpio_PADDR   ),
    .PWDATA  ( gpio_PWDATA  ),
    .PRDATA  ( gpio_PRDATA  ),
    .PREADY  ( gpio_PREADY  ),
    .PSLVERR ( gpio_PSLVERR )
  );

  mpsoc_apb_gpio #(
    .PADDR_SIZE ( PADDR_SIZE ),
    .PDATA_SIZE ( PDATA_SIZE )
  )
  gpio (
    .PRESETn ( HRESETn ),
    .PCLK    ( HCLK    ),

    .PSEL    ( gpio_PSEL    ),
    .PENABLE ( gpio_PENABLE ),
    .PWRITE  ( gpio_PWRITE  ),
    .PSTRB   ( gpio_PSTRB   ),
    .PADDR   ( gpio_PADDR   ),
    .PWDATA  ( gpio_PWDATA  ),
    .PRDATA  ( gpio_PRDATA  ),
    .PREADY  ( gpio_PREADY  ),
    .PSLVERR ( gpio_PSLVERR ),

    .gpio_i  ( gpio_i       ),
    .gpio_o  ( gpio_o       ),
    .gpio_oe ( gpio_oe      )
  );

  //DUT WB
  mpsoc_wb_gpio #(
    .WB_DATA_WIDTH         ( WB_DATA_WIDTH         ),
    .WB_ADDR_WIDTH         ( WB_ADDR_WIDTH         ),
    .GPIO_WIDTH            ( GPIO_WIDTH            ),
    .USE_IO_PAD_CLK        ( USE_IO_PAD_CLK        ),
    .REGISTER_GPIO_OUTPUTS ( REGISTER_GPIO_OUTPUTS ),
    .REGISTER_GPIO_INPUTS  ( REGISTER_GPIO_INPUTS  )
  )
  wb_gpio (
    // WISHBONE Interface
    .wb_clk_i  ( HCLK     ),  // Clock
    .wb_rst_i  ( HRESETn  ),  // Reset

    .wb_cyc_i  ( wb_cyc_i  ),  // cycle valid input
    .wb_adr_i  ( wb_adr_i  ),  // address bus inputs
    .wb_dat_i  ( wb_dat_i  ),  // input data bus
    .wb_sel_i  ( wb_sel_i  ),  // byte select inputs
    .wb_we_i   ( wb_we_i   ),  // indicates write transfer
    .wb_stb_i  ( wb_stb_i  ),  // strobe input
    .wb_dat_o  ( wb_dat_o  ),  // output data bus
    .wb_ack_o  ( wb_ack_o  ),  // normal termination
    .wb_err_o  ( wb_err_o  ),  // termination w/ error
    .wb_inta_o ( wb_inta_o ),  // Interrupt request output

    // Auxiliary Inputs Interface
    .aux_i (aux_i),  // Auxiliary inputs

    // External GPIO Interface
    .ext_pad_i (ext_pad_i),  // GPIO Inputs

    .ext_pad_o (ext_pad_o),   // GPIO Outputs
    .ext_padoe_o (ext_padoe_o)  // GPIO output drivers enables
  );
endmodule
