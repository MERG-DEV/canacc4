define(test_name, flim_set_can_id_test)dnl
include(common.inc)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 782 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    variable test_sidl : integer;
    begin
      report("test_name: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
      --
      wait until RB6 == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      report("test_name: Check CAN Id");
      rx_data(16#0D#) -- QNN, CBUS Query node request
      tx_can_id(initial, 16#B1#, 16#80#)
      --
      report("test_name: Set CAN Id");
      rx_data(16#75#, 4, 2, 3) -- CBUS set CAN Id request, node 4 2, CAN Id 3
      --
      tx_wait_for_node_message(16#52#, 4, 2) -- NNACK, CBUS node number acknowledge, node 4 2
      tx_check_can_id(NN acknowledge, 16#B0#, 16#60#)
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
