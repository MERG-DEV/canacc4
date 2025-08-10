set_test_name()dnl
configuration for "processor_type" is
  shared label    main_loop;
  shared label    setup;
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(29376)
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
      wait until slim_led == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      setup_button <= '0';
      report("test_name: Setup button pressed");
      wait until slim_led == '0';
      report("test_name: FLiM setup started");
      --
      setup_button <= '1'; -- Setup button released
      report("test_name: Setup button released, awaiting RTR");
      tx_rtr
      tx_check_can_id(default, 16#BF#, 16#E0#)
      --
      test_sidh := 0;
      test_sidl := 16#20#;
        while test_sidl < 16#100# loop
          rx_sid(test_sidh, test_sidl)
          test_sidl := test_sidl + 16#20#;
        end loop;
        test_sidh := 1;
        test_sidl := 0;
        while test_sidl < 16#80# loop
          rx_sid(test_sidh, test_sidl)
          test_sidl := test_sidl + 16#20#;
        end loop;
      rx_sid(test_sidh, 16#A0#)
      report("test_name: RTR, first free CAN Id is 12");
      --
      report("test_name: Waiting for Node Number request");
      tx_wait_for_node_message(OPC_RQNN, 0, 0) -- RQNN, CBUS request Node Number, node 0 0
      report("test_name: RQNN request");
      tx_check_can_id(new, 16#B1#, 16#80#)
      --
      report("test_name: Request Node Parameters");
      rx_data(OPC_RQNP, 0, 0) -- RQNP, CBUS node parameters request, node 0 0
      tx_wait_for_message(OPC_PARAMS, response, 165, manufacturer id, 114, minor version, 8, module id, 128, number of events allowed, 2, number of variables per event, 16, number of node variables, 2, major version) -- PARAMS, CBUS node parameters response
      --
      report("test_name: Request Module Name");
      rx_data(OPC_RQMN, 0, 0) -- RQMN, CBUS module name request, node 0 0
      report("test_name: Name request");
      tx_wait_for_message(OPC_NAME, response, 65, name [0], 67, name [1], 67, name [2], 52, name [3], 95, name [4], 50, name [5], 32,  name [6]) -- NAME, CBUS module name response, CANACC4_2
      --
      wait until flim_led == '1';
      wait until flim_led == '0';
      wait until flim_led == '1';
      wait until flim_led == '0';
      report("test_name: Yellow LED (FLiM) flashing");
      --
      report("test_name: Set Node Number");
      rx_data(OPC_SNN, 4, 2) -- SNN, CBUS set node number, node 4 2
      --
      report("test_name: Awaiting Node Number Acknowledge");
      tx_wait_for_node_message(OPC_NNACK, 4, 2) -- NNACK, CBUS node number acknowledge, node 4 2
      report("test_name: Node number response");
      tx_check_can_id(acknowledge, 16#B1#, 16#80#)
      --
      wait until flim_led == '1';
      report("test_name: Yellow LED (FLiM) now on");
      --
      if slim_led == '1' then
        report("test_name: Green LED (SLiM) on");
        test_state := fail;
      end if;
      --
      report("test_name: Restart");
      wait until PC == main_loop;
      PC <= setup;
      --
      if flim_led == '1' then
        wait until flim_led == '0';
      end if;
      wait until flim_led == '1';
      report("test_name: Yellow LED (FLiM) back on");
      --
      report("test_name: Check Node Number and event space after restart");
      rx_data(OPC_NNEVN, 4, 2) -- NNEVN, CBUS request available event space, node 4 2
      --
      tx_wait_for_node_message(OPC_EVNLF, 4, 2, 123, available event space) -- EVLNF, CBUS available event space response, node 4 2
      --
      end_test
    end process test_name;
end testbench;
