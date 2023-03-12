define(test_name, slim_rx_buffer_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
  shared variable Datmode; -- FIXME, kludge to prevent overwriting Rx packet
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(877)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    file     data_file   : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
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
      report("test_name: Read Node Parameter, received in RXB0");
      rx_data(16#73#, 0, 0, 0) -- CBUS read node parameter by index, node 0 0, index 0 - parameter count
      --
      -- FIXME, kludge to prevent overwriting Rx packet
      wait until Datmode == 1;
      wait until Datmode == 0;
      --
      report("test_name: Read Node Parameter, received in RXB1");
      rxb1_data(16#73#, 0, 0, 1) -- CBUS read node parameter by index, node 0 0, index 1
      --
      data_file_open(slim_params.dat)
      --
      param_index := 0;
      while param_index < 2 loop
        data_file_report_line
        data_file_read(param_value)
        --
        tx_wait_for_node_message(16#9B#, 0, 0, param_index, parameter index, param_value, parameter value) -- PARAN, CBUS individual parameter response node 0 0
        param_index := param_index + 1;
      end loop;
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
