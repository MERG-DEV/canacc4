define(test_name, patsubst(__file__, {.m4},))dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(1182)
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
      report("test_name: Check initial CAN Id");
      rx_data(OPC_QNN) -- QNN, CBUS Query node request)
      --
      tx_wait_if_not_ready
      tx_check_can_id(initial, 16#B1#, 16#80#)

      report("test_name: Request enumerate");
      rx_data(OPC_ENUM, 4, 2) -- CBUS enumerate request to node 4 2
      --
      tx_rtr
      tx_check_can_id(default, 16#BF#, 16#E0#)
      --
      test_sidl := 16#20#;
      while test_sidl < 16#60# loop
        rx_sid(0, test_sidl)
        test_sidl := test_sidl + 16#20#;
      end loop;
      rx_sid(0, 16#80#)
      report("test_name: RTR, first free CAN Id is 3");
      --
      tx_wait_for_node_message(OPC_NNACK, 4, 2) -- NNACK, CBUS node number acknowledge
      tx_check_can_id(new CAN Id, 16#B0#, 16#60#)
      --
      end_test
    end process test_name;
end testbench;
