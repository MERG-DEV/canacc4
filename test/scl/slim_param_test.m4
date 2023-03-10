define(test_name, slim_param_test)dnl
include(common.inc)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 907 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    file     data_file   : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
    variable node_hi     : integer;
    variable node_lo     : integer;
    variable param_index : integer;
    variable param_value : integer;
    begin
      report("test_name: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      file_open(file_stat, data_file, "./data/slim_ignore.dat", read_mode);
      if file_stat != open_ok then
        report("test_name: Failed to open ignored addresses data file");
        report("test_name: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      report("test_name: Ignore requests not addressed to this node");
      while endfile(data_file) == false loop
        readline(data_file, file_line);
        report(file_line);
        readline(data_file, file_line);
        read(file_line, node_hi);
        readline(data_file, file_line);
        read(file_line, node_lo);
        rx_data(16#73#, node_hi, node_lo, 0) -- RQNPN, CBUS read node parameter by index, 0 == number of parameters
        tx_check_no_message(2)
      end loop;
      --
      file_close(data_file);
      --
      file_open(file_stat, data_file, "./data/slim_params.dat", read_mode);
      if file_stat != open_ok then
        report("test_name: Failed to open parameter data file");
        report("test_name: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      report("test_name: Read Node Parameters");
      param_index := 0;
      while endfile(data_file) == false loop
        readline(data_file, file_line);
        report(file_line);
        readline(data_file, file_line);
        read(file_line, param_value);
        --
        rx_data(16#73#, 0, 0, param_index) -- RQNPN, CBUS read node parameter by index, node 0 0, index = param_index
        --
        tx_wait_for_node_message(16#9B#, 0, 0, param_index, parameter index, param_value, parameter value) then -- PARAN, CBUS individual parameter response
        param_index := param_index + 1;
      end loop;
      --
      report("test_name: Test past number of parameters");
      rx_data(16#73#, 0, 0, param_index) -- RQNPN, CBUS read node parameter by index
      tx_wait_for_cmderr_message(0, 0, 9) -- CMDERR, CBUS error response
      --
      if test_state == pass then
        report("test_name: PASS");
      else
        report("test_name: FAIL");
      end if;
      PC <= 0;
      wait;
    end process test_name;
end testbench;
