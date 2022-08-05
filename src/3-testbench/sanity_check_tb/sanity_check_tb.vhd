library ieee;
use ieee.std_logic_1164.all;

entity sanity_check_tb is
end sanity_check_tb;

architecture tb of sanity_check_tb is
begin
   triggerError : process
   begin
     wait for 100 us;
     assert(false) report "SANITY CHECK ERROR TRIGGERED!" severity error;
     wait;
   end process;
end tb;
