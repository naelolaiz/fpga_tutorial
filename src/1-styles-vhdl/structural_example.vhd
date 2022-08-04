library ieee;
use ieee.std_logic_1164.all;

entity structural_example is
 port ( Button1 : in std_logic;
        Button2 : in std_logic;
        Button3 : in std_logic;
        Led : out std_logic
        );
 end;

 architecture structural of structural_example is
--    component OR2
--       port (IN1, IN2 : in std_logic;
--             OUT1     : inout std_logic);
--    end component;

--    component AND2
--       port (IN1, IN2 : in std_logic;
--             OUT1     : inout std_logic);
--    end component;

    component not_gate
       port (i1 : in std_logic;
             o1 : out std_logic);
    end component;

  signal sOutAnd : std_logic := '0';
  signal sLed    : std_logic := '0';

 begin
    
    andInstance : AND2
    port map(IN1 => not Button1,
             IN2 => not Button2); --,
--             OUT => sOutAnd);

    orInstance : OR2
    port map(IN1 => sOutAnd,
             IN2 => not Button3); --,
--             OUT => sLed);

    notInstance : not_gate
    port map (i1 => sLed,
              o1 => Led);

 end structural;
