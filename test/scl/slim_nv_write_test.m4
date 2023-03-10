define(test_name, slim_nv_write_test)dnl
include(common.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  test_timeout: process is
    begin
      wait for 873 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    begin
      report("test_name: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- Learn off
      RA5 <= '1'; -- Unlearn off
     --
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      report("test_name: Change 3A fire time");
      rx_data(16#96#, 0, 0, 5, 2) -- NVSET, CBUS set node variable by index, node 0 0, index = output 3A fire time
      tx_check_no_message(776)
      --
      report("test_name: Test long off 0x0102,0x0204, trigger 3A");
      rx_data(16#91#, 1, 2, 2, 4) -- ACOF, CBUS long off, node 1 2, event 2 4
      --
      wait until PORTC != 0;
      if PORTC == 32 then
        report("test_name: Triggered 3A");
      else
        report("test_name: Wrong output");
        test_state := fail;
      end if;
      wait until PORTC == 0 for 25 ms;
      if PORTC == 0 then
        report("test_name: Trigger too short");
        test_state := fail;
      end if;
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
