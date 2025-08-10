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
    file     data_file     : text;
    variable file_stat      : file_open_status;
    variable file_line      : string;
    variable node_hi        : integer;
    variable node_lo        : integer;
    variable event_hi       : integer;
    variable event_lo       : integer;
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
      rx_data(OPC_NNLRN, 4, 2) -- NNLRN, CBUS enter learn mode to node 4 2
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      data_file_open(stored_events.dat)
      --
      report("test_name: Read events");
      while endfile(data_file) == false loop
        data_file_report_line
        --
        data_file_read(node_hi)
        data_file_read(node_lo)
        data_file_read(event_hi)
        data_file_read(event_lo)
        --
        readline(data_file, file_line);
        while match(file_line, "Done") == false loop
          report(file_line);
          read(file_line, variable_index);
          rx_data(OPC_REQEV, node_hi, node_lo, event_hi, event_lo, variable_index) -- CBUS Read event variable request
          data_file_read(variable_value)
          tx_wait_for_message(OPC_EVANS, opcode, node_hi, node high, node_lo, node low, event_hi, event high, event_lo, event low, variable_index, event variable index, variable_value, event variable value) -- EVANS, CBUS event variable response
          --
          readline(data_file, file_line);
        end loop;
      end loop;
      --
      report("test_name: Event Variable index too low");
      rx_data(OPC_REQEV, node_hi, node_lo, event_hi, event_lo, 0) -- CBUS Read event variable request
      tx_wait_for_cmderr_message(4, 2, CMDERR_INV_EV_IDX) -- CBUS error response, node 4 2, Invalid event variable index
      --
      report("test_name: Event Variable index too high");
      rx_data(OPC_REQEV, node_hi, node_lo, event_hi, event_lo, 3) -- CBUS Read event variable request
      tx_wait_for_cmderr_message(4, 2, CMDERR_INV_EV_IDX) -- CBUS error response, node 4 2, Invalid event variable index
      --
      report("test_name: Read unknown event");
      rx_data(OPC_REQEV, 9, 8, 7, 6, 1) -- CBUS Read event variable request
      tx_wait_for_cmderr_message(4, 2, CMDERR_NO_EV) -- CBUS error response, node 4 2, unknown event
      --
      end_test
    end process test_name;
end testbench;
