define(test_name, patsubst(__file__, {.m4},))dnl
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
      setup_button <= '1'; -- Setup button not pressed
      dolearn_switch <= '1'; -- DOLEARN off
      unlearn_switch <= '1'; -- UNLEARN off
      --
      wait until slim_led == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      report("test_name: Check CAN Id");
      rx_data(OPC_RQNPN, 0, 0, 0) -- RQNPN, CBUS read node parameter by index, node 0 0, index 0 == number of parameters
      tx_can_id(initial, 16#B0#, 16#00#)
      --
      report("test_name: Set CAN Id");
      rx_data(OPC_CANID, 0, 0, 3) -- CBUS set CAN Id, node 0 0, new CAN Id = 3
      tx_check_no_message(776)
      --
      report("test_name: Verify CAN Id unchanged");
      rx_data(OPC_RQNPN, 0, 0, 0) -- RQNPN, CBUS read node parameter by index, node 0 0, index 0 == number of parameters
      tx_can_id(unchanged, 16#B0#, 16#00#)
      --
      end_test
    end process test_name;
end testbench;
