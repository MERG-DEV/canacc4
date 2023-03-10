include(common.inc)dnl
define(test_name, slim_nv_read_test)dnl
include(rx_tx.inc)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 14863 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
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
      RA3 <= '1'; -- Setup button not pressed
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      file_open(file_stat, data_file, "./data/nvs.dat", read_mode);
      if file_stat != open_ok then
        report("test_name: Failed to open node variable data file");
        report("test_name: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      report("test_name: Read Node Variables");
      while endfile(data_file) == false loop
        readline(data_file, file_line);
        report(file_line);
        readline(data_file, file_line);
        read(file_line, nv_index);
        readline(data_file, file_line);
        --
        rx_data(16#71#, 0, 0, nv_index) -- NVRD, CBUS read node variable by index, node 0 0
        tx_check_no_message(776)
      end loop;
      --
      report("test_name: Test past number of Node Variables");
      nv_index := nv_index + 1;
      rx_data(16#71#, 0, 0, nv_index) -- NVRD, CBUS read node variable by index, node 0 0
      tx_check_no_message(776)
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
