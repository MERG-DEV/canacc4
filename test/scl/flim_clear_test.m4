define(test_name, flim_clear_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
include(io.inc)dnl
include(hardware.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(16934)
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
      dolearn_switch <= '1'; -- Learn off
      unlearn_switch <= '1'; -- Unlearn off
      --
      wait until flim_led == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      report("test_name: Reject clear events request");
      rx_data(16#55#, 4, 2) -- NNCLR, CBUS clear events to node 4 2
      tx_wait_for_node_message(16#6F#, 4, 2, 2, error number) -- CMDERR, CBUS error response
      --
      report("test_name: Check available event space");
      rx_data(16#56#, 4, 2) -- NNEVN, CBUS request available event space to node 4 2
      tx_wait_for_node_message(16#70#, 4, 2, 123) -- EVLNF, CBUS available event space response
      --
      report("test_name: Check number of stored events");
      rx_data(16#58#, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(16#74#, 4, 2, 5, number of stored events) -- NNEVN, CBUS number of stored events response
      --
      report("test_name: Enter learn mode");
      rx_data(16#53#, 4, 2) -- NNLRN, CBUS enter learn mode to node 4 2
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Clear events");
      rx_data(16#55#, 4, 2) -- NNCLR, CBUS clear events to node 4 2
      tx_wait_for_node_message(16#59#, 4, 2) -- WRACK, CBUS write acknowledge response
      --
      report("test_name: Exit learn mode");
      rx_data(16#54#, 4, 2) -- NNULN, exit learn mode to node 4 2
      --
      report("test_name: Reheck available event space");
      rx_data(16#56#, 4, 2) -- NNEVN, CBUS request available event space to node 4 2
      tx_wait_for_node_message(16#70#, 4, 2, 128) -- EVLNF, CBUS available event space response
      --
      report("test_name: Reheck number of stored events");
      rx_data(16#58#, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(16#74#, 4, 2, 0, number of stored events) -- NNEVN, CBUS number of stored events response
      --
      report("test_name: Check events are now ignored");
      data_file_open(learnt_events.dat)
      --
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        data_file_report_line
        rx_data_file_event
        --
        readline(data_file, file_line);
        while match(file_line, "Done") == false loop
          readline(data_file, file_line);
        end loop;
        --
        output_check_no_pulse(PORTC, 1005)
      end loop;
      --
      end_test
    end process test_name;
end testbench;
