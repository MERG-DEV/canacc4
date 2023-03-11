define(test_name, slim_modify_test)dnl
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
      wait for 28609 ms;
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
      RB4 <= '1'; -- Learn off
      RA5 <= '1'; -- Unlearn off
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      report("test_name: Enter learn mode");
      --
      data_file_open(modify.dat)
      --
      report("test_name: Modify events");
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        data_file_report_line
        --
        RXB0D0 <= 16#D2#;    -- EVLRN, CBUS learn event
        read(data_file, RXB0D1, 1);
        read(data_file, RXB0D2, 1);
        read(data_file, RXB0D3, 1);
        read(data_file, RXB0D4, 1);
        read(data_file, RXB0D5, 1);
        read(data_file, RXB0D6, 1);
        rx_frame(7)
        tx_check_no_message(776)
        --
        wait until PORTC != 0 for 1005 ms;
        if PORTC != 0 then
          report("test_name: Unexpected trigger");
          test_state := fail;
          wait until PORTC == 0;
        end if;
        --
        while match(file_line, "Done") == false loop
          readline(data_file, file_line);
        end loop;
      end loop;
      --
      file_close(data_file);
      --
      report("test_name: Exit learn mode");
      rx_data(16#54#, 4, 2) -- NNULN, exit learn mode, node 4 2
      --
      data_file_open(learnt_events.dat)
      --
      report("test_name: Check events are unchanged");
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
      file_close(data_file);
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
