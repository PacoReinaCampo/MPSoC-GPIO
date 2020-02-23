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
  parameter HADDR_SIZE  = 32;
  parameter HDATA_SIZE  = 32;
  parameter PADDR_SIZE  = 10;
  parameter PDATA_SIZE  = 8;
  parameter SYNC_DEPTH  = 3;

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //Common signals
  wire                        HRESETn;
  wire                        HCLK;

  //GPIO Interface
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

  //DUT WB
  mpsoc_wb_peripheral_bridge #(
    .HADDR_SIZE ( HADDR_SIZE ),
    .HDATA_SIZE ( HDATA_SIZE ),
    .PADDR_SIZE ( PADDR_SIZE ),
    .PDATA_SIZE ( PDATA_SIZE ),
    .SYNC_DEPTH ( SYNC_DEPTH )
  )
  gpio_wb_bridge (
    //AHB Slave Interface
    .HRESETn   ( HRESETn ),
    .HCLK      ( HCLK    ),

    .HSEL      (       ),
    .HADDR     (      ),
    .HWDATA    (     ),
    .HRDATA    (     ),
    .HWRITE    (     ),
    .HSIZE     (      ),
    .HBURST    (     ),
    .HPROT     (      ),
    .HTRANS    (     ),
    .HMASTLOCK (  ),
    .HREADYOUT (  ),
    .HREADY    (     ),
    .HRESP     (      ),

    //APB Master Interface
    .PRESETn (  ),
    .PCLK    (     ),

    .PSEL    (     ),
    .PENABLE (  ),
    .PPROT   (              ),
    .PWRITE  (   ),
    .PSTRB   (    ),
    .PADDR   (    ),
    .PWDATA  (   ),
    .PRDATA  (   ),
    .PREADY  (   ),
    .PSLVERR (  )
  );

  //DUT APB
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
endmodule
