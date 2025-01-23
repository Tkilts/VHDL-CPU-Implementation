----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/21/2024 08:00:54 PM
-- Design Name: 
-- Module Name: cpu_top_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cpu_top_tb is
--  Port ( );
end cpu_top_tb;

architecture Behavioral of cpu_top_tb is

component cpu_top is
    port(clk      : in  std_logic; -- cpu clock
        clk50    : in std_logic;  -- display clock (50 MHz)
        reset    : in  std_logic;
        an       : out std_logic_vector(3 downto 0); -- Anode for 7-segment display
        CA, CB, CC, CD, CE, CF, CG : out  std_logic  -- 7-segment display cathodes
        );
end component;

        signal clk_tb : std_logic; -- cpu clock
        signal clk50_tb : std_logic;  -- display clock (50 MHz)
        signal reset_tb : std_logic;
        signal an_tb : std_logic_vector(3 downto 0); -- Anode for 7-segment display
        signal CA_tb, CB_tb, CC_tb, CD_tb, CE_tb, CF_tb, CG_tb : std_logic;  -- 7-segment display cathodes

begin

    dut: cpu_top port map(clk_tb, clk50_tb, reset_tb, an_tb, CA_tb, CB_tb,
                          CC_tb, CD_tb, CE_tb, CF_tb, CG_tb);
  
     initialize: process
     begin
        reset_tb <= '1';
        --clk_tb <= '0';
        wait for 10ns;
        --clk_tb <= '1';
        --wait for 10ns;
        --clk_tb <= '0';
        reset_tb <= '0';
        for i in 0 to 1000 loop
            clk_tb <= '0';
            wait for 10ns;
            clk_tb <= '1';
            wait for 10ns;
            clk_tb <= '0';
        end loop;
        wait;
     end process;
end Behavioral;


