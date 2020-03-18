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
//              General Purpose Input Output                                  //
//              AMBA3 APB-Lite Bus Interface                                  //
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

module mpsoc_apb_gpio #(
  parameter PADDR_SIZE = 64,
  parameter PDATA_SIZE = 64
)
  (
    input                         PRESETn,
    input                         PCLK,
    input                         PSEL,
    input                         PENABLE,
    input                         PWRITE,
    input                         PSTRB,
    input      [PADDR_SIZE  -1:0] PADDR,
    input      [PDATA_SIZE  -1:0] PWDATA,
    output reg [PDATA_SIZE  -1:0] PRDATA,
    output                        PREADY,
    output                        PSLVERR,

    input      [PDATA_SIZE  -1:0] gpio_i,
    output reg [PDATA_SIZE  -1:0] gpio_o,
    output reg [PDATA_SIZE  -1:0] gpio_oe
  );

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //

  localparam MODE      = 0,
             DIRECTION = 1,
             OUTPUTS   = 2,
             INPUTS    = 3,
             IOC       = 4, //Interrupt-on-change
             IPENDING  = 5; //Interrupt-pending

  //number of synchronisation flipflop stages on GPIO inputs
  localparam INPUT_STAGES = 3;

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //Control registers
  logic [PDATA_SIZE-1:0] mode_reg;
  logic [PDATA_SIZE-1:0] dir_reg;
  logic [PDATA_SIZE-1:0] out_reg;
  logic [PDATA_SIZE-1:0] in_reg;

  //Input register, to prevent metastability
  logic [PDATA_SIZE-1:0] input_regs [INPUT_STAGES];

  genvar n;

  //////////////////////////////////////////////////////////////////
  //
  // Functions
  //

  //Is this a valid write to address 0x...?
  //Take 'address' as an argument
  function automatic is_write_to_adr(input integer bits, input [PADDR_SIZE-1:0] address);
    logic [$bits(PADDR)-1:0] mask;

    mask = (1 << bits) - 1; //only 'bits' LSBs should be '1'
    is_write_to_adr = PSEL & PENABLE & PWRITE & ( (PADDR & mask) == (address & mask) );
  endfunction

  //What data is written?
  //- Handles PSTRB, takes previous register/data value as an argument
  function automatic [PDATA_SIZE-1:0] get_write_value (input [PDATA_SIZE-1:0] orig_val);
    get_write_value[0*8 +: 8] = PSTRB ? PWDATA[0*8 +: 8] : orig_val[0*8 +: 8];
  endfunction

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  //APB accesses

  //The core supports zero-wait state accesses on all transfers.
  //It is allowed to driver PREADY with a steady signal
  assign PREADY  = 1'b1; //always ready
  assign PSLVERR = 1'b0; //Never an error

  //APB Writes

  //APB write to Mode register
  always @(posedge PCLK,negedge PRESETn) begin
    if      (!PRESETn                ) mode_reg <= 'h0;
    else if ( is_write_to_adr(2,MODE)) mode_reg <= get_write_value(mode_reg);
  end

  //APB write to Direction register
  always @(posedge PCLK,negedge PRESETn) begin
    if      (!PRESETn                     ) dir_reg <= 'h0;
    else if ( is_write_to_adr(2,DIRECTION)) dir_reg <= get_write_value(dir_reg);
  end

  //APB write to Output register
  //treat writes to Input register same
  always @(posedge PCLK,negedge PRESETn) begin
    if      (!PRESETn                    ) out_reg <= 'h0;
    else if ( is_write_to_adr(2,OUTPUTS) ||
              is_write_to_adr(2,INPUTS)  ) out_reg <= get_write_value(out_reg);
  end

  //APB Reads
  always @(posedge PCLK) begin
    case (PADDR[1:0])
      MODE     : PRDATA <= mode_reg;
      DIRECTION: PRDATA <= dir_reg;
      OUTPUTS  : PRDATA <= out_reg;
      INPUTS   : PRDATA <= in_reg;
    endcase
  end

  //Internals INPUT_STAGES*PDATA_SIZE
  generate
    for (n=0; n<INPUT_STAGES; n=n+1) begin
      always @(posedge PCLK) begin
        if (n==0) input_regs[n] <= gpio_i;
        else      input_regs[n] <= input_regs[n-1];
      end
    end
  endgenerate

  always @(posedge PCLK) begin
    in_reg <= input_regs[INPUT_STAGES-1];
  end

  // mode
  // 0=push-pull    drive out_reg value onto transmitter input
  // 1=open-drain   always drive '0' onto transmitter

  always @(posedge PCLK) begin
    gpio_o <= mode_reg ? 'h0 : out_reg;
  end

  // direction  mode          out_reg
  // 0=input                           disable transmitter-enable (output enable)
  // 1=output   0=push-pull            always enable transmitter
  //            1=open-drain  1=Hi-Z   disable transmitter
  //                          0=low    enable transmitter

  always @(posedge PCLK) begin
    gpio_oe <= dir_reg & ~(mode_reg ? out_reg : 'h0);
  end
endmodule
