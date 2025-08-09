define(test_name, flim_teach_no_space_test)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(292)
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
      report("test_name: Enter learn mode");
      rx_data(OPC_NNLRN, 4, 2) -- NNLRN, CBUS enter learn mode to node 4 2
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Learn event");
      rx_data(OPC_EVLRN, 1, 2, 9, 128, 1, 4) -- EVLRN, CBUS learn event, node 1 2, event 9 128, variable index 1 - trigger bitmap, variable value 4 - trigger output pair 3
      tx_wait_for_node_message(OPC_WRACK, 4, 2) -- WRACK, CBUS write acknowledge response, node 4 2
      output_wait_for_any_pulse(PORTC)
      --
      report("test_name: Learnt 128 events");
      --
      report("test_name: Cannot learn event 0x0102, 0x0981");
      rx_data(OPC_EVLRN, 1, 2, 9, 129, 1, 4) -- EVLRN, CBUS learn event, node 1 2, event 9 129, variable index 1 - trigger bitmap, variable value 4 - trigger output pair 3
      tx_wait_for_cmderr_message(4, 2, CMDERR_TOO_MANY_EVENTS) -- CBUS error response, node 4 2, No event space left
      --
      -- FIXME yellow LED should flash
      --if flim_led == '0' then
      --  wait until flim_led == '1';
      --end if;
      --wait until flim_led == '1';
      --
      report("test_name: Cannot learn event 0x0000, 0x0982");
      rx_data(OPC_EVLRN, 0, 0, 9, 130, 1, 4) -- EVLRN, CBUS learn event, node 0 0, event 9 130, variable index 1 - trigger bitmap, variable value 4 - trigger output pair 3
      tx_wait_for_cmderr_message(4, 2, CMDERR_TOO_MANY_EVENTS) -- CBUS error response, node 4 2, No event space left
      --
      -- FIXME yellow LED should flash
      --if flim_led == '0' then
      --  wait until flim_led == '1';
      --end if;
      --wait until flim_led == '1';
      --
      end_test
    end process test_name;
end testbench;
