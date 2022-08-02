library ieee;
use ieee.std_logic_1164.all;

entity dataflow_example is
 port ( Button1 : in std_logic;
        Button2 : in std_logic;
        Button3 : in std_logic;
        Led : out std_logic
        );
 end;

 architecture logic of dataflow_example is
 begin
  Led <= not (((not Button1) and (not Button2)) or (not Button3));
 end logic;
