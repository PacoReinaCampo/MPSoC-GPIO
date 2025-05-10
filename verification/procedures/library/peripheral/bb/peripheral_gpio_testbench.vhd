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
  -- Variables
  ------------------------------------------------------------------------------

  signal p1_dout : std_logic_vector (7 downto 0);
  signal p2_dout : std_logic_vector (7 downto 0);
  signal p3_dout : std_logic_vector (7 downto 0);
  signal p4_dout : std_logic_vector (7 downto 0);
  signal p5_dout : std_logic_vector (7 downto 0);
  signal p6_dout : std_logic_vector (7 downto 0);

  signal p1_dout_en : std_logic_vector (7 downto 0);
  signal p2_dout_en : std_logic_vector (7 downto 0);
  signal p3_dout_en : std_logic_vector (7 downto 0);
  signal p4_dout_en : std_logic_vector (7 downto 0);
  signal p5_dout_en : std_logic_vector (7 downto 0);
  signal p6_dout_en : std_logic_vector (7 downto 0);

  signal p1_sel : std_logic_vector (7 downto 0);
  signal p2_sel : std_logic_vector (7 downto 0);
  signal p3_sel : std_logic_vector (7 downto 0);
  signal p4_sel : std_logic_vector (7 downto 0);
  signal p5_sel : std_logic_vector (7 downto 0);
  signal p6_sel : std_logic_vector (7 downto 0);

  signal p1dir : std_logic_vector (7 downto 0);
  signal p1ifg : std_logic_vector (7 downto 0);

  signal p1_din : std_logic_vector (7 downto 0);
  signal p2_din : std_logic_vector (7 downto 0);
  signal p3_din : std_logic_vector (7 downto 0);
  signal p4_din : std_logic_vector (7 downto 0);
  signal p5_din : std_logic_vector (7 downto 0);
  signal p6_din : std_logic_vector (7 downto 0);

  signal irq_port1 : std_logic;
  signal irq_port2 : std_logic;

  signal per_dout : std_logic_vector (15 downto 0);
  signal mclk     : std_logic;
  signal per_en   : std_logic;
  signal puc_rst  : std_logic;
  signal per_we   : std_logic_vector (1 downto 0);
  signal per_addr : std_logic_vector (13 downto 0);
  signal per_din  : std_logic_vector (15 downto 0);

  ------------------------------------------------------------------------------
  -- Components
  ------------------------------------------------------------------------------
  component peripheral_gpio_bb
    port (
      p1_dout : out std_logic_vector (7 downto 0);
      p2_dout : out std_logic_vector (7 downto 0);
      p3_dout : out std_logic_vector (7 downto 0);
      p4_dout : out std_logic_vector (7 downto 0);
      p5_dout : out std_logic_vector (7 downto 0);
      p6_dout : out std_logic_vector (7 downto 0);

      p1_dout_en : out std_logic_vector (7 downto 0);
      p2_dout_en : out std_logic_vector (7 downto 0);
      p3_dout_en : out std_logic_vector (7 downto 0);
      p4_dout_en : out std_logic_vector (7 downto 0);
      p5_dout_en : out std_logic_vector (7 downto 0);
      p6_dout_en : out std_logic_vector (7 downto 0);

      p1_sel : out std_logic_vector (7 downto 0);
      p2_sel : out std_logic_vector (7 downto 0);
      p3_sel : out std_logic_vector (7 downto 0);
      p4_sel : out std_logic_vector (7 downto 0);
      p5_sel : out std_logic_vector (7 downto 0);
      p6_sel : out std_logic_vector (7 downto 0);

      p1dir : out std_logic_vector (7 downto 0);
      p1ifg : out std_logic_vector (7 downto 0);

      p1_din : in std_logic_vector (7 downto 0);
      p2_din : in std_logic_vector (7 downto 0);
      p3_din : in std_logic_vector (7 downto 0);
      p4_din : in std_logic_vector (7 downto 0);
      p5_din : in std_logic_vector (7 downto 0);
      p6_din : in std_logic_vector (7 downto 0);

      irq_port1 : out std_logic;
      irq_port2 : out std_logic;

      per_dout : out std_logic_vector (15 downto 0);
      mclk     : in  std_logic;
      per_en   : in  std_logic;
      puc_rst  : in  std_logic;
      per_we   : in  std_logic_vector (1 downto 0);
      per_addr : in  std_logic_vector (13 downto 0);
      per_din  : in  std_logic_vector (15 downto 0)
      );
  end component;

begin

  ------------------------------------------------------------------------------
  -- Module Body
  ------------------------------------------------------------------------------

  -- DUT WB
  gpio_bb : peripheral_gpio_bb
    port map (
      p1_dout => p1_dout,
      p2_dout => p2_dout,
      p3_dout => p3_dout,
      p4_dout => p4_dout,
      p5_dout => p5_dout,
      p6_dout => p6_dout,

      p1_dout_en => p1_dout_en,
      p2_dout_en => p2_dout_en,
      p3_dout_en => p3_dout_en,
      p4_dout_en => p4_dout_en,
      p5_dout_en => p5_dout_en,
      p6_dout_en => p6_dout_en,

      p1_sel => p1_sel,
      p2_sel => p2_sel,
      p3_sel => p3_sel,
      p4_sel => p4_sel,
      p5_sel => p5_sel,
      p6_sel => p6_sel,

      p1dir => p1dir,
      p1ifg => p1ifg,

      p1_din => p1_din,
      p2_din => p2_din,
      p3_din => p3_din,
      p4_din => p4_din,
      p5_din => p5_din,
      p6_din => p6_din,

      irq_port1 => irq_port1,
      irq_port2 => irq_port2,

      per_dout => per_dout,
      mclk     => mclk,
      per_en   => per_en,
      puc_rst  => puc_rst,
      per_we   => per_we,
      per_addr => per_addr,
      per_din  => per_din
      );
end rtl;
