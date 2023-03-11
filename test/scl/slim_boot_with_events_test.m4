define(test_name, slim_boot_with_events_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  test_timeout: process is
    begin
      wait for 24839 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    file     data_file   : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
    variable trigger_val : integer;
    begin
      report("test_name: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      data_file_open(learnt_events.dat)
      --
      report("test_name: Check events");
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        data_file_report_line
        rx_data_file_event
        --
        readline(data_file, file_line);
        while match(file_line, "Done") == false loop
          readline(data_file, file_line);
          read(file_line, trigger_val);
          --
          wait until PORTC != 0;
          if PORTC == trigger_val then
            report(file_line);
         else
            report("test_name: Wrong output");
            test_state := fail;
          end if;
          wait until PORTC == 0;
          --
          readline(data_file, file_line);
        end loop;
        --
        wait until PORTC != 0 for 1005 ms;
        if PORTC != 0 then
          report("test_name: Unexpected trigger");
          test_state := fail;
          wait until PORTC == 0;
        end if;
      end loop;
      --
      report("test_name: Request available event space");
      rx_data(16#56#, 0, 0) -- NNEVN, CBUS request available event space, node 0 0
      tx_check_no_message(776)
      --
      report("test_name: Request number of stored events");
      rx_data(16#58#, 0, 0) -- RQEVN, CBUS request number of stored events, node 0 0
      tx_check_no_message(776)
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
