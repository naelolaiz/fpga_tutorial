-- AND
library ieee;
use ieee.std_logic_1164.all;

entity and_gate is
port ( i1 : in std_logic;
       i2 : in std_logic;
       o1 : out std_logic
       );
end;
architecture dataflow_and of and_gate is
begin
  o1 <= i1 and i2;
end dataflow_and;

-- OR
library ieee;
use ieee.std_logic_1164.all;

entity or_gate is
port ( i1 : in std_logic;
       i2 : in std_logic;
       o1 : out std_logic
       );
end;
architecture dataflow_or of or_gate is
begin
  o1 <= i1 or i2;
end dataflow_or;

-- NOT
library ieee;
use ieee.std_logic_1164.all;

entity not_gate is
port ( i1 : in std_logic;
       o1 : out std_logic
       );
end;
architecture dataflow_not of not_gate is
begin
  o1 <= not i1;
end dataflow_not;
