define(test_name, patsubst(__file__, {.m4},))dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(33)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    file     data_file  : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
    variable node_hi     : integer;
    variable node_lo     : integer;
    variable param_index : integer;
    variable param_value : integer;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      --
      wait until flim_led == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      data_file_open(flim_ignore.dat)
      --
      report("test_name: Ignore requests not addressed to node");
      while endfile(data_file) == false loop
        data_file_report_line
        data_file_read(node_hi)
        data_file_read(node_lo)
        --
        rx_data(OPC_RQNPN, node_hi, node_lo) -- CBUS read node parameter by index
        tx_check_no_message(2) -- Test if response sent
      end loop;
      --
      file_close(data_file);
      --
      data_file_open(flim_params.dat)
      --
      report("test_name: Read Node Parameters");
      param_index := 0;
      while endfile(data_file) == false loop
        data_file_report_line
        data_file_read(param_value)
        --
        rx_data(OPC_RQNPN, 4, 2, param_index) -- CBUS read node parameter by index
        tx_wait_for_node_message(OPC_PARAN, 4, 2, param_index, param_value) -- CBUS individual parameter response
        param_index := param_index + 1;
      end loop;
      --
      report("test_name: Test beyond number of parameters");
      rx_data(OPC_RQNPN, 4, 2, param_index) -- CBUS read node parameter by index
      tx_wait_for_cmderr_message(4, 2, CMDERR_INV_PARAM_IDX) -- CBUS error response, node 4 2, Invalid parameter index
      --
      end_test
    end process test_name;
end testbench;
