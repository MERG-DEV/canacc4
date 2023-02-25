include(common.inc)dnl
define(test_name, flim_nv_read_test)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 37 ms;
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
    variable nv_value : integer;
    begin
      report("test_name: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      --
      wait until RB6 == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      file_open(file_stat, data_file, "./data/flim_ignore.dat", read_mode);
      if file_stat != open_ok then
        report("test_name: Failed to open ignored addresses data file");
        report("test_name: FAIL");
        PC <= 0;
        wait;
      end if;
      --
      report("test_name: Ignore requests not addressed to node");
      while endfile(data_file) == false loop
        wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
        readline(data_file, file_line);
        report(file_line);
        RXB0D0 <= 16#71#;           -- NVRD, CBUS read node variable by index
        read(data_file, RXB0D1, 1); -- NN high
        read(data_file, RXB0D2, 1); -- NN low
        RXB0D3 <= 1;                -- Index
        RXB0CON.RXFUL <= '1';
        RXB0DLC.DLC3 <= '1';
        CANSTAT <= 16#0C#;
        PIR3.RXB0IF <= '1';
        --
        TXB1CON.TXREQ <= '0';
        wait until TXB1CON.TXREQ == '1' for 2 ms; -- Test if response sent
        if TXB1CON.TXREQ == '1' then
          report("test_name: Unexpected response");
          test_state := fail;
        end if;
      end loop;
      --
      file_close(data_file);
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
        wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
        if RXB0CON.RXFUL != '0' then
          wait until RXB0CON.RXFUL == '0';
        end if;
        readline(data_file, file_line);
        report(file_line);
        readline(data_file, file_line);
        read(file_line, nv_index);
        readline(data_file, file_line);
        read(file_line, nv_value);
        --
        RXB0D0 <= 16#71#;      -- NVRD, CBUS read node variable by index
        RXB0D1 <= 4;           -- NN high
        RXB0D2 <= 2;           -- NN low
        RXB0D3 <= nv_index;
        RXB0CON.RXFUL <= '1';
        RXB0DLC.DLC3 <= '1';
        CANSTAT <= 16#0C#;
        PIR3.RXB0IF <= '1';
        --
        TXB1CON.TXREQ <= '0';
        wait until TXB1CON.TXREQ == '1';
        if TXB1D0 != 16#97# then -- NVANS, CBUS node variable response
          report("test_name: Sent wrong response");
          test_state := fail;
        end if;
        if TXB1D1 != 4 then
          report("test_name: Sent wrong Node Number (high)");
          test_state := fail;
        end if;
        if TXB1D2 != 2 then
          report("test_name: Sent wrong Node Number (low)");
          test_state := fail;
        end if;
        if TXB1D3 != nv_index then
          report("test_name: Sent wrong node variable index");
          test_state := fail;
        end if;
        if TXB1D4 != nv_value then
          report("test_name: Sent wrong node variable value");
          test_state := fail;
        end if;
      end loop;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Test beyond number of node variables");
      nv_index := nv_index + 1;
      RXB0D0 <= 16#71#;    -- NVRD, CBUS read node variable by index
      RXB0D1 <= 4;         -- NN high
      RXB0D2 <= 2;         -- NN low
      RXB0D3 <= nv_index;  -- Node Variable index
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#97# then -- NVANS, CBUS node variable response
        report("test_name: Sent wrong response");
        test_state := fail;
      end if;
      if TXB1D1 != 4 then
        report("test_name: Sent wrong Node Number (high)");
        test_state := fail;
      end if;
      if TXB1D2 != 2 then
        report("test_name: Sent wrong Node Number (low)");
        test_state := fail;
      end if;
      if TXB1D3 != 0 then -- Invalid node variable index
        report("test_name: Failed to send invalid node variable index");
        test_state := fail;
      end if;
      if TXB1D4 != 0 then -- Invalid node variable index
        report("test_name: Failed to send invalid node variable value");
        test_state := fail;
      end if;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Test read node variable [0]");
      nv_index := nv_index + 1;
      RXB0D0 <= 16#71#;  -- NVRD, CBUS read node variable by index
      RXB0D1 <= 4;       -- NN high
      RXB0D2 <= 2;       -- NN low
      RXB0D3 <= 0;       -- Node Variable index
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#97# then -- NVANS, CBUS node variable response
        report("test_name: Sent wrong response");
        test_state := fail;
      end if;
      if TXB1D1 != 4 then
        report("test_name: Sent wrong Node Number (high)");
        test_state := fail;
      end if;
      if TXB1D2 != 2 then
        report("test_name: Sent wrong Node Number (low)");
        test_state := fail;
      end if;
      if TXB1D3 != 0 then -- Invalid node variable index
        report("test_name: Failed to send invalid node variable index");
        test_state := fail;
      end if;
      if TXB1D4 != 0 then -- Invalid node variable index
        report("test_name: Failed to send invalid node variable value");
        test_state := fail;
      end if;
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
