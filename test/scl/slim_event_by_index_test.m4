define(test_name, slim_event_by_index_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
include(hardware.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(811)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
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
      report("test_name: Read event");
      rx_data(16#72#, 0, 0, 1) -- NENRD, CBUS Read event by index request, node 0 0 , event index 1
      tx_check_no_message(776)
      --
      end_test
    end process test_name;
end testbench;
