define(test_name, patsubst(__file__, {.m4},))dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(25)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state     : test_result;
    variable event_index    : integer;
    file     data_file     : text;
    variable file_stat      : file_open_status;
    variable file_line      : string;
    variable variable_index : integer;
    variable variable_value : integer;
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
      data_file_open(stored_events.dat)
      --
      report("test_name: Read events");
      event_index := 1;
      while endfile(data_file) == false loop
        data_file_report_line
        --
        -- Skip node and event numbers
        readline(data_file, file_line);
        readline(data_file, file_line);
        readline(data_file, file_line);
        readline(data_file, file_line);
        --
        readline(data_file, file_line);
        while match(file_line, "Done") == false loop
          report(file_line);
          read(file_line, variable_index);
          rx_data(OPC_REVAL, 4, 2, event_index, variable_index) -- REVAL, CBUS Indexed read event variable request, node 4 2
          data_file_read(variable_value)
          tx_wait_for_node_message(OPC_NEVAL, 4, 2, event_index, event index, variable_index, variable index, variable_value, variable value) -- NEVAL, CBUS Indexed event variable response
          --
          readline(data_file, file_line);
        end loop;
          event_index := event_index + 1;
      end loop;
      --
      event_index := event_index - 1;
      rx_data(OPC_REVAL, 4, 2, event_index, 0) -- REVAL, CBUS Indexed read event variable request, node 4 2, variable index too low
      tx_wait_for_cmderr_message(4, 2, CMDERR_INV_EV_IDX) -- CBUS error response, node 4 2, Invalid event variable index
      --
      rx_data(OPC_REVAL, 4, 2, event_index, 3) -- REVAL, CBUS Indexed read event variable request, node 4 2, variable index too high
      tx_wait_for_cmderr_message(4, 2, CMDERR_INV_EV_IDX) -- CBUS error response, node 4 2, Invalid event variable index
      --
      rx_data(OPC_REVAL, 4, 2, event_index + 1, 1) -- REVAL, CBUS Indexed read event variable request, node 4 2, event index too high
      tx_wait_for_cmderr_message(4, 2, CMDERR_INVALID_EVENT) -- CBUS error response, node 4 2, Invalid event index
      --
      rx_data(OPC_REVAL, 4, 2, 0, 1) -- REVAL, CBUS Indexed read event variable request, node 4 2, event index too low
      tx_wait_for_cmderr_message(4, 2, CMDERR_INVALID_EVENT) -- CBUS error response, node 4 2, Invalid event index
      --
      end_test
    end process test_name;
end testbench;
