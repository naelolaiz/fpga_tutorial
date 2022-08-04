library ieee;
use ieee.std_logic_1164.all;


-- counts up to CYCLES_FROM_TRIGGER_TO_SET_OUTPUT of inClock, and set outTimer to 1 afterwards
entity one_time_timer is
  generic (CYCLES_FROM_TRIGGER_TO_SET_OUTPUT : integer := 50E6);
  port    (inClock : in std_logic;
           inTimerEnabled : in std_logic;
           inReset : in std_logic;
           outTimer: out std_logic);
end;

architecture logic of one_time_timer is
begin
  TimerProcess : process (inClock, inReset)
    variable cyclesCount : integer range 0 to CYCLES_FROM_TRIGGER_TO_SET_OUTPUT := 0;
  begin
    if inReset = '1' then
      outTimer <= '0';
      cyclesCount := 0;
    elsif rising_edge(inClock) then
      if cyclesCount < CYCLES_FROM_TRIGGER_TO_SET_OUTPUT then
        cyclesCount := cyclesCount + 1;
        outTimer <= '0';
      else
        outTimer <= '1';
      end if;
    end if;
  end process;

end logic;

---------

-- top level entity
library ieee;
use ieee.std_logic_1164.all;

entity toplevel_timer is
  generic (CYCLES_FROM_TRIGGER_TO_SET_OUTPUT : integer := 100E6);
  port (inClock50Mhz : in std_logic;
        inNoReset    : in std_logic; 
        outLed       : out std_logic);        
end;

architecture logic of toplevel_timer is
  signal sTimerOut : std_logic;
  signal sReset : std_logic;
begin

sReset <= not inNoReset;

timerInstance : entity work.one_time_timer(logic)
  generic map (CYCLES_FROM_TRIGGER_TO_SET_OUTPUT => CYCLES_FROM_TRIGGER_TO_SET_OUTPUT)
  port map    (inClock => inClock50Mhz,
               inTimerEnabled => inNoReset,
               inReset => sReset,
               outTimer => sTimerOut);
  outLed <= sTimerOut;
end logic;

