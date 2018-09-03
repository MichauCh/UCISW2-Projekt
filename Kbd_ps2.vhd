----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:25:59 05/21/2018 
-- Design Name: 
-- Module Name:    Kbd_ps2 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Kbd_ps2 is
    Port ( Clock : in  STD_LOGIC;
           KbdClock : in  STD_LOGIC;
           KbdData : in  STD_LOGIC;
           LPaddleDir : buffer integer;
           RPaddleDir : buffer integer;
           GamePaused : buffer integer);
end Kbd_ps2;

architecture Behavioral of Kbd_ps2 is

signal bitCount : integer range 0 to 10 :=0;
signal scancodeReady : STD_LOGIC := '0';
signal scancode : STD_LOGIC_VECTOR(7 downto 0);
signal breakReceived : STD_LOGIC := '0';

constant kbW : STD_LOGIC_VECTOR(7 downto 0) := "00011101";
constant kbS : STD_LOGIC_VECTOR(7 downto 0) := "00011011";
constant kbI : STD_LOGIC_VECTOR(7 downto 0) := "01000011";
constant kbK : STD_LOGIC_VECTOR(7 downto 0) := "01000010";
constant kbGameBreak : STD_LOGIC_VECTOR(7 downto 0) := "00101001";


begin 

   ReadBits : process(KbdClock)
   begin
      if falling_edge(KbdClock) then
         if bitCount = 0 and KbdData = '0' then
           scancodeReady <= '0';
           bitCount <= bitCount + 1;
         elsif bitCount > 0 and bitCount < 9 then
            scancode <= KbdData & scancode(7 downto 1);
            bitCount <= bitCount + 1;
         elsif bitCount = 9 then
            bitCount <= bitCount +1;
         elsif bitCount = 10 then
            scancodeReady <= '1';
            bitCount <= 0;
         end if;
       end if;
   end process ReadBits;

   HandleInput : process(scancode, scancodeReady)
   begin
      if scancodeReady'event and scancodeReady = '1' then
         if breakReceived = '1' then
            breakReceived <= '0';
            if scancode = kbW or scancode = kbS then
               LPaddleDir <= 0;
            elsif scancode = kbI or scancode = kbK then
               RPaddleDir <= 0;
            elsif scancode = kbGameBreak then
               GamePaused <= 0;
            end if;
         elsif breakReceived = '0' then
            if scancode = "11110000" then
               breakReceived <= '1';
            end if;
            
            if scancode = kbW then
               LPaddleDir <= -1;
            elsif scancode = kbS then
               LPaddleDir <= 1;
               
            elsif scancode = kbI then
               RPaddleDir <= -1;
            elsif scancode = kbK then
               RPaddleDir <= 1;
               
            elsif scancode = kbGameBreak then
               GamePaused <= 1;
            end if;
         end if;
      end if;
            
   end process HandleInput;

end Behavioral;

