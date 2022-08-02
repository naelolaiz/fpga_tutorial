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
    component or_gate
       port (i1, i2 : in std_logic;
             o1 : out std_logic);
    end component;

    component and_gate
       port (i1, i2 : in std_logic;
             o1 : out std_logic);
    end component;

    component not_gate
       port (i1 : in std_logic;
             o1 : out std_logic);
    end component;

  signal sOutAnd : std_logic := '0';
  signal sLed    : std_logic := '0';

 begin
    
    andInstance : and_gate
    port map(i1 => not Button1,
             i2 => not Button2,
             o1 => sOutAnd);

    orInstance : or_gate
    port map(i1 => sOutAnd,
             i2 => not Button3,
             o1 => sLed);

    notInstance : not_gate
    port map (i1 => sLed,
              o1 => Led);

 end structural;
