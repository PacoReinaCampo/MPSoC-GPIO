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
--              AMBA3 AHB-Lite Bus Interface                                  --
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

  -- AHB3 GPIO Interface
  constant HADDR_SIZE : integer := 32;
  constant HDATA_SIZE : integer := 32;
  constant PADDR_SIZE : integer := 10;
  constant PDATA_SIZE : integer := 8;
  constant SYNC_DEPTH : integer := 3;

  ------------------------------------------------------------------------------
  -- Variables
  ------------------------------------------------------------------------------

  -- Common signals
  signal HRESETn : std_logic;
  signal HCLK    : std_logic;

  -- AHB3 GPIO Interface
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

  ------------------------------------------------------------------------------
  -- Components
  ------------------------------------------------------------------------------
  component peripheral_apb42ahb3
    generic (
      HADDR_SIZE : integer := 32;
      HDATA_SIZE : integer := 32;
      PADDR_SIZE : integer := 10;
      PDATA_SIZE : integer := 8;
      SYNC_DEPTH : integer := 3
      );
    port (
      -- AHB Slave Interface
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

      -- APB Master Interface
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

  component peripheral_gpio_apb4
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

begin

  ------------------------------------------------------------------------------
  -- Module Body
  ------------------------------------------------------------------------------

  -- DUT AHB3
  apb42ahb3 : peripheral_apb42ahb3
    generic map (
      HADDR_SIZE => HADDR_SIZE,
      HDATA_SIZE => HDATA_SIZE,
      PADDR_SIZE => PADDR_SIZE,
      PDATA_SIZE => PDATA_SIZE,
      SYNC_DEPTH => SYNC_DEPTH
      )
    port map (
      -- AHB Slave Interface
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

      -- APB Master Interface
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

  gpio_apb4 : peripheral_gpio_apb4
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
end rtl;
