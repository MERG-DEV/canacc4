include(common.inc)dnl
define(test_name, slim_teach_test)dnl
include(rx_tx.inc)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 2661 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state   : test_result;
    file     event_file   : text;
    variable file_stat    : file_open_status;
    variable file_line    : string;
    variable report_line  : string;
    variable trigger_line : string;
    variable trigger_val  : integer;
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
      report("test_name: Enter learn mode");
      rx_data(16#53#, 0, 0) -- NNLRN, CBUS enter learn mode, node 0 0
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Teach long 0x0102,0x0402");
      rx_data(16#D2#, 1, 2, 4, 2, 1, 4) -- EVLRN, CBUS learn event, node 1 2, event 4 2, variable 1 value 4
      tx_check_no_message(776) -- Test if response sent
      --
      report("test_name: Exit learn mode");
      rx_data(16#54#, 0, 0) -- NNULN, CBUS exit learn mode, node 0 0
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Test long on 0x0102,0x0402");
      rx_data(16#90#, 1, 2 , 4, 2) -- ACON, CBUS long on, node 1 2, event 4 2
      --
      wait until PORTC != 0 for 1005 ms;
      if PORTC != 0 then
        report("test_name: Unexpected trigger");
        test_state := fail;
        wait until PORTC == 0;
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
