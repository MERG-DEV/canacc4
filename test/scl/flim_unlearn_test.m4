define(test_name, flim_unlearn_test)dnl
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
      wait for 25687 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state   : test_result;
    file     data_file    : text;
    variable file_stat    : file_open_status;
    variable report_line  : string;
    variable trigger_line : string;
    variable trigger_val  : integer;
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
      RB4 <= '0'; -- DOLEARN on
      RA5 <= '0'; -- UNLEARN on
      --
      data_file_open(unlearn.dat)
      --
      report("test_name: Unlearn events");
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        readline(data_file, report_line);
        report(report_line);
        read(data_file, RXB0D0, 1);
        read(data_file, RXB0D1, 1);
        read(data_file, RXB0D2, 1);
        read(data_file, RXB0D3, 1);
        read(data_file, RXB0D4, 1);
        rx_frame(5)
        --
        wait until PORTC != 0;
        wait until PORTC == 0;
      end loop;
      --
      file_close(data_file);
      --
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
      --
      data_file_open(learnt_events.dat)
      --
      report("test_name: Check remaining events");
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        readline(data_file, report_line);
        report(report_line);
        read(data_file, RXB0D0, 1);
        read(data_file, RXB0D1, 1);
        read(data_file, RXB0D2, 1);
        read(data_file, RXB0D3, 1);
        read(data_file, RXB0D4, 1);
        rx_frame(5)
        --
        readline(data_file, report_line);
        while match(report_line, "Done") == false loop
          readline(data_file, trigger_line);
          read(trigger_line, trigger_val);
          --
          wait until PORTC != 0;
          if PORTC == trigger_val then
            report(report_line);
         else
            report("slim_unlearn_test: Wrong output");
            test_state := fail;
          end if;
          wait until PORTC == 0;
          --
          readline(data_file, report_line);
        end loop;
        --
        wait until PORTC != 0 for 1005 ms;
        if PORTC != 0 then
          report("slim_unlearn_test: Unexpected trigger");
          test_state := fail;
          wait until PORTC == 0;
        end if;
      end loop;
      --
      if test_state == pass then
        report("test_name: PASS");
      else
        report("test_name: FAIL");
        report(PC); -- Crashes simulator, MDB will report current source line
      end if;
      PC <= 0;
      wait;
    end process test_name;
end testbench;
