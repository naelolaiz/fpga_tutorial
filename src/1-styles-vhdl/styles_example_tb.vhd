library ieee;
use ieee.std_logic_1164.all;

-- test bench level entity
entity styles_example_tb is
end;

architecture tb of styles_example_tb is
   signal sInButton1, sInButton2, sInButton3 : std_logic := '1';
   signal sLedBehavioral, sLedDataflow, sLedStructural : std_logic := '1';

    -- declare record type
    type test_vector is record
        a, b, c: std_logic;
        q : std_logic;
    end record; 

    type test_vector_array is array (natural range <>) of test_vector;
    constant test_vectors : test_vector_array := (
        -- a, b, c , q   -- positional method is used below
        ('0', '0', '0', '0'),
        ('0', '0', '1', '0'),
        ('0', '1', '0', '0'),
        ('0', '1', '1', '1'),
        ('1', '0', '0', '0'),
        ('1', '0', '1', '1'),
        ('1', '1', '0', '0'),
        ('1', '1', '1', '1')
        );
begin
  behavioralInstance : entity work.behavioral_example(behavioral)
     port map (Button1 => sInButton1,
               Button2 => sInButton2, 
               Button3 => sInButton3, 
               Led  => sLedBehavioral);

  structuralInstance : entity work.structural_example(structural)
     port map (Button1 => sInButton1,
               Button2 => sInButton2, 
               Button3 => sInButton3, 
               Led  => sLedStructural);

  dataflowInstance : entity work.dataflow_example(logic)
     port map (Button1 => sInButton1,
               Button2 => sInButton2, 
               Button3 => sInButton3, 
               Led  => sLedDataflow);

    tb : process
    begin
        for i in test_vectors'range loop
            sInButton1 <= test_vectors(i).a;
            sInButton2 <= test_vectors(i).b;
            sInButton2 <= test_vectors(i).b;

            wait for 20 ns;

            assert ( 
                     sLedBehavioral = sLedDataflow
                     and sLedBehavioral = sLedStructural
                     and sLedStructural = test_vectors(i).q
                    )
            report  "error detected"
                    severity error;
        end loop;
        wait;
    end process; 

               
end tb;

