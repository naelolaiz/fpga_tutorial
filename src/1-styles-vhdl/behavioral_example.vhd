library ieee;
use ieee.std_logic_1164.all;

entity behavioral_example is
 port ( Button1 : in std_logic;
        Button2 : in std_logic;
        Button3 : in std_logic;
        Led : out std_logic
        );
 end;

 architecture behavioral of behavioral_example is
 begin
  MyProcess : process (Button1, Button2, Button3)
  begin
    if (Button1 = '0' and Button2 = '0') or (Button3 ='0') then
        Led <= '0';
    else
        Led <= '1';
    end if;
  end process;
 end behavioral;
