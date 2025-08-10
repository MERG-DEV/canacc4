define(test_name, patsubst(__file__, {.m4},))dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(14863)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    file     data_file  : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
    variable nv_index : integer;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      --
      wait until slim_led == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      data_file_open(nvs.dat)
      --
      report("test_name: Read Node Variables");
      while endfile(data_file) == false loop
        data_file_report_line
        data_file_read(nv_index)
        readline(data_file, file_line);
        --
        rx_data(OPC_NVRD, 0, 0, nv_index) -- NVRD, CBUS read node variable by index, node 0 0
        tx_check_no_message(776)
      end loop;
      --
      report("test_name: Test past number of Node Variables");
      nv_index := nv_index + 1;
      rx_data(OPC_NVRD, 0, 0, nv_index) -- NVRD, CBUS read node variable by index, node 0 0
      tx_check_no_message(776)
      --
      end_test
    end process test_name;
end testbench;
