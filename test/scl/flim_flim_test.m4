set_test_name()dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(1609)
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
      wait until flim_led == '1';
      report("test_name: Booted into FLiM");
      --
      setup_button <= '0';
      report("test_name: Setup button pressed");
      wait for 1 sec;
      setup_button <= '1';
      report("test_name: Setup button released");
      --
      report("test_name: Awaiting RTR");
      tx_rtr
      tx_check_can_id(default, 16#BF#, 16#E0#)
      --
      report("test_name: Awaiting Node Number request");
      tx_wait_for_node_message(OPC_RQNN, 4, 2) -- RQNN, CBUS request Node Number, node 0 0
      report("test_name: RQNN request");
      tx_check_can_id(new, 16#B0#, 16#20#)
      --
      report("test_name: Set Node Number");
      rx_data(OPC_SNN, 9, 8) -- SNN, CBUS set node number, node 4 2
      --
      report("test_name: Awaiting Node Number acknowledge");
      tx_wait_for_node_message(OPC_NNACK, 9, 8) -- NNACK, CBUS node number acknowledge, node 4 2
      report("test_name: Node number response");
      tx_check_can_id(acknowledge, 16#B0#, 16#20#)
      --
      if flim_led == '0' then
        report("test_name: Awaiting yellow LED (FLiM)");
        wait until flim_led == '1';
      end if;
      report("test_name: Yellow LED (FLiM) on");
      --
      if slim_led == '1' then
        report("test_name: Green LED (SLiM) on");
        test_state := fail;
      end if;
      --
      end_test
    end process test_name;
end testbench;
