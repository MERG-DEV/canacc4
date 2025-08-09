define(test_name, slim_clear_test)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(24046)
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
      dolearn_switch <= '1'; -- Learn off
      unlearn_switch <= '1'; -- Unlearn off
      --
      wait until slim_led == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      report("test_name: Enter learn mode");
      rx_data(OPC_NNLRN, 0, 0) -- NNLRN, CBUS enter learn mode, node 0 0
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Clear events");
      rx_data(OPC_NNCLR, 0, 0) -- NNCLR, CBUS clear events, node 0 0
      tx_check_no_message(776)
      --
      report("test_name: Exit learn mode");
      rx_data(OPC_NNULN, 0, 0) -- NNULN, exit learn mode, node 0 0
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      data_file_open(learnt_events.dat)
      --
      report("test_name: Check events");
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        data_file_report_line
        rx_data_file_event
        --
        output_wait_for_data_file_pulse(PORTC)
        --
        output_check_no_pulse(PORTC, 1005)
      end loop;
      --
      end_test
    end process test_name;
end testbench;
