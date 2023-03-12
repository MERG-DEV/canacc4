define(test_name, slim_boot_ignore_unlearn_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(23286)
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
      RB4 <= '0'; -- DOLEARN on
      RA5 <= '0'; -- UNLEARN on
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
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
          data_file_read(trigger_val)
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
        wait on PORTC for 1005 ms;
        if PORTC != 0 then
          report("test_name: Unexpected trigger");
          test_state := fail;
          wait until PORTC == 0;
        end if;
      end loop;
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
