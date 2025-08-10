define(test_name, patsubst(__file__, {.m4},))dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(16)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    file     data_file  : text;
    variable file_stat  : file_open_status;
    variable sidh_line  : string;
    variable tx_count  : integer;
     variable sidh_val   : integer;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      --
      wait until flim_led == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      report("test_name: Request Node Parameter");
      rx_data(OPC_RQNPN, 4, 2, 0); -- CBUS read node parameter by index
      wait until INTCON < 128;
      wait until INTCON > 127;
      --
      data_file_open(flim_sidh.dat)
      --
      report("test_name: Loosing arbitration raises Tx priority");
      while endfile(data_file) == false loop
        readline(data_file, sidh_line);
        report(sidh_line);
        readline(data_file, sidh_line);
        read(sidh_line, tx_count);
        readline(data_file, sidh_line);
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
      end_test
    end process test_name;
end testbench;
