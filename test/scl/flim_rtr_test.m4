define(test_name, patsubst(__file__, {.m4},))dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(3)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    variable test_sidl : integer;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      dolearn_switch <= '1'; -- DOLEARN off
      unlearn_switch <= '1'; -- UNLEARN off
      --
      wait until flim_led == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      report("test_name: Receive RTR");
      rx_rtr
      tx_wait_for_rtr_response(16#B1#, 16#80#)
      --
      end_test
    end process test_name;
end testbench;
