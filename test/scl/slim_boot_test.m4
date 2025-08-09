define(test_name, slim_boot_test)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  test_timeout: process is
    begin
      wait for 16958 ms;
      report("test_name: TIMEOUT");
      if flim_led == '1' then
        report("test_name: Yellow LED (FLiM) on");
      end if;
      report(PC); -- Crashes simulator, MDB will report current source line
      stop_test
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    file     data_file : text;
    variable file_stat  : file_open_status;
    variable file_line  : string;
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
      data_file_open(learnt_events.dat)
      --
      report("test_name: Check events");
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        data_file_report_line
        rx_data_file_event
        --
        while match(file_line, "Done") == false loop
          readline(data_file, file_line);
        end loop;
        --
        output_check_no_pulse(PORTC, 1005)
      end loop;
      --
      if flim_led == '1' then
        report("test_name: Yellow LED (FLiM) on");
        test_state := fail;
      end if;
      --
      end_test
    end process test_name;
end testbench;
