define(test_name, patsubst(__file__, {.m4},))dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(23964)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    file     data_file   : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
    variable pulse_val : integer;
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
      dolearn_switch <= '0';
      report("test_name: Learn switch on");
      --
      report("test_name: Do not learn events");
      data_file_open(learn.dat)
      --
      while endfile(data_file) == false loop
        data_file_report_line
        --
        readline(data_file, file_line);
        read(file_line, sel0_switch);
        readline(data_file, file_line);
        read(file_line, sel1_switch);
        readline(data_file, file_line);
        read(file_line, polarity_switch);

        rx_wait_if_not_ready
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
      file_close(data_file);
      --
      dolearn_switch <= '1'; -- Learn off
      report("test_name: Learn switch off");
      --
      rx_data(OPC_NNEVN, 4, 2) -- NNEVN, CBUS request available event space, node 4 2
      tx_wait_for_node_message(OPC_EVNLF, 4, 2, 128, available event space) -- EVLNF, CBUS available event space response
      --
      report("test_name: Check number of stored events");
      rx_data(OPC_RQEVN, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(OPC_NUMEV, 4, 2, 0, number of stored events) -- NUMEV, CBUS number of stored event response node 4 2
      --
      report("test_name: Check events were not learnt");
      data_file_open(learnt_events.dat)
      --
      while endfile(data_file) == false loop
        data_file_report_line
        rx_wait_if_not_ready
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
