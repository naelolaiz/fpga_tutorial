library ieee;
use ieee.std_logic_1164.all;

-- test bench level entity
entity toplevel_timer_tb is
end;

architecture tb of toplevel_timer_tb is
 -- signals for inputs
  signal sClock50Mhz    : std_logic := '0';
  signal sButtonTimerEnabled : std_logic := '1';
 -- signals for outputs
  signal sOutLed      : std_logic ; 
 -- signals for process
  signal sInputSignalForSimulationDone : boolean := false;
begin



-- instantiate device under test
  DUT : entity work.toplevel_timer(logic)
     generic map (CYCLES_FROM_TRIGGER_TO_SET_OUTPUT => 10)
     port map (inClock50Mhz => sClock50Mhz,
               inNoReset    => sButtonTimerEnabled, 
               outLed     => sOutLed);

-- generate input signals
  sClock50Mhz <= not sClock50Mhz after 10 ns;

  generatePressedButtons : process 
  begin
    sButtonTimerEnabled <= '0';
    wait for 30 ns;
    sButtonTimerEnabled <= '1';
    wait for 300 ns;
  end process;

  sInputSignalForSimulationDone <= false, true after 100 ms;

end tb;

