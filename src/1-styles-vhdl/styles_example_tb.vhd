library ieee;
use ieee.std_logic_1164.all;

-- test bench level entity
entity styles_example_tb is
end;

architecture tb of styles_example_tb is
   signal sA, sB, sC : std_logic := '1';
   signal sLedBehavioral, sLedDataflow, sLedStructural : std_logic := '1';
   signal sQ : std_logic := '0';
   signal sI : integer;

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
     port map (Button1 => sA,
               Button2 => sB, 
               Button3 => sC, 
               Led  => sLedBehavioral);

  structuralInstance : entity work.structural_example(structural)
     port map (Button1 => sA,
               Button2 => sB, 
               Button3 => sC, 
               Led  => sLedStructural);

  dataflowInstance : entity work.dataflow_example(logic)
     port map (Button1 => sA,
               Button2 => sB, 
               Button3 => sC, 
               Led  => sLedDataflow);

    tb : process
    begin
        for i in test_vectors'range loop
            sI <= i;
            sA <= test_vectors(i).a;
            sB <= test_vectors(i).b;
            sC <= test_vectors(i).c;
            sQ <= test_vectors(i).q;

            wait for 10 ns;

            assert ( 
                     sLedBehavioral = sLedDataflow
                     and sLedBehavioral = sLedStructural
                     and sLedStructural = sQ
                    )
            report  "error detected! "
                     & "i: " & integer'image(sI)
                     & ". Inputs: "
                     & std_logic'image(sA) 
                     & ", " 
                     & std_logic'image(sB) 
                     & ", " 
                     & std_logic'image(sC) 
                     & ". behavioral: " 
                     & std_logic'image(sLedBehavioral) 
                     & ", dataflow: " 
                     & std_logic'image(sLedDataflow)
                     & ", structural: " 
                     & std_logic'image(sLedStructural) 
                     & ", expected: " 
                     & std_logic'image(sQ) 

                    severity error;
        end loop;
        report "Simulation done!" severity note;
        wait;
    end process; 
               
end tb;

