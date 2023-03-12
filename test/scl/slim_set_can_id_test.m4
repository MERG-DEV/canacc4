define(test_name, slim_set_can_id_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(813)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    begin
      report("test_name: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      report("test_name: Check CAN Id");
      rx_data(16#73#, 0, 0, 0) -- RQNPN, CBUS read node parameter by index, node 0 0, index 0 == number of parameters
      tx_can_id(initial, 16#B0#, 16#00#)
      --
      report("test_name: Set CAN Id");
      rx_data(16#75#, 0, 0, 3) -- CBUS set CAN Id, node 0 0, new CAN Id = 3
      tx_check_no_message(776)
      --
      report("test_name: Verify CAN Id unchanged");
      rx_data(16#73#, 0, 0, 0) -- RQNPN, CBUS read node parameter by index, node 0 0, index 0 == number of parameters
      tx_can_id(unchanged, 16#B0#, 16#00#)
      --
      end_test
    end process test_name;
end testbench;
