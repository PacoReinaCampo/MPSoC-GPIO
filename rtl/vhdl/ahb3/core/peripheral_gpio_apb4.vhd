-- Converted from verilog/peripheral_gpio_apb4/peripheral_gpio_apb4.sv
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
--              Peripheral-GPIO for MPSoC                                     //
--              General Purpose Input Output for MPSoC                        //
--              AMBA4 APB-Lite Bus Interface                                  //
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
-- *   Paco Reina Campo <pacoreinacampo@queenfield.tech>
-- */

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity peripheral_gpio_apb4 is
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
end peripheral_gpio_apb4;

architecture RTL of peripheral_gpio_apb4 is
  --////////////////////////////////////////////////////////////////
  --
  -- Constants
  --

  --Interrupt-on-change
  constant MODE      : std_logic_vector(63 downto 0) := X"0000000000000000";
  constant DIRECTION : std_logic_vector(63 downto 0) := X"0000000000000001";
  constant OUTPUTS   : std_logic_vector(63 downto 0) := X"0000000000000002";
  constant INPUTS    : std_logic_vector(63 downto 0) := X"0000000000000003";
  constant IOC       : std_logic_vector(63 downto 0) := X"0000000000000004";
  constant IPENDING  : std_logic_vector(63 downto 0) := X"0000000000000005";  --Interrupt-pending

  --number of synchronisation flipflop stages on GPIO inputs
  constant INPUT_STAGES : integer := 3;

  --////////////////////////////////////////////////////////////////
  --
  -- Variables
  --

  --Control registers
  signal mode_reg : std_logic_vector(PDATA_SIZE-1 downto 0);
  signal dir_reg  : std_logic_vector(PDATA_SIZE-1 downto 0);
  signal out_reg  : std_logic_vector(PDATA_SIZE-1 downto 0);
  signal in_reg   : std_logic_vector(PDATA_SIZE-1 downto 0);

  --Input register, to prevent metastability
  signal input_regs : std_logic_vector(INPUT_STAGES*PDATA_SIZE-1 downto 0);

  --////////////////////////////////////////////////////////////////
  --
  -- Functions
  --

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

  -- Is this a valid write to address 0x...?
  -- Take 'address' as an argument
  function is_write_to_adr (
    PSEL_S    : std_logic;
    PENABLE_S : std_logic;
    PWRITE_S  : std_logic;
    PADDR_S   : std_logic_vector(PADDR_SIZE-1 downto 0);
    bits      : integer;
    address   : std_logic_vector(PADDR_SIZE-1 downto 0)

    ) return std_logic is
    variable is_write : std_logic;
    variable mask     : std_logic_vector(PADDR_SIZE-1 downto 0);

    variable is_write_to_adr_return : std_logic;
  begin
    --only 'bits' LSBs should be '1'
    is_write := PSEL_S and PENABLE_S and PWRITE_S;
    mask := std_logic_vector(to_unsigned(2**bits-1, PADDR_SIZE));
    is_write_to_adr_return := is_write and to_stdlogic((PADDR_S and mask) = (address and mask));
    return is_write_to_adr_return;
  end function is_write_to_adr;

  -- What data is written?
  -- Handles PSTRB, takes previous register/data value as an argument
  function get_write_value (
    PSTRB_S  : std_logic;
    PWDATA_S : std_logic_vector(PDATA_SIZE-1 downto 0);
    orig_val : std_logic_vector(PDATA_SIZE-1 downto 0)
    ) return std_logic_vector is
    variable get_write_value_return : std_logic_vector (PDATA_SIZE-1 downto 0);
  begin
    if (PSTRB_S = '1') then
      get_write_value_return := PWDATA_S;
    else
      get_write_value_return := orig_val;
    end if;
    return get_write_value_return;
  end function get_write_value;

begin
  --////////////////////////////////////////////////////////////////
  --
  -- Module Body
  --

  --APB accesses

  --The core supports zero-wait state accesses on all transfers.
  --It is allowed to driver PREADY with a steady signal
  PREADY  <= '1';  --always ready
  PSLVERR <= '0';  --Never an error

  --APB Writes

  --APB write to Mode register
  processing_0 : process (PCLK, PRESETn)
  begin
    if (PRESETn = '0') then
      mode_reg <= (others => '0');
    elsif (rising_edge(PCLK)) then
      if (is_write_to_adr(PSEL, PENABLE, PWRITE, PADDR, 2, MODE) = '1') then
        mode_reg <= get_write_value(PSTRB, PWDATA, mode_reg);
      end if;
    end if;
  end process;

  --APB write to Direction register
  processing_1 : process (PCLK, PRESETn)
  begin
    if (PRESETn = '0') then
      dir_reg <= (others => '0');
    elsif (rising_edge(PCLK)) then
      if (is_write_to_adr(PSEL, PENABLE, PWRITE, PADDR, 2, DIRECTION) = '1') then
        dir_reg <= get_write_value(PSTRB, PWDATA, dir_reg);
      end if;
    end if;
  end process;

  --APB write to Output register
  --treat writes to Input register same
  processing_2 : process (PCLK, PRESETn)
  begin
    if (PRESETn = '0') then
      out_reg <= (others => '0');
    elsif (rising_edge(PCLK)) then
      if (is_write_to_adr(PSEL, PENABLE, PWRITE, PADDR, 2, OUTPUTS) = '1') or (is_write_to_adr(PSEL, PENABLE, PWRITE, PADDR, 2, INPUTS) = '1') then
        out_reg <= get_write_value(PSTRB, PWDATA, out_reg);
      end if;
    end if;
  end process;

  --APB Reads
  processing_3 : process (PCLK)
  begin
    if (rising_edge(PCLK)) then
      case (PADDR) is
        when MODE =>
          PRDATA <= mode_reg;
        when DIRECTION =>
          PRDATA <= dir_reg;
        when OUTPUTS =>
          PRDATA <= out_reg;
        when INPUTS =>
          PRDATA <= in_reg;
        when others =>
          null;
      end case;
    end if;
  end process;

  --Internals INPUT_STAGES*PDATA_SIZE
  generating_0 : for n in 0 to INPUT_STAGES - 1 generate
    processing_4 : process (PCLK)
    begin
      if (rising_edge(PCLK)) then
        if (n = 0) then
          input_regs((n+1)*PDATA_SIZE-1 downto n*PDATA_SIZE) <= gpio_i;
        else
          input_regs((n+1)*PDATA_SIZE-1 downto n*PDATA_SIZE) <= input_regs(n*PDATA_SIZE-1 downto (n-1)*PDATA_SIZE);
        end if;
      end if;
    end process;
  end generate;

  processing_5 : process (PCLK)
  begin
    if (rising_edge(PCLK)) then
      in_reg <= input_regs(INPUT_STAGES*PDATA_SIZE-1 downto (INPUT_STAGES-1)*PDATA_SIZE);
    end if;
  end process;

  -- mode
  -- 0=push-pull    drive out_reg value onto transmitter input
  -- 1=open-drain   always drive '0' onto transmitter

  processing_6 : process (PCLK)
    variable mode_out : std_logic_vector(PDATA_SIZE-1 downto 0);
  begin
    if (rising_edge(PCLK)) then
      if (mode_reg = (mode_reg'range => '1')) then
        gpio_o <= (others => '0');
      else
        gpio_o <= out_reg;
      end if;
    end if;
  end process;

  -- direction  mode          out_reg
  -- 0=input                           disable transmitter-enable (output enable)
  -- 1=output   0=push-pull            always enable transmitter
  --            1=open-drain  1=Hi-Z   disable transmitter
  --                          0=low    enable transmitter

  processing_7 : process (PCLK)
    variable mode_out : std_logic_vector(PDATA_SIZE-1 downto 0);
  begin
    if (rising_edge(PCLK)) then
      gpio_oe <= dir_reg and not mode_out;
      if (mode_reg = (mode_reg'range => '1')) then
        mode_out := out_reg;
      else
        mode_out := (others => '0');
      end if;
    end if;
  end process;
end RTL;
