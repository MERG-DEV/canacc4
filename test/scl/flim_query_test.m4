define(test_name, flim_query_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
include(hardware.inc)dnl
include(cbusdefs.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(777)
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
      wait until flim_led == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      report("test_name: Query Node");
      rx_data(OPC_QNN) -- QNN, CBUS Query node request
      tx_wait_for_node_message(OPC_PNN, 4, 2, 165, manufacturer id, 8, module id, 13, flags) -- PNN, CBUS Query node response
      --
      end_test
    end process test_name;
end testbench;
