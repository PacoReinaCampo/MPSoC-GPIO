-- Converted from bench/verilog/regression/peripheral_gpio_testbench.sv
-- by verilog2vhdl - QueenField

--------------------------------------------------------------------------------
--                                            __ _      _     _               --
--                                           / _(_)    | |   | |              --
--                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              --
--               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              --
--              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              --
--               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              --
--                  | |                                                       --
--                  |_|                                                       --
--                                                                            --
--                                                                            --
--              Peripheral-GPIO for MPSoC                                     --
--              General Purpose Input Output for MPSoC                        --
--              WishBone Bus Interface                                        --
--                                                                            --
--------------------------------------------------------------------------------

-- Copyright (c) 2018-2019 by the author(s)
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
--------------------------------------------------------------------------------
-- Author(s):
--   Paco Reina Campo <pacoreinacampo@queenfield.tech>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity peripheral_gpio_testbench is
end peripheral_gpio_testbench;

architecture rtl of peripheral_gpio_testbench is
  ------------------------------------------------------------------------------
  --  Constants
  ------------------------------------------------------------------------------

  -- WB GPIO Interface
  constant WB_DATA_WIDTH         : integer := 32;
  constant WB_ADDR_WIDTH         : integer := 8;
  constant GPIO_WIDTH            : integer := 32;
  constant USE_IO_PAD_CLK        : string  := "DISABLED";
  constant REGISTER_GPIO_OUTPUTS : string  := "DISABLED";
  constant REGISTER_GPIO_INPUTS  : string  := "DISABLED";

  ------------------------------------------------------------------------------
  -- Variables
  ------------------------------------------------------------------------------

  --Common signals
  signal clk : std_logic;
  signal rst : std_logic;

  -- WB GPIO Interface
  signal wb_cyc_i  : std_logic;         -- cycle valid input
  signal wb_adr_i  : std_logic_vector(WB_ADDR_WIDTH-1 downto 0);  -- address bus inputs
  signal wb_dat_i  : std_logic_vector(WB_DATA_WIDTH-1 downto 0);  -- input data bus
  signal wb_sel_i  : std_logic_vector(3 downto 0);  -- byte select inputs
  signal wb_we_i   : std_logic;         -- indicates write transfer
  signal wb_stb_i  : std_logic;         -- strobe input
  signal wb_dat_o  : std_logic_vector(WB_DATA_WIDTH-1 downto 0);  -- output data bus
  signal wb_ack_o  : std_logic;         -- normal termination
  signal wb_err_o  : std_logic;         -- termination w/ error
  signal wb_inta_o : std_logic;         -- Interrupt request output

  -- Auxiliary Inputs Interface
  signal aux_i : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- Auxiliary inputs

  -- External GPIO Interface
  signal ext_pad_i : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- GPIO Inputs

  signal ext_pad_o   : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- GPIO Outputs
  signal ext_padoe_o : std_logic_vector(GPIO_WIDTH-1 downto 0);  -- GPIO output drivers enables

  ------------------------------------------------------------------------------
  -- Components
  ------------------------------------------------------------------------------
  component peripheral_gpio_wb
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
      wb_clk_i  : in  std_logic;        -- Clock
      wb_rst_i  : in  std_logic;        -- Reset
      wb_cyc_i  : in  std_logic;        -- cycle valid input
      wb_adr_i  : in  std_logic_vector(WB_ADDR_WIDTH-1 downto 0);  -- address bus inputs
      wb_dat_i  : in  std_logic_vector(WB_DATA_WIDTH-1 downto 0);  -- input data bus
      wb_sel_i  : in  std_logic_vector(3 downto 0);  -- byte select inputs
      wb_we_i   : in  std_logic;        -- indicates write transfer
      wb_stb_i  : in  std_logic;        -- strobe input
      wb_dat_o  : out std_logic_vector(WB_DATA_WIDTH-1 downto 0);  -- output data bus
      wb_ack_o  : out std_logic;        -- normal termination
      wb_err_o  : out std_logic;        -- termination w/ error
      wb_inta_o : out std_logic;        -- Interrupt request output

      -- Auxiliary Inputs Interface
      aux_i : in std_logic_vector(GPIO_WIDTH-1 downto 0);  -- Auxiliary inputs

      -- External GPIO Interface
      ext_pad_i : in std_logic_vector(GPIO_WIDTH-1 downto 0);  -- GPIO Inputs

      ext_pad_o   : out std_logic_vector(GPIO_WIDTH-1 downto 0);  -- GPIO Outputs
      ext_padoe_o : out std_logic_vector(GPIO_WIDTH-1 downto 0)  -- GPIO output drivers enables
      );
  end component;

begin

  ------------------------------------------------------------------------------
  -- Module Body
  ------------------------------------------------------------------------------

  --DUT WB
  gpio_wb : peripheral_gpio_wb
    generic map (
      WB_DATA_WIDTH         => WB_DATA_WIDTH,
      WB_ADDR_WIDTH         => WB_ADDR_WIDTH,
      GPIO_WIDTH            => GPIO_WIDTH,
      USE_IO_PAD_CLK        => USE_IO_PAD_CLK,
      REGISTER_GPIO_OUTPUTS => REGISTER_GPIO_OUTPUTS,
      REGISTER_GPIO_INPUTS  => REGISTER_GPIO_INPUTS
      )
    port map (
      -- WISHBONE Interface
      wb_clk_i => clk,                  -- Clock
      wb_rst_i => rst,                  -- Reset

      wb_cyc_i  => wb_cyc_i,            -- cycle valid input
      wb_adr_i  => wb_adr_i,            -- address bus inputs
      wb_dat_i  => wb_dat_i,            -- input data bus
      wb_sel_i  => wb_sel_i,            -- byte select inputs
      wb_we_i   => wb_we_i,             -- indicates write transfer
      wb_stb_i  => wb_stb_i,            -- strobe input
      wb_dat_o  => wb_dat_o,            -- output data bus
      wb_ack_o  => wb_ack_o,            -- normal termination
      wb_err_o  => wb_err_o,            -- termination w/ error
      wb_inta_o => wb_inta_o,           -- Interrupt request output

      -- Auxiliary Inputs Interface
      aux_i => aux_i,                   -- Auxiliary inputs

      -- External GPIO Interface
      ext_pad_i => ext_pad_i,           -- GPIO Inputs

      ext_pad_o   => ext_pad_o,         -- GPIO Outputs
      ext_padoe_o => ext_padoe_o        -- GPIO output drivers enables
      );
end rtl;
