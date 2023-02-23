configuration for "PIC18F2480" is
  shared variable Datmode; -- FIXME, kludge to prevent overwriting Rx packet
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 3 ms;
      report("flim_rx_buffer_test: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  flim_rx_buffer_test: process is
    type test_result is (pass, fail);
    variable test_state  : test_result;
    file     data_file   : text;
    variable file_stat   : file_open_status;
    variable file_line   : string;
    variable param_index : integer;
    variable param_value : integer;
    begin
      report("flim_rx_buffer_test: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      --
      wait until RB6 == '1'; -- Booted into FliM
      report("flim_rx_buffer_test: Yellow LED (FLiM) on");
      --
      report("flim_rx_buffer_test: Read Node Parameter, received in RXB0");
      RXB0D0 <= 16#73#;      -- CBUS read node parameter by index
      RXB0D1 <= 4;           -- NN high
      RXB0D2 <= 2;           -- NN low
      RXB0D3 <= 0;
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      -- FIXME, kludge to prevent overwriting Rx packet
      wait until Datmode == 9;
      wait until Datmode == 8;
      --
      report("flim_rx_buffer_test: Read Node Parameter, received in RXB1");
      RXB1D0 <= 16#73#;      -- CBUS read node parameter by index
      RXB1D1 <= 4;           -- NN high
      RXB1D2 <= 2;           -- NN low
      RXB1D3 <= 1;
      RXB1CON.RXFUL <= '1';
      RXB1DLC.DLC3 <= '1';
      CANSTAT <= 16#0A#;
      PIR3.RXB1IF <= '1';
      --
      file_open(file_stat, data_file, "./data/flim_params.dat", read_mode);
      if file_stat != open_ok then
        report("flim_rx_buffer_test: Failed to open parameter data file");
        report("flim_rx_buffer_test: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      param_index := 0;
      while param_index < 2 loop
        readline(data_file, file_line);
        report(file_line);
        readline(data_file, file_line);
        read(file_line, param_value);
        --
        if TXB1CON.TXREQ == '0' then
          report("flim_rx_buffer_test: Awaiting response");
          wait until TXB1CON.TXREQ == '1';
        end if;
        if TXB1D0 != 16#9B# then -- PARAN, CBUS individual parameter response
          report("flim_rx_buffer_test: Sent wrong response");
          test_state := fail;
        end if;
        if TXB1D1 != 4 then
          report("flim_rx_buffer_test: Sent wrong Node Number (high)");
          test_state := fail;
        end if;
        if TXB1D2 != 2 then
          report("flim_rx_buffer_test: Sent wrong Node Number (low)");
          test_state := fail;
        end if;
        if TXB1D3 != param_index then
          report("flim_rx_buffer_test: Sent wrong parameter index");
          test_state := fail;
        end if;
        if TXB1D4 != param_value then
          report("flim_rx_buffer_test: Sent wrong parameter value");
          test_state := fail;
        end if;
        param_index := param_index + 1;
        TXB1CON.TXREQ <= '0';
      end loop;
      --
      if test_state == pass then
        report("flim_rx_buffer_test: PASS");
      else
        report("flim_rx_buffer_test: FAIL");
      end if;          
      PC <= 0;
      wait;
    end process flim_rx_buffer_test;
end testbench;
