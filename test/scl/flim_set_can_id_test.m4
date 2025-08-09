define(test_name, flim_set_can_id_test)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(782)
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
      report("test_name: Check CAN Id");
      rx_data(OPC_QNN) -- QNN, CBUS Query node request
      tx_can_id(initial, 16#B1#, 16#80#)
      --
      report("test_name: Set CAN Id");
      rx_data(OPC_CANID, 4, 2, 3) -- CBUS set CAN Id request, node 4 2, CAN Id 3
      --
      tx_wait_for_node_message(OPC_NNACK, 4, 2) -- NNACK, CBUS node number acknowledge, node 4 2
      tx_check_can_id(NN acknowledge, 16#B0#, 16#60#)
      --
      end_test
    end process test_name;
end testbench;
