define(test_name, patsubst(__file__, {.m4},))dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(2661)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      dolearn_switch <= '1'; -- Learn off
      unlearn_switch <= '1'; -- Unlearn off
      --
      wait until slim_led == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      report("test_name: Enter learn mode");
      rx_data(OPC_NNLRN, 0, 0) -- NNLRN, CBUS enter learn mode, node 0 0
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Teach long 0x0102,0x0402");
      rx_data(OPC_EVLRN, 1, 2, 4, 2, 1, 4) -- EVLRN, CBUS learn event, node 1 2, event 4 2, variable 1 value 4
      tx_check_no_message(776) -- Test if response sent
      --
      report("test_name: Exit learn mode");
      rx_data(OPC_NNULN, 0, 0) -- NNULN, CBUS exit learn mode, node 0 0
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Test long on 0x0102,0x0402");
      rx_data(OPC_ACON, 1, 2 , 4, 2) -- ACON, CBUS long on, node 1 2, event 4 2
      --
      output_check_no_pulse(PORTC, 1005)
      --
      end_test
    end process test_name;
end testbench;
