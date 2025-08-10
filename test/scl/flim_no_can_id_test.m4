set_test_name()dnl
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
    variable test_sidh : integer;
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
      report("test_name: Request enumerate");
      rx_data(OPC_ENUM, 4, 2) -- CBUS enumerate request
      --
      report("test_name: Waiting for RTR");
      tx_rtr
      tx_check_can_id(default, 16#BF#, 16#E0#)
      --
      test_sidh := 0;
      test_sidl := 16#20#;
      while test_sidh < OPC_RQNP loop
        while test_sidl < 16#100# loop
          rx_sid(test_sidh, test_sidl)
          test_sidl := test_sidl + 16#20#;
        end loop;
        test_sidh := test_sidh + 1;
        test_sidl := 0;
      end loop;
      report("test_name: RTR, all CAN Ids taken");
      --
      tx_wait_for_cmderr_message(4, 2 ,CMDERR_INVALID_EVENT) -- CBUS error response, node 4 2, error 7
      tx_check_can_id(unchanged, 16#BF#, 16#E0#)
      --
      end_test
    end process test_name;
end testbench;
