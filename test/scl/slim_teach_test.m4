define(test_name, slim_teach_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
include(io.inc)dnl
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
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- Learn off
      RA5 <= '1'; -- Unlearn off
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      report("test_name: Enter learn mode");
      rx_data(16#53#, 0, 0) -- NNLRN, CBUS enter learn mode, node 0 0
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Teach long 0x0102,0x0402");
      rx_data(16#D2#, 1, 2, 4, 2, 1, 4) -- EVLRN, CBUS learn event, node 1 2, event 4 2, variable 1 value 4
      tx_check_no_message(776) -- Test if response sent
      --
      report("test_name: Exit learn mode");
      rx_data(16#54#, 0, 0) -- NNULN, CBUS exit learn mode, node 0 0
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Test long on 0x0102,0x0402");
      rx_data(16#90#, 1, 2 , 4, 2) -- ACON, CBUS long on, node 1 2, event 4 2
      --
      output_check_no_pulse(PORTC, 1005)
      --
      end_test
    end process test_name;
end testbench;
