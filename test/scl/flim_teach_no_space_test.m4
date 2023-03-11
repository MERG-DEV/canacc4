define(test_name, flim_teach_no_space_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  test_timeout: process is
    begin
      wait for 292 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    begin
      report("test_name: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- Learn off
      RA5 <= '1'; -- Unlearn off
      --
      wait until RB6 == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      report("test_name: Enter learn mode");
      rx_data(16#53#, 4, 2) -- NNLRN, CBUS enter learn mode to node 4 2
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Learn event");
      rx_data(16#D2#, 1, 2, 9, 128, 1, 4) -- EVLRN, CBUS learn event, node 1 2, event 9 128, variable index 1 - trigger bitmap, variable value 4 - trigger output pair 3
      tx_wait_for_node_message(16#59#, 4, 2) -- WRACK, CBUS write acknowledge response, node 4 2
      --
      wait until PORTC != 0;
      wait until PORTC == 0;
      --
      report("test_name: Learnt 128 events");
      --
      report("test_name: Cannot learn event 0x0102, 0x0981");
      rx_data(16#D2#, 1, 2, 9, 129, 1, 4) -- EVLRN, CBUS learn event, node 1 2, event 9 129, variable index 1 - trigger bitmap, variable value 4 - trigger output pair 3
      tx_wait_for_cmderr_message(4, 2, 4) -- CMDERR, CBUS error response, node 4 2, No event space left
      --
      -- FIXME yellow LED should flash
      --if RB6 == '0' then
      --  wait until RB6 == '1';
      --end if;
      --wait until RB6 == '1';
      --
      report("test_name: Cannot learn event 0x0000, 0x0982");
      rx_data(16#D2#, 0, 0, 9, 130, 1, 4) -- EVLRN, CBUS learn event, node 0 0, event 9 130, variable index 1 - trigger bitmap, variable value 4 - trigger output pair 3
      tx_wait_for_cmderr_message(4, 2, 4) -- CMDERR, CBUS error response, node 4 2, No event space left
      --
      -- FIXME yellow LED should flash
      --if RB6 == '0' then
      --  wait until RB6 == '1';
      --end if;
      --wait until RB6 == '1';
      --
      if test_state == pass then
        report("test_name: PASS");
      else
        report("test_name: FAIL");
      end if;
      PC <= 0;
      wait;
    end process test_name;
end testbench;
