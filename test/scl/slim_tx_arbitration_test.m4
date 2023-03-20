define(test_name, slim_tx_arbitration_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(890)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    file     data_file  : text;
    variable file_stat  : file_open_status;
    variable file_line  : string;
    variable tx_count   : integer;
    variable sidh_val   : integer;
    begin
      report("test_name: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      report("test_name: Request Node Parameter");
      rx_data(16#73#, 0, 0, 0); -- CBUS read node parameter by index
      wait until INTCON < 128;
      wait until INTCON > 127;
      --
      data_file_open(slim_sidh.dat)
      --
      report("test_name: Loosing arbitration raises Tx priority");
      while endfile(data_file) == false loop
        readline(data_file, file_line);
        report(file_line);
        readline(data_file, file_line);
        read(file_line, tx_count);
        readline(data_file, file_line);
        read(file_line, sidh_val);
        --
        while tx_count > 0 loop
          if TXB1CON.TXREQ == '0' then
            wait until TXB1CON.TXREQ == '1';
          end if;
          if TXB1SIDH != sidh_val then
            report("test_name: Wrong SIDH");
            test_state := fail;
          end if;
          TXB1CON.TXLARB <= '1';
          CANSTAT <= 16#02#;
          PIR3.ERRIF <= '1';
          wait until INTCON < 128;
          wait until INTCON > 127;
          tx_count := tx_count - 1;
        end loop;
      end loop;
      --
      end_test
    end process test_name;
end testbench;
