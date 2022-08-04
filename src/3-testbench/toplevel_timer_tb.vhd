library ieee;
use ieee.std_logic_1164.all;

-- test bench level entity
entity toplevel_timer_tb is
   generic (CYCLES_FROM_TRIGGER_TO_SET_OUTPUT : integer := 10;
            CYCLE_PERIOD : time := 20 ns);
end;

architecture tb of toplevel_timer_tb is
 -- signals for inputs
  signal sClock50Mhz    : std_logic := '0';
  signal sButtonTimerEnabled : std_logic := '1';
 -- signals for outputs
  signal sOutLed      : std_logic ; 
 -- signals for process
  signal sSimulationDone : boolean := false;

begin
-----------------------------------
-- instantiate device under test
  DUT : entity work.toplevel_timer(logic)
     generic map (CYCLES_FROM_TRIGGER_TO_SET_OUTPUT => CYCLES_FROM_TRIGGER_TO_SET_OUTPUT)
     port map (inClock50Mhz => sClock50Mhz,
               inNoReset    => sButtonTimerEnabled, 
               outLed       => sOutLed);

-----------------------------------
-- generate input signals
 -- boolean to terminate simulation after 3 ms
  sSimulationDone <= false, true after 3 ms;
 -- 50 MHz clock
  sClock50Mhz <= not sClock50Mhz after CYCLE_PERIOD / 2 when not sSimulationDone;
 -- process for button simulation: duty cycle: 50ns off, 2 * timer_timeout on.
  generatePressedButton : process 
  begin
    if not sSimulationDone then
      sButtonTimerEnabled <= '0', '1' after 50 ns;
      wait for CYCLE_PERIOD * CYCLES_FROM_TRIGGER_TO_SET_OUTPUT * 2; -- twice the needed time to expect the timer output enable
    else
      wait; -- blocks here
    end if;
  end process;

-----------------------------------
-- validate the output of the DUT

-- High impedance output when reset enabled
  validateTimerHighImpedanceOutputOnReset : process 
  begin
    wait until sButtonTimerEnabled = '0';
    wait for 1 ns; -- wait for the signal to be propagated
    assert (sOutLed = 'Z')
      report "Error0 : timer output not Z when disabled (reset on)" severity error;
  end process;

-- Start timer makes output low
  validateOutputLowOnStartTimer : process 
  begin
    wait until rising_edge(sButtonTimerEnabled);
    wait until rising_edge(sClock50Mhz);
    wait for 1 ns; -- wait for the signal to be propagated
    assert (sOutLed = '0')
      report "Error1 : timer output not 0 after a fresh reset" severity error;
  end process;

-- Triggered timer makes output high
  validateOutputHighAfterTimerDone : process 
    variable timeSinceLow : time := 0 ns;
    constant ALLOWED_DELTA : time := 1 ns;
  begin
    wait until sOutLed = '0';
    timeSinceLow := now;
    wait until rising_edge(sClock50Mhz);
    wait until sOutLed = '1';
    -- check that the timer was triggered on time
    assert (abs((now - timeSinceLow) - (CYCLES_FROM_TRIGGER_TO_SET_OUTPUT * CYCLE_PERIOD)) < ALLOWED_DELTA)
      report "Error2 : timer output not 1 after timeout period" severity error;
    -- check that the output is still 1 after four clocks
    for counter in 1 to 4 loop
       wait until rising_edge(sClock50Mhz);
       assert (sOutLed = '1')
         report "Error3 : timer output not kept 1 after timeout period" severity error;
     end loop;
  end process;

end tb;

