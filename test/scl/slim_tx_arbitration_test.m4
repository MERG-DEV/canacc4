define(test_name, slim_tx_arbitration_test)dnl
include(common.inc)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 890 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    file     sidh_file  : text;
    variable file_stat  : file_open_status;
    variable sidh_line  : string;
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
      file_open(file_stat, sidh_file, "./data/slim_sidh.dat", read_mode);
      if file_stat != open_ok then
        report("test_name: Failed to open SIDH data file");
        report("test_name: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      report("test_name: Loosing arbitration raises Tx priority");
      while endfile(sidh_file) == false loop
        readline(sidh_file, sidh_line);
        report(sidh_line);
        readline(sidh_file, sidh_line);
        read(sidh_line, tx_count);
        readline(sidh_file, sidh_line);
        read(sidh_line, sidh_val);
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
      if test_state == pass then
        report("test_name: PASS");
      else
        report("test_name: FAIL");
      end if;
      PC <= 0;
      wait;
    end process test_name;
end testbench;
