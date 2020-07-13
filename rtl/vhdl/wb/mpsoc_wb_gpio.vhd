-- Converted from mpsoc_wb_gpio.v
-- by verilog2vhdl - QueenField

--//////////////////////////////////////////////////////////////////////////////
--                                            __ _      _     _               //
--                                           / _(_)    | |   | |              //
--                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              //
--               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              //
--              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              //
--               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              //
--                  | |                                                       //
--                  |_|                                                       //
--                                                                            //
--                                                                            //
--              MPSoC-RISCV CPU                                               //
--              General Purpose Input Output Bridge                           //
--              Wishbone Bus Interface                                        //
--                                                                            //
--//////////////////////////////////////////////////////////////////////////////

-- Copyright (c) 2018-2019 by the author(s)
-- *
-- * Permission is hereby granted, free of charge, to any person obtaining a copy
-- * of this software and associated documentation files (the "Software"), to deal
-- * in the Software without restriction, including without limitation the rights
-- * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- * copies of the Software, and to permit persons to whom the Software is
-- * furnished to do so, subject to the following conditions:
-- *
-- * The above copyright notice and this permission notice shall be included in
-- * all copies or substantial portions of the Software.
-- *
-- * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- * THE SOFTWARE.
-- *
-- * =============================================================================
-- * Author(s):
-- *   Damjan Lampret <lampret@opencores.org>
-- *   Francisco Javier Reina Campo <frareicam@gmail.com>
-- */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mpsoc_wb_gpio is
  generic (
    WB_DATA_WIDTH         : integer := 32;
    WB_ADDR_WIDTH         : integer := 8;
    GPIO_WIDTH            : integer := 32;
    USE_IO_PAD_CLK        : string  := "DISABLED";
    REGISTER_GPIO_OUTPUTS : string  := "DISABLED";
    REGISTER_GPIO_INPUTS  : string  := "DISABLED"
    );
  port (
    -- WISHBONE Interface
    wb_clk_i  : in  std_logic;          -- Clock
    wb_rst_i  : in  std_logic;          -- Reset
    wb_cyc_i  : in  std_logic;          -- cycle valid input
    wb_adr_i  : in  std_logic_vector(WB_ADDR_WIDTH-1 downto 0);  -- address bus inputs
    wb_dat_i  : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);  -- input data bus
    wb_sel_i  : in  std_logic_vector(3 downto 0);  -- byte select inputs
    wb_we_i   : in  std_logic;          -- indicates write transfer
    wb_stb_i  : in  std_logic;          -- strobe input
    wb_dat_o  : out std_logic_vector(WB_DATA_WIDTH-1 downto 0);  -- output data bus
    wb_ack_o  : out std_logic;          -- normal termination
    wb_err_o  : out std_logic;          -- termination w/ error
    wb_inta_o : out std_logic;          -- Interrupt request output

    -- Auxiliary Inputs Interface
    aux_i : in std_logic_vector(GPIO_WIDTH-1 downto 0);  -- Auxiliary inputs

    -- External GPIO Interface
    ext_pad_i : in std_logic_vector(GPIO_WIDTH-1 downto 0);  -- GPIO Inputs

    ext_pad_o   : out std_logic_vector(GPIO_WIDTH-1 downto 0);  -- GPIO Outputs
    ext_padoe_o : out std_logic_vector(GPIO_WIDTH-1 downto 0)  -- GPIO output drivers enables
    );
end mpsoc_wb_gpio;

architecture RTL of mpsoc_wb_gpio is
  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  -- Strict 32-bit WISHBONE access

  -- If this one is defined, all WISHBONE accesses must be 32-bit. If it is
  -- not defined, err_o is asserted whenever 8- or 16-bit access is made.
  -- Undefine it if you need to save some area.

  -- By default it is defined.
  constant GPIO_STRICT_32BIT_ACCESS : std_logic := '1';
  constant GPIO_FULL_DECODE         : std_logic := '1';

  -- WISHBONE address bits used for full decoding of GPIO registers.
  constant GPIO_ADDRHH : integer := 7;
  constant GPIO_ADDRHL : integer := 6;
  constant GPIO_ADDRLH : integer := 1;
  constant GPIO_ADDRLL : integer := 0;

  -- Bits of WISHBONE address used for partial decoding of GPIO registers.

  -- Addresses of GPIO registers

  -- To comply with GPIO IP core specification document they must go from
  -- address 0 to address 0x18 in the following order: RGPIO_IN, RGPIO_OUT,
  -- RGPIO_OE, RGPIO_INTE, RGPIO_PTRIG, RGPIO_AUX and RGPIO_CTRL

  -- If particular register is not needed, it's address definition can be omitted
  -- and the register will not be implemented. Instead a fixed default value will
  -- be used.
  constant GPIO_RGPIO_IN    : integer := 0;  -- Address 0x00
  constant GPIO_RGPIO_OUT   : integer := 1;  -- Address 0x04
  constant GPIO_RGPIO_OE    : integer := 2;  -- Address 0x08
  constant GPIO_RGPIO_INTE  : integer := 3;  -- Address 0x0c
  constant GPIO_RGPIO_PTRIG : integer := 4;  -- Address 0x10
  constant GPIO_RGPIO_AUX   : integer := 5;  -- Address 0x14
  constant GPIO_RGPIO_CTRL  : integer := 6;  -- Address 0x18
  constant GPIO_RGPIO_INTS  : integer := 7;  -- Address 0x1c
  constant GPIO_RGPIO_ECLK  : integer := 8;  -- Address 0x20
  constant GPIO_RGPIO_NEC   : integer := 9;  -- Address 0x24

  -- Default values for unimplemented GPIO registers
  constant GPIO_DEF_RGPIO_IN    : std_logic_vector(GPIO_WIDTH-1 downto 0) := (others => '0');
  constant GPIO_DEF_RGPIO_OUT   : std_logic_vector(GPIO_WIDTH-1 downto 0) := (others => '0');
  constant GPIO_DEF_RGPIO_OE    : std_logic_vector(GPIO_WIDTH-1 downto 0) := (others => '0');
  constant GPIO_DEF_RGPIO_INTE  : std_logic_vector(GPIO_WIDTH-1 downto 0) := (others => '0');
  constant GPIO_DEF_RGPIO_PTRIG : std_logic_vector(GPIO_WIDTH-1 downto 0) := (others => '0');
  constant GPIO_DEF_RGPIO_AUX   : std_logic_vector(GPIO_WIDTH-1 downto 0) := (others => '0');
  constant GPIO_DEF_RGPIO_CTRL  : std_logic_vector(GPIO_WIDTH-1 downto 0) := (others => '0');
  constant GPIO_DEF_RGPIO_ECLK  : std_logic_vector(GPIO_WIDTH-1 downto 0) := (others => '0');
  constant GPIO_DEF_RGPIO_NEC   : std_logic_vector(GPIO_WIDTH-1 downto 0) := (others => '0');

  -- RGPIO_CTRL bits

  -- To comply with the GPIO IP core specification document they must go from
  -- bit 0 to bit 1 in the following order: INTE, INT
  constant GPIO_RGPIO_CTRL_INTE : integer := 0;
  constant GPIO_RGPIO_CTRL_INTS : integer := 1;

  constant GPIO_WB_BYTES1 : std_logic := '0';
  constant GPIO_WB_BYTES2 : std_logic := '0';
  constant GPIO_WB_BYTES3 : std_logic := '0';
  constant GPIO_WB_BYTES4 : std_logic := '0';

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  -- GPIO Input Register (or no register)
  signal rgpio_in : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- RGPIO_IN register

  -- GPIO Output Register (or no register)
  signal rgpio_out : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- RGPIO_OUT register

  -- GPIO Output Driver Enable Register (or no register)
  signal rgpio_oe : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- RGPIO_OE register

  -- GPIO Interrupt Enable Register (or no register)
  signal rgpio_inte : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- RGPIO_INTE register

  -- GPIO Positive edge Triggered Register (or no register)
  signal rgpio_ptrig : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- RGPIO_PTRIG register

  -- GPIO Auxiliary select Register (or no register)
  signal rgpio_aux : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- RGPIO_AUX register

  -- GPIO Control Register (or no register)
  signal rgpio_ctrl : std_logic_vector(1 downto 0);  -- RGPIO_CTRL register

  -- GPIO Interrupt Status Register (or no register)
  signal rgpio_ints : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- RGPIO_INTS register

  -- GPIO Enable Clock  Register (or no register)
  signal rgpio_eclk : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- RGPIO_ECLK register

  -- GPIO Active Negative Edge  Register (or no register)
  signal rgpio_nec : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- RGPIO_NEC register

  signal ext_pad_s : std_logic_vector(GPIO_WIDTH-1 downto 0);

  -- Internal wires & regs
  signal rgpio_out_sel   : std_logic;   -- RGPIO_OUT select
  signal rgpio_oe_sel    : std_logic;   -- RGPIO_OE select
  signal rgpio_inte_sel  : std_logic;   -- RGPIO_INTE select
  signal rgpio_ptrig_sel : std_logic;   -- RGPIO_PTRIG select
  signal rgpio_aux_sel   : std_logic;   -- RGPIO_AUX select
  signal rgpio_ctrl_sel  : std_logic;   -- RGPIO_CTRL select
  signal rgpio_ints_sel  : std_logic;   -- RGPIO_INTS select
  signal rgpio_eclk_sel  : std_logic;
  signal rgpio_nec_sel   : std_logic;
  signal full_decoding   : std_logic;   -- Full address decoding qualification
  signal in_muxed        : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- Muxed inputs
  signal wb_ack          : std_logic;   -- WB Acknowledge
  signal wb_err          : std_logic;   -- WB Error
  signal wb_inta         : std_logic;   -- WB Interrupt
  signal wb_dat          : std_logic_vector(WB_DATA_WIDTH-1 downto 0);  -- WB Data out
  signal wb_ack_s        : std_logic;   -- WB Acknowledge
  signal wb_err_s        : std_logic;   -- WB Error
  signal wb_inta_s       : std_logic;   -- WB Interrupt
  signal wb_dat_s        : std_logic_vector(WB_DATA_WIDTH-1 downto 0);  -- WB Data out

  signal out_pad : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- GPIO Outputs

  -- synchronize inputs to system clock
  signal sync, ext_pad_sync : std_logic_vector(GPIO_WIDTH-1 downto 0);

  -- GPIO Outputs
  signal ext_pad_g : std_logic_vector(GPIO_WIDTH-1 downto 0);

  --////////////////////////////////////////////////////////////////
  --
  -- Functions
  --
  function reduce_or (
    reduce_or_in : std_logic_vector
    ) return std_logic is
    variable reduce_or_out : std_logic := '0';
  begin
    for i in reduce_or_in'range loop
      reduce_or_out := reduce_or_out or reduce_or_in(i);
    end loop;
    return reduce_or_out;
  end reduce_or;

  function to_stdlogic (
    input : boolean
    ) return std_logic is
  begin
    if input then
      return('1');
    else
      return('0');
    end if;
  end function to_stdlogic;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  -- All WISHBONE transfer terminations are successful except when:
  -- a) full address decoding is enabled and address doesn't match
  --    any of the GPIO registers
  -- b) wb_sel_i evaluation is enabled and one of the wb_sel_i inputs is zero

  -- WB Acknowledge
  wb_ack <= wb_cyc_i and wb_stb_i and not wb_err_s;

  processing_0 : process (wb_clk_i, wb_rst_i)
  begin
    if (wb_rst_i = '1') then
      wb_ack_s <= '0';
    elsif (rising_edge(wb_clk_i)) then
      wb_ack_s <= wb_ack and not wb_ack_s and (not wb_err);
    end if;
  end process;

  wb_ack_o <= wb_ack_s;

  -- WB Error
  GPIO_STRICT_32BIT_ACCESS_GENERATING_10 : if (GPIO_STRICT_32BIT_ACCESS = '1') generate
    wb_err <= wb_cyc_i and wb_stb_i and (not full_decoding or to_stdlogic(wb_sel_i /= "1111"));
  elsif (GPIO_STRICT_32BIT_ACCESS = '0') generate
    wb_err <= wb_cyc_i and wb_stb_i and not full_decoding;
  end generate;

  processing_1 : process (wb_clk_i, wb_rst_i)
  begin
    if (wb_rst_i = '1') then
      wb_err_s <= '0';
    elsif (rising_edge(wb_clk_i)) then
      wb_err_s <= wb_err and not wb_err_s;
    end if;
  end process;

  wb_err_o <= wb_err_s;

  -- Full address decoder
  GPIO_FULL_DECODE_GENERATING_11 : if (GPIO_FULL_DECODE = '1') generate
    full_decoding <= to_stdlogic(wb_adr_i(GPIO_ADDRHH downto GPIO_ADDRHL) = std_logic_vector(to_unsigned(0, GPIO_ADDRHH-GPIO_ADDRHL+1))) and to_stdlogic(wb_adr_i(GPIO_ADDRLH downto GPIO_ADDRLL) = std_logic_vector(to_unsigned(0, GPIO_ADDRLH-GPIO_ADDRLL+1)));
  elsif (GPIO_FULL_DECODE = '0') generate
    full_decoding <= '1';
  end generate;

  -- GPIO registers address decoder
  GPIO_RGPIO_OUT_GENERATING_12 : if (GPIO_RGPIO_OUT /= 0) generate
    rgpio_out_sel <= wb_cyc_i and wb_stb_i and to_stdlogic(wb_adr_i(GPIO_ADDRHL+1 downto GPIO_ADDRLH-1) = std_logic_vector(to_unsigned(GPIO_RGPIO_OUT, GPIO_ADDRHL-GPIO_ADDRLH+3))) and full_decoding;
  end generate;
  GPIO_RGPIO_OE_GENERATING_13 : if (GPIO_RGPIO_OE /= 0) generate
    rgpio_oe_sel <= wb_cyc_i and wb_stb_i and to_stdlogic(wb_adr_i(GPIO_ADDRHL+1 downto GPIO_ADDRLH-1) = std_logic_vector(to_unsigned(GPIO_RGPIO_OE, GPIO_ADDRHL-GPIO_ADDRLH+3))) and full_decoding;
  end generate;
  GPIO_RGPIO_INTE_GENERATING_14 : if (GPIO_RGPIO_INTE /= 0) generate
    rgpio_inte_sel <= wb_cyc_i and wb_stb_i and to_stdlogic(wb_adr_i(GPIO_ADDRHL+1 downto GPIO_ADDRLH-1) = std_logic_vector(to_unsigned(GPIO_RGPIO_INTE, GPIO_ADDRHL-GPIO_ADDRLH+3))) and full_decoding;
  end generate;
  GPIO_RGPIO_PTRIG_GENERATING_15 : if (GPIO_RGPIO_PTRIG /= 0) generate
    rgpio_ptrig_sel <= wb_cyc_i and wb_stb_i and to_stdlogic(wb_adr_i(GPIO_ADDRHL+1 downto GPIO_ADDRLH-1) = std_logic_vector(to_unsigned(GPIO_RGPIO_PTRIG, GPIO_ADDRHL-GPIO_ADDRLH+3))) and full_decoding;
  end generate;
  GPIO_RGPIO_AUX_GENERATING_16 : if (GPIO_RGPIO_AUX /= 0) generate
    rgpio_aux_sel <= wb_cyc_i and wb_stb_i and to_stdlogic(wb_adr_i(GPIO_ADDRHL+1 downto GPIO_ADDRLH-1) = std_logic_vector(to_unsigned(GPIO_RGPIO_AUX, GPIO_ADDRHL-GPIO_ADDRLH+3))) and full_decoding;
  end generate;
  GPIO_RGPIO_CTRL_GENERATING_17 : if (GPIO_RGPIO_CTRL /= 0) generate
    rgpio_ctrl_sel <= wb_cyc_i and wb_stb_i and to_stdlogic(wb_adr_i(GPIO_ADDRHL+1 downto GPIO_ADDRLH-1) = std_logic_vector(to_unsigned(GPIO_RGPIO_CTRL, GPIO_ADDRHL-GPIO_ADDRLH+3))) and full_decoding;
  end generate;
  GPIO_RGPIO_INTS_GENERATING_18 : if (GPIO_RGPIO_INTS /= 0) generate
    rgpio_ints_sel <= wb_cyc_i and wb_stb_i and to_stdlogic(wb_adr_i(GPIO_ADDRHL+1 downto GPIO_ADDRLH-1) = std_logic_vector(to_unsigned(GPIO_RGPIO_INTS, GPIO_ADDRHL-GPIO_ADDRLH+3))) and full_decoding;
  end generate;
  GPIO_RGPIO_ECLK_GENERATING_19 : if (GPIO_RGPIO_ECLK /= 0) generate
    rgpio_eclk_sel <= wb_cyc_i and wb_stb_i and to_stdlogic(wb_adr_i(GPIO_ADDRHL+1 downto GPIO_ADDRLH-1) = std_logic_vector(to_unsigned(GPIO_RGPIO_ECLK, GPIO_ADDRHL-GPIO_ADDRLH+3))) and full_decoding;
  end generate;
  GPIO_RGPIO_NEC_GENERATING_20 : if (GPIO_RGPIO_NEC /= 0) generate
    rgpio_nec_sel <= wb_cyc_i and wb_stb_i and to_stdlogic(wb_adr_i(GPIO_ADDRHL+1 downto GPIO_ADDRLH-1) = std_logic_vector(to_unsigned(GPIO_RGPIO_NEC, GPIO_ADDRHL-GPIO_ADDRLH+3))) and full_decoding;
  end generate;

  -- Write to RGPIO_CTRL or update of RGPIO_CTRL[INT] bit
  GPIO_RGPIO_CTRL_GENERATING_21 : if (GPIO_RGPIO_CTRL /= 0) generate
    processing_2 : process (wb_clk_i, wb_rst_i)
    begin
      if (wb_rst_i = '1') then
        rgpio_ctrl <= (others => '0');
      elsif (rising_edge(wb_clk_i)) then
        if (rgpio_ctrl_sel = '1' and wb_we_i = '1') then
          rgpio_ctrl <= wb_dat_i(1 downto 0);
        elsif (rgpio_ctrl(GPIO_RGPIO_CTRL_INTE) = '1') then
          rgpio_ctrl(GPIO_RGPIO_CTRL_INTS) <= rgpio_ctrl(GPIO_RGPIO_CTRL_INTS) or wb_inta_s;
        end if;
      end if;
    end process;
  elsif (GPIO_RGPIO_CTRL = 0) generate
    rgpio_ctrl <= "01";                 -- RGPIO_CTRL[EN] = 1
  end generate;

  -- Write to RGPIO_OUT
  GPIO_RGPIO_OUT_GENERATING_22 : if (GPIO_RGPIO_OUT /= 0) generate
    processing_3 : process (wb_clk_i, wb_rst_i)
    begin
      if (wb_rst_i = '1') then
        rgpio_out <= (others => '0');
      elsif (rising_edge(wb_clk_i)) then
        if (rgpio_out_sel = '1' and wb_we_i = '1') then
          if (GPIO_STRICT_32BIT_ACCESS = '1') then
            rgpio_out <= wb_dat_i(GPIO_WIDTH-1 downto 0);
          elsif (GPIO_WB_BYTES4 = '1') then
            if (wb_sel_i(3) = '1') then
              rgpio_out(GPIO_WIDTH-1 downto 24) <= wb_dat_i(GPIO_WIDTH-1 downto 24);
            elsif (wb_sel_i(2) = '1') then
              rgpio_out(23 downto 16) <= wb_dat_i(23 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_out(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_out(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES3 = '1') then
            if (wb_sel_i(2) = '1') then
              rgpio_out(GPIO_WIDTH-1 downto 16) <= wb_dat_i(GPIO_WIDTH-1 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_out(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_out(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES2 = '1') then
            if (wb_sel_i(1) = '1') then
              rgpio_out(GPIO_WIDTH-1 downto 8) <= wb_dat_i(GPIO_WIDTH-1 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_out(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES1 = '1') then
            if (wb_sel_i(0) = '1') then
              rgpio_out(GPIO_WIDTH-1 downto 0) <= wb_dat_i(GPIO_WIDTH-1 downto 0);
            end if;
          end if;
        end if;
      end if;
    end process;
  elsif (GPIO_RGPIO_OUT = 0) generate
    rgpio_out <= GPIO_DEF_RGPIO_OUT;    -- RGPIO_OUT = 0x0
  end generate;

  -- Write to RGPIO_OE.
  GPIO_RGPIO_OE_GENERATING_28 : if (GPIO_RGPIO_OE /= 0) generate
    processing_4 : process (wb_clk_i, wb_rst_i)
    begin
      if (wb_rst_i = '1') then
        rgpio_oe <= (others => '0');
      elsif (rising_edge(wb_clk_i)) then
        if (rgpio_oe_sel = '1' and wb_we_i = '1') then
          if (GPIO_STRICT_32BIT_ACCESS = '1') then
            rgpio_oe <= wb_dat_i(GPIO_WIDTH-1 downto 0);
          elsif (GPIO_WB_BYTES4 = '1') then
            if (wb_sel_i(3) = '1') then
              rgpio_oe(GPIO_WIDTH-1 downto 24) <= wb_dat_i(GPIO_WIDTH-1 downto 24);
            elsif (wb_sel_i(2) = '1') then
              rgpio_oe(23 downto 16) <= wb_dat_i(23 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_oe(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_oe(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES3 = '1') then
            if (wb_sel_i(2) = '1') then
              rgpio_oe(GPIO_WIDTH-1 downto 16) <= wb_dat_i(GPIO_WIDTH-1 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_oe(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_oe(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES2 = '1') then
            if (wb_sel_i(1) = '1') then
              rgpio_oe(GPIO_WIDTH-1 downto 8) <= wb_dat_i(GPIO_WIDTH-1 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_oe(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES1 = '1') then
            if (wb_sel_i(0) = '1') then
              rgpio_oe(GPIO_WIDTH-1 downto 0) <= wb_dat_i(GPIO_WIDTH-1 downto 0);
            end if;
          end if;
        end if;
      end if;
    end process;
  elsif (GPIO_RGPIO_OE = 0) generate
    rgpio_oe <= GPIO_DEF_RGPIO_OE;      -- RGPIO_OE = 0x0
  end generate;


  -- Write to RGPIO_INTE
  GPIO_RGPIO_INTE_GENERATING_34 : if (GPIO_RGPIO_INTE /= 0) generate
    processing_5 : process (wb_clk_i, wb_rst_i)
    begin
      if (wb_rst_i = '1') then
        rgpio_inte <= (others => '0');
      elsif (rising_edge(wb_clk_i)) then
        if (rgpio_inte_sel = '1' and wb_we_i = '1') then
          if (GPIO_STRICT_32BIT_ACCESS = '1') then
            rgpio_inte <= wb_dat_i(GPIO_WIDTH-1 downto 0);
          elsif (GPIO_WB_BYTES4 = '1') then
            if (wb_sel_i(3) = '1') then
              rgpio_inte(GPIO_WIDTH-1 downto 24) <= wb_dat_i(GPIO_WIDTH-1 downto 24);
            elsif (wb_sel_i(2) = '1') then
              rgpio_inte(23 downto 16) <= wb_dat_i(23 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_inte(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_inte(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES3 = '1') then
            if (wb_sel_i(2) = '1') then
              rgpio_inte(GPIO_WIDTH-1 downto 16) <= wb_dat_i(GPIO_WIDTH-1 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_inte(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_inte(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES2 = '1') then
            if (wb_sel_i(1) = '1') then
              rgpio_inte(GPIO_WIDTH-1 downto 8) <= wb_dat_i(GPIO_WIDTH-1 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_inte(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES1 = '1') then
            if (wb_sel_i(0) = '1') then
              rgpio_inte(GPIO_WIDTH-1 downto 0) <= wb_dat_i(GPIO_WIDTH-1 downto 0);
            end if;
          end if;
        end if;
      end if;
    end process;
  elsif (GPIO_RGPIO_INTE = 0) generate
    rgpio_inte <= GPIO_DEF_RGPIO_INTE;  -- RGPIO_INTE = 0x0
  end generate;

  -- Write to RGPIO_PTRIG
  GPIO_RGPIO_PTRIG_GENERATING_40 : if (GPIO_RGPIO_PTRIG /= 0) generate
    processing_6 : process (wb_clk_i, wb_rst_i)
    begin
      if (wb_rst_i = '1') then
        rgpio_ptrig <= (others => '0');
      elsif (rising_edge(wb_clk_i)) then
        if (rgpio_ptrig_sel = '1' and wb_we_i = '1') then
          if (GPIO_STRICT_32BIT_ACCESS = '1') then
            rgpio_ptrig <= wb_dat_i(GPIO_WIDTH-1 downto 0);
          elsif (GPIO_WB_BYTES4 = '1') then
            if (wb_sel_i(3) = '1') then
              rgpio_ptrig(GPIO_WIDTH-1 downto 24) <= wb_dat_i(GPIO_WIDTH-1 downto 24);
            elsif (wb_sel_i(2) = '1') then
              rgpio_ptrig(23 downto 16) <= wb_dat_i(23 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_ptrig(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_ptrig(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES3 = '1') then
            if (wb_sel_i(2) = '1') then
              rgpio_ptrig(GPIO_WIDTH-1 downto 16) <= wb_dat_i(GPIO_WIDTH-1 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_ptrig(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_ptrig(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES2 = '1') then
            if (wb_sel_i(1) = '1') then
              rgpio_ptrig(GPIO_WIDTH-1 downto 8) <= wb_dat_i(GPIO_WIDTH-1 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_ptrig(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES1 = '1') then
            if (wb_sel_i(0) = '1') then
              rgpio_ptrig(GPIO_WIDTH-1 downto 0) <= wb_dat_i(GPIO_WIDTH-1 downto 0);
            end if;
          end if;
        end if;
      end if;
    end process;
  elsif (GPIO_RGPIO_PTRIG = 0) generate
    rgpio_ptrig <= GPIO_DEF_RGPIO_PTRIG;  -- RGPIO_PTRIG = 0x0
  end generate;

  -- Write to RGPIO_AUX
  GPIO_RGPIO_AUX_GENERATING_46 : if (GPIO_RGPIO_AUX /= 0) generate
    processing_7 : process (wb_clk_i, wb_rst_i)
    begin
      if (wb_rst_i = '1') then
        rgpio_aux <= (others => '0');
      elsif (rising_edge(wb_clk_i)) then
        if (rgpio_aux_sel = '1' and wb_we_i = '1') then
          if (GPIO_STRICT_32BIT_ACCESS = '1') then
            rgpio_aux <= wb_dat_i(GPIO_WIDTH-1 downto 0);
          elsif (GPIO_WB_BYTES4 = '1') then
            if (wb_sel_i(3) = '1') then
              rgpio_aux(GPIO_WIDTH-1 downto 24) <= wb_dat_i(GPIO_WIDTH-1 downto 24);
            elsif (wb_sel_i(2) = '1') then
              rgpio_aux(23 downto 16) <= wb_dat_i(23 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_aux(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_aux(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES3 = '1') then
            if (wb_sel_i(2) = '1') then
              rgpio_aux(GPIO_WIDTH-1 downto 16) <= wb_dat_i(GPIO_WIDTH-1 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_aux(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_aux(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES2 = '1') then
            if (wb_sel_i(1) = '1') then
              rgpio_aux(GPIO_WIDTH-1 downto 8) <= wb_dat_i(GPIO_WIDTH-1 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_aux(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES1 = '1') then
            if (wb_sel_i(0) = '1') then
              rgpio_aux(GPIO_WIDTH-1 downto 0) <= wb_dat_i(GPIO_WIDTH-1 downto 0);
            end if;
          end if;
        end if;
      end if;
    end process;
  elsif (GPIO_RGPIO_AUX = 0) generate
    rgpio_aux <= GPIO_DEF_RGPIO_AUX;    -- RGPIO_AUX = 0x0
  end generate;

  -- Write to RGPIO_ECLK
  GPIO_RGPIO_ECLK_GENERATING_52 : if (GPIO_RGPIO_ECLK /= 0) generate
    processing_8 : process (wb_clk_i, wb_rst_i)
    begin
      if (wb_rst_i = '1') then
        rgpio_eclk <= (others => '0');
      elsif (rising_edge(wb_clk_i)) then
        if (rgpio_eclk_sel = '1' and wb_we_i = '1') then
          if (GPIO_STRICT_32BIT_ACCESS = '1') then
            rgpio_eclk <= wb_dat_i(GPIO_WIDTH-1 downto 0);
          elsif (GPIO_WB_BYTES4 = '1') then
            if (wb_sel_i(3) = '1') then
              rgpio_eclk(GPIO_WIDTH-1 downto 24) <= wb_dat_i(GPIO_WIDTH-1 downto 24);
            elsif (wb_sel_i(2) = '1') then
              rgpio_eclk(23 downto 16) <= wb_dat_i(23 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_eclk(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_eclk(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES3 = '1') then
            if (wb_sel_i(2) = '1') then
              rgpio_eclk(GPIO_WIDTH-1 downto 16) <= wb_dat_i(GPIO_WIDTH-1 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_eclk(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_eclk(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES2 = '1') then
            if (wb_sel_i(1) = '1') then
              rgpio_eclk(GPIO_WIDTH-1 downto 8) <= wb_dat_i(GPIO_WIDTH-1 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_eclk(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES1 = '1') then
            if (wb_sel_i(0) = '1') then
              rgpio_eclk(GPIO_WIDTH-1 downto 0) <= wb_dat_i(GPIO_WIDTH-1 downto 0);
            end if;
          end if;
        end if;
      end if;
    end process;
  elsif (GPIO_RGPIO_ECLK = 0) generate
    rgpio_eclk <= GPIO_DEF_RGPIO_ECLK;  -- RGPIO_ECLK = 0x0
  end generate;

  -- Write to RGPIO_NEC
  GPIO_RGPIO_NEC_GENERATING_58 : if (GPIO_RGPIO_NEC /= 0) generate
    processing_9 : process (wb_clk_i, wb_rst_i)
    begin
      if (wb_rst_i = '1') then
        rgpio_nec <= (others => '0');
      elsif (rising_edge(wb_clk_i)) then
        if (rgpio_nec_sel = '1' and wb_we_i = '1') then
          if (GPIO_STRICT_32BIT_ACCESS = '1') then
            rgpio_nec <= wb_dat_i(GPIO_WIDTH-1 downto 0);
          elsif (GPIO_WB_BYTES4 = '1') then
            if (wb_sel_i(3) = '1') then
              rgpio_nec(GPIO_WIDTH-1 downto 24) <= wb_dat_i(GPIO_WIDTH-1 downto 24);
            elsif (wb_sel_i(2) = '1') then
              rgpio_nec(23 downto 16) <= wb_dat_i(23 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_nec(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_nec(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES3 = '1') then
            if (wb_sel_i(2) = '1') then
              rgpio_nec(GPIO_WIDTH-1 downto 16) <= wb_dat_i(GPIO_WIDTH-1 downto 16);
            elsif (wb_sel_i(1) = '1') then
              rgpio_nec(15 downto 8) <= wb_dat_i(15 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_nec(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES2 = '1') then
            if (wb_sel_i(1) = '1') then
              rgpio_nec(GPIO_WIDTH-1 downto 8) <= wb_dat_i(GPIO_WIDTH-1 downto 8);
            elsif (wb_sel_i(0) = '1') then
              rgpio_nec(7 downto 0) <= wb_dat_i(7 downto 0);
            end if;
          elsif (GPIO_WB_BYTES1 = '1') then
            if (wb_sel_i(0) = '1') then
              rgpio_nec(GPIO_WIDTH-1 downto 0) <= wb_dat_i(GPIO_WIDTH-1 downto 0);
            end if;
          end if;
        end if;
      end if;
    end process;
  elsif (GPIO_RGPIO_NEC = 0) generate
    rgpio_nec <= GPIO_DEF_RGPIO_NEC;    -- RGPIO_NEC = 0x0
  end generate;

  REGISTER_GPIO_INPUTS_GENERATING_58 : if (REGISTER_GPIO_INPUTS = "ENABLED") generate
    -- synchronize inputs to system clock
    processing_10 : process (wb_clk_i, wb_rst_i)
    begin
      if (wb_rst_i = '1') then
        sync         <= (others => '0');
        ext_pad_sync <= (others => '0');
      elsif (rising_edge(wb_clk_i)) then
        sync         <= ext_pad_i;
        ext_pad_sync <= sync;
      end if;
      ext_pad_s <= ext_pad_sync;
    end process;
  elsif (REGISTER_GPIO_INPUTS = "DISABLED") generate
    -- Pass straight through
    ext_pad_s <= ext_pad_i;
  end generate;

  -- Latch into RGPIO_IN
  GPIO_RGPIO_IN_GENERATING_64 : if (GPIO_RGPIO_IN /= 0) generate
    processing_11 : process (wb_clk_i, wb_rst_i)
    begin
      if (wb_rst_i = '1') then
        rgpio_in <= (others => '0');
      elsif (rising_edge(wb_clk_i)) then
        rgpio_in <= in_muxed;
      end if;
    end process;
  elsif (GPIO_RGPIO_IN = 0) generate
    rgpio_in <= in_muxed;
  end generate;

  in_muxed <= ext_pad_s;

  -- Mux all registers when doing a read of GPIO registers
  processing_12 : process (wb_adr_i, rgpio_in, rgpio_out, rgpio_oe, rgpio_inte, rgpio_ptrig, rgpio_aux, rgpio_ctrl, rgpio_ints, rgpio_eclk, rgpio_nec)
    variable state : integer;
  begin
    case (state) is                     -- synopsys full_case parallel_case
      when GPIO_RGPIO_OUT =>
        if (GPIO_RGPIO_OUT /= 0) then
          wb_dat(WB_DATA_WIDTH-1 downto 0) <= rgpio_out;
        end if;
      when GPIO_RGPIO_OE =>
        if (GPIO_RGPIO_OE /= 0) then
          wb_dat(WB_DATA_WIDTH-1 downto 0) <= rgpio_oe;
        end if;
      when GPIO_RGPIO_INTE =>
        if (GPIO_RGPIO_INTE /= 0) then
          wb_dat(WB_DATA_WIDTH-1 downto 0) <= rgpio_inte;
        end if;
      when GPIO_RGPIO_PTRIG =>
        if (GPIO_RGPIO_PTRIG /= 0) then
          wb_dat(WB_DATA_WIDTH-1 downto 0) <= rgpio_ptrig;
        end if;
      when GPIO_RGPIO_NEC =>
        if (GPIO_RGPIO_NEC /= 0) then
          wb_dat(WB_DATA_WIDTH-1 downto 0) <= rgpio_nec;
        end if;
      when GPIO_RGPIO_ECLK =>
        if (GPIO_RGPIO_ECLK /= 0) then
          wb_dat(WB_DATA_WIDTH-1 downto 0) <= rgpio_eclk;
        end if;
      when GPIO_RGPIO_AUX =>
        if (GPIO_RGPIO_AUX /= 0) then
          wb_dat(WB_DATA_WIDTH-1 downto 0) <= rgpio_aux;
        end if;
      when GPIO_RGPIO_CTRL =>
        if (GPIO_RGPIO_CTRL /= 0) then
          wb_dat(1 downto 0)               <= rgpio_ctrl;
          wb_dat(WB_DATA_WIDTH-1 downto 2) <= (others => '0');
        end if;
      when GPIO_RGPIO_INTS =>
        if (GPIO_RGPIO_INTS /= 0) then
          wb_dat(WB_DATA_WIDTH-1 downto 0) <= rgpio_ints;
        end if;
      when others =>
        wb_dat(WB_DATA_WIDTH-1 downto 0) <= rgpio_in;
    end case;

    state := to_integer(unsigned(wb_adr_i(GPIO_ADDRHL+1 downto GPIO_ADDRLH-1)));
  end process;

  processing_13 : process (wb_clk_i, wb_rst_i)
  begin
    if (wb_rst_i = '1') then
      wb_dat_s <= (others => '0');
    elsif (rising_edge(wb_clk_i)) then
      wb_dat_s <= wb_dat;
    end if;
  end process;

  wb_dat_o <= wb_dat_s;

  -- RGPIO_INTS
  GPIO_RGPIO_INTS_GENERATING_74 : if (GPIO_RGPIO_INTS /= 0) generate
    processing_14 : process (wb_clk_i, wb_rst_i)
    begin
      if (wb_rst_i = '1') then
        rgpio_ints <= (others => '0');
      elsif (rising_edge(wb_clk_i)) then
        if (rgpio_ints_sel = '1' and wb_we_i = '1') then
          rgpio_ints <= wb_dat_i(GPIO_WIDTH-1 downto 0);
        elsif (rgpio_ctrl(GPIO_RGPIO_CTRL_INTE) = '1') then
          rgpio_ints <= rgpio_ints or (((in_muxed xor rgpio_in) and not (in_muxed xor rgpio_ptrig)) and rgpio_inte);
        end if;
      end if;
    end process;
  elsif (GPIO_RGPIO_INTS = 0) generate
    rgpio_ints <= rgpio_ints or (((in_muxed xor rgpio_in) and not (in_muxed xor rgpio_ptrig)) and rgpio_inte);
  end generate;

  -- Generate interrupt request
  wb_inta <= rgpio_ctrl(GPIO_RGPIO_CTRL_INTE)
             when reduce_or(rgpio_ints) = '1' else '0';

  processing_15 : process (wb_clk_i, wb_rst_i)
  begin
    if (wb_rst_i = '1') then
      wb_inta_s <= '0';
    elsif (rising_edge(wb_clk_i)) then
      wb_inta_s <= wb_inta;
    end if;
  end process;

  wb_inta_o <= wb_inta_s;

  -- Output enables are RGPIO_OE bits
  ext_padoe_o <= rgpio_oe;

  -- Generate GPIO outputs
  out_pad <= (rgpio_out and not rgpio_aux) or (aux_i and rgpio_aux);

  -- Optional registration of GPIO outputs
  REGISTER_GPIO_OUTPUTS_GENERATING_74 : if (REGISTER_GPIO_OUTPUTS = "ENABLED") generate
    processing_16 : process (wb_clk_i, wb_rst_i)
    begin
      if (wb_rst_i = '1') then
        ext_pad_g <= (others => '0');
      elsif (rising_edge(wb_clk_i)) then
        ext_pad_g <= out_pad;
      end if;
    end process;
  elsif (REGISTER_GPIO_OUTPUTS = "DISABLED") generate
    ext_pad_g <= out_pad;
  end generate;

  ext_pad_o <= ext_pad_g;
end RTL;
