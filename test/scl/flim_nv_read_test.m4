define(test_name, flim_nv_read_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
include(hardware.inc)dnl
include(cbusdefs.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(37)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    file     data_file  : text;
    variable file_stat  : file_open_status;
    variable file_line  : string;
    variable node_hi    : integer;
    variable node_lo    : integer;
    variable nv_index   : integer;
    variable nv_value   : integer;
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
        rx_data(OPC_NVRD, node_hi, node_lo, 1) -- NVRD, CBUS read node variable, index 1
        tx_check_no_message(2) -- Test if unexpected response sent
      end loop;
      --
      file_close(data_file);
      --
      data_file_open(nvs.dat)
      --
      report("test_name: Read Node Variables");
      while endfile(data_file) == false loop
        data_file_report_line
        data_file_read(nv_index)
        data_file_read(nv_value)
        rx_data(OPC_NVRD, 4, 2, nv_index) -- NVRD, CBUS read node variable by index, node 4 2
        tx_wait_for_node_message(OPC_NVANS, 4, 2, nv_index, variable index, nv_value, variable value) -- NVANS, CBUS node variable response node 4 2
      end loop;
      --
      report("test_name: Test beyond number of node variables");
      nv_index := nv_index + 1;
      rx_data(OPC_NVRD, 4, 2, nv_index) -- NVRD, CBUS read node variable by index, node 4 2, index too high
      tx_wait_for_node_message(OPC_NVANS, 4, 2, 0, variable index, 0, variable value) -- NVANS, CBUS node variable response node 4 2
      --
      report("test_name: Test read node variable [0]");
      rx_data(OPC_NVRD, 4, 2, 0) -- NVRD, CBUS read node variable, node 4 2, index 0
      tx_wait_for_node_message(OPC_NVANS, 4, 2, 0, variable index, 0, variable value) -- NVANS, CBUS node variable response node 4 2
      --
      end_test
    end process test_name;
end testbench;
