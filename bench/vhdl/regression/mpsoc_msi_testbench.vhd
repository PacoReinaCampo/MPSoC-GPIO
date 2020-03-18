-- Converted from bench/verilog/regression/mpsoc_msi_testbench.sv
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
--              Master Slave Interface Tesbench                               //
--              AMBA3 AHB-Lite Bus Interface                                  //
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
-- *   Francisco Javier Reina Campo <frareicam@gmail.com>
-- */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mpsoc_msi_testbench is
end mpsoc_msi_testbench;

architecture RTL of mpsoc_msi_testbench is
  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  -- AHB3 GPIO Interface
  constant HADDR_SIZE : integer := 32;
  constant HDATA_SIZE : integer := 32;
  constant PADDR_SIZE : integer := 10;
  constant PDATA_SIZE : integer := 8;
  constant SYNC_DEPTH : integer := 3;

  -- WB GPIO Interface
  constant WB_DATA_WIDTH         : integer := 32;
  constant WB_ADDR_WIDTH         : integer := 8;
  constant GPIO_WIDTH            : integer := 32;
  constant USE_IO_PAD_CLK        : string  := "DISABLED";
  constant REGISTER_GPIO_OUTPUTS : string  := "DISABLED";
  constant REGISTER_GPIO_INPUTS  : string  := "DISABLED";

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  --Common signals
  signal HRESETn : std_logic;
  signal HCLK    : std_logic;

  --AHB3 GPIO Interface
  signal mst_gpio_HSEL      : std_logic;
  signal mst_gpio_HADDR     : std_logic_vector(HADDR_SIZE-1 downto 0);
  signal mst_gpio_HWDATA    : std_logic_vector(HDATA_SIZE-1 downto 0);
  signal mst_gpio_HRDATA    : std_logic_vector(HDATA_SIZE-1 downto 0);
  signal mst_gpio_HWRITE    : std_logic;
  signal mst_gpio_HSIZE     : std_logic_vector(2 downto 0);
  signal mst_gpio_HBURST    : std_logic_vector(2 downto 0);
  signal mst_gpio_HPROT     : std_logic_vector(3 downto 0);
  signal mst_gpio_HTRANS    : std_logic_vector(1 downto 0);
  signal mst_gpio_HMASTLOCK : std_logic;
  signal mst_gpio_HREADY    : std_logic;
  signal mst_gpio_HREADYOUT : std_logic;
  signal mst_gpio_HRESP     : std_logic;

  signal gpio_PADDR   : std_logic_vector(PADDR_SIZE-1 downto 0);
  signal gpio_PWDATA  : std_logic_vector(PDATA_SIZE-1 downto 0);
  signal gpio_PSEL    : std_logic;
  signal gpio_PENABLE : std_logic;
  signal gpio_PWRITE  : std_logic;
  signal gpio_PSTRB   : std_logic;
  signal gpio_PRDATA  : std_logic_vector(PDATA_SIZE-1 downto 0);
  signal gpio_PREADY  : std_logic;
  signal gpio_PSLVERR : std_logic;

  signal gpio_i  : std_logic_vector(PDATA_SIZE-1 downto 0);
  signal gpio_o  : std_logic_vector(PDATA_SIZE-1 downto 0);
  signal gpio_oe : std_logic_vector(PDATA_SIZE-1 downto 0);

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

  --////////////////////////////////////////////////////////////////
  --
  -- Components
  --
  component mpsoc_ahb3_peripheral_bridge
    generic (
      HADDR_SIZE : integer := 32;
      HDATA_SIZE : integer := 32;
      PADDR_SIZE : integer := 10;
      PDATA_SIZE : integer := 8;
      SYNC_DEPTH : integer := 3
      );
    port (
      --AHB Slave Interface
      HRESETn   : in  std_logic;
      HCLK      : in  std_logic;
      HSEL      : in  std_logic;
      HADDR     : in  std_logic_vector(HADDR_SIZE-1 downto 0);
      HWDATA    : in  std_logic_vector(HDATA_SIZE-1 downto 0);
      HRDATA    : out std_logic_vector(HDATA_SIZE-1 downto 0);
      HWRITE    : in  std_logic;
      HSIZE     : in  std_logic_vector(2 downto 0);
      HBURST    : in  std_logic_vector(2 downto 0);
      HPROT     : in  std_logic_vector(3 downto 0);
      HTRANS    : in  std_logic_vector(1 downto 0);
      HMASTLOCK : in  std_logic;
      HREADYOUT : out std_logic;
      HREADY    : in  std_logic;
      HRESP     : out std_logic;

      --APB Master Interface
      PRESETn : in  std_logic;
      PCLK    : in  std_logic;
      PADDR   : out std_logic_vector(PADDR_SIZE-1 downto 0);
      PWDATA  : out std_logic_vector(PDATA_SIZE-1 downto 0);
      PSEL    : out std_logic;
      PENABLE : out std_logic;
      PPROT   : out std_logic_vector(2 downto 0);
      PWRITE  : out std_logic;
      PSTRB   : out std_logic;
      PRDATA  : in  std_logic_vector(PDATA_SIZE-1 downto 0);
      PREADY  : in  std_logic;
      PSLVERR : in  std_logic
      );
  end component;

  component mpsoc_apb_gpio
    generic (
      PADDR_SIZE : integer := 64;
      PDATA_SIZE : integer := 64
      );
    port (
      PRESETn : in std_logic;
      PCLK    : in std_logic;

      PSEL    : in  std_logic;
      PENABLE : in  std_logic;
      PWRITE  : in  std_logic;
      PSTRB   : in  std_logic;
      PADDR   : in  std_logic_vector(PADDR_SIZE-1 downto 0);
      PWDATA  : in  std_logic_vector(PDATA_SIZE-1 downto 0);
      PRDATA  : out std_logic_vector(PDATA_SIZE-1 downto 0);
      PREADY  : out std_logic;
      PSLVERR : out std_logic;

      gpio_i  : in  std_logic_vector(PDATA_SIZE-1 downto 0);
      gpio_o  : out std_logic_vector(PDATA_SIZE-1 downto 0);
      gpio_oe : out std_logic_vector(PDATA_SIZE-1 downto 0)
      );
  end component;

  component mpsoc_wb_gpio
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

  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --DUT AHB3
  gpio_ahb3_bridge : mpsoc_ahb3_peripheral_bridge
    generic map (
      HADDR_SIZE => HADDR_SIZE,
      HDATA_SIZE => HDATA_SIZE,
      PADDR_SIZE => PADDR_SIZE,
      PDATA_SIZE => PDATA_SIZE,
      SYNC_DEPTH => SYNC_DEPTH
      )
    port map (
      --AHB Slave Interface
      HRESETn => HRESETn,
      HCLK    => HCLK,

      HSEL      => mst_gpio_HSEL,
      HADDR     => mst_gpio_HADDR,
      HWDATA    => mst_gpio_HWDATA,
      HRDATA    => mst_gpio_HRDATA,
      HWRITE    => mst_gpio_HWRITE,
      HSIZE     => mst_gpio_HSIZE,
      HBURST    => mst_gpio_HBURST,
      HPROT     => mst_gpio_HPROT,
      HTRANS    => mst_gpio_HTRANS,
      HMASTLOCK => mst_gpio_HMASTLOCK,
      HREADYOUT => mst_gpio_HREADYOUT,
      HREADY    => mst_gpio_HREADY,
      HRESP     => mst_gpio_HRESP,

      --APB Master Interface
      PRESETn => HRESETn,
      PCLK    => HCLK,

      PSEL    => gpio_PSEL,
      PENABLE => gpio_PENABLE,
      PPROT   => open,
      PWRITE  => gpio_PWRITE,
      PSTRB   => gpio_PSTRB,
      PADDR   => gpio_PADDR,
      PWDATA  => gpio_PWDATA,
      PRDATA  => gpio_PRDATA,
      PREADY  => gpio_PREADY,
      PSLVERR => gpio_PSLVERR
      );

  gpio : mpsoc_apb_gpio
    generic map (
      PADDR_SIZE => PADDR_SIZE,
      PDATA_SIZE => PDATA_SIZE
      )
    port map (
      PRESETn => HRESETn,
      PCLK    => HCLK,

      PSEL    => gpio_PSEL,
      PENABLE => gpio_PENABLE,
      PWRITE  => gpio_PWRITE,
      PSTRB   => gpio_PSTRB,
      PADDR   => gpio_PADDR,
      PWDATA  => gpio_PWDATA,
      PRDATA  => gpio_PRDATA,
      PREADY  => gpio_PREADY,
      PSLVERR => gpio_PSLVERR,

      gpio_i  => gpio_i,
      gpio_o  => gpio_o,
      gpio_oe => gpio_oe
      );

  --DUT WB
  wb_gpio : mpsoc_wb_gpio
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
      wb_clk_i => HCLK,                 -- Clock
      wb_rst_i => HRESETn,              -- Reset

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
end RTL;
