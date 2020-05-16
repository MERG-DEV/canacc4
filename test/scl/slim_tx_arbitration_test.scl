configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 890 ms;
      report("slim_tx_arbitration_test: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  slim_tx_arbitration_test: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    file     sidh_file  : text;
    variable file_stat  : file_open_status;
    variable sidh_line  : string;
    variable tx_count   : integer;
    variable sidh_val   : integer;
    begin
      report("slim_tx_arbitration_test: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("slim_tx_arbitration_test: Green LED (SLiM) on");
      --
      report("slim_tx_arbitration_test: Request Node Parameter");
      RXB0D0 <= 16#73#;      -- CBUS read node parameter by index
      RXB0D1 <= 0;           -- NN high
      RXB0D2 <= 0;           -- NN low
      RXB0D3 <= 0;
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      wait until INTCON < 128;
      wait until INTCON > 127;
      --
      file_open(file_stat, sidh_file, "./data/slim_sidh.dat", read_mode);
      if file_stat != open_ok then
        report("flim_unteach_test: Failed to open SIDH data file");
        report("flim_unteach_test: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      report("slim_tx_arbitration_test: Loosing arbitration raises Tx priority");
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
          if TXB1SIDH == sidh_val then
            --
          else
            report("slim_tx_arbitration_test: Wrong SIDH");
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
        report("slim_tx_arbitration_test: PASS");
      else
        report("slim_tx_arbitration_test: FAIL");
      end if;          
      PC <= 0;
      wait;
    end process slim_tx_arbitration_test;
end testbench;
