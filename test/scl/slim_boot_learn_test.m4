define(test_name, patsubst(__file__, {.m4},))dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(23286)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state     : test_result;
    file     data_file      : text;
    variable file_stat      : file_open_status;
    variable file_line      : string;
    variable pulse_report : string;
    variable pulse_val    : integer;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      dolearn_switch <= '0'; -- DOLEARN on
      unlearn_switch <= '1'; -- UNLEARN off
      --
      wait until slim_led == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      dolearn_switch <= '1'; -- DOLEARN off
      --
      data_file_open(learnt_events.dat)
      --
      report("test_name: Learn events");
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        data_file_report_line
        rx_data_file_event
        --
        output_wait_for_data_file_pulse(PORTC)
        output_check_no_pulse(PORTC, 1005)
      end loop;
      --
      end_test
    end process test_name;
end testbench;
