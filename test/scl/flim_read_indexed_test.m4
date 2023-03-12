define(test_name, flim_read_indexed_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
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
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- Learn off
      RA5 <= '1'; -- Unlearn off
      --
      wait until RB6 == '1'; -- Booted into FLiM
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
          rx_data(16#9C#, 4, 2, event_index, variable_index) -- REVAL, CBUS Indexed read event variable request, node 4 2
          data_file_read(variable_value)
          tx_wait_for_node_message(16#B5#, 4, 2, event_index, event index, variable_index, variable index, variable_value, variable value) -- NEVAL, CBUS Indexed event variable response
          --
          readline(data_file, file_line);
        end loop;
          event_index := event_index + 1;
      end loop;
      --
      event_index := event_index - 1;
      rx_data(16#9C#, 4, 2, event_index, 0) -- REVAL, CBUS Indexed read event variable request, node 4 2, variable index too low
      tx_wait_for_cmderr_message(4, 2, 6) -- CMDERR, CBUS error response, node 4 2, Invalid event variable index
      --
      rx_data(16#9C#, 4, 2, event_index, 3) -- REVAL, CBUS Indexed read event variable request, node 4 2, variable index too high
      tx_wait_for_cmderr_message(4, 2, 6) -- CMDERR, CBUS error response, node 4 2, Invalid event variable index
      --
      rx_data(16#9C#, 4, 2, event_index + 1, 1) -- REVAL, CBUS Indexed read event variable request, node 4 2, event index too high
      tx_wait_for_cmderr_message(4, 2, 7) -- CMDERR, CBUS error response, node 4 2, Invalid event index
      --
      rx_data(16#9C#, 4, 2, 0, 1) -- REVAL, CBUS Indexed read event variable request, node 4 2, event index too low
      tx_wait_for_cmderr_message(4, 2, 7) -- CMDERR, CBUS error response, node 4 2, Invalid event index
      --
      end_test
    end process test_name;
end testbench;
