define(test_name, flim_nv_write_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  test_timeout: process is
    begin
      wait for 1374 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    file     data_file  : text;
    variable file_stat  : file_open_status;
    variable file_line  : string;
    variable fire_time1 : cycle;
    variable fire_time2 : cycle;
    variable node_hi    : integer;
    variable node_lo    : integer;
    begin
      report("test_name: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      --
      wait until RB6 == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      data_file_open(flim_ignore.dat)
      --
      report("test_name: Ignore requests not addressed to node");
      while endfile(data_file) == false loop
        data_file_report_line
        readline(data_file, file_line);
        read(file_line, node_hi);
        readline(data_file, file_line);
        read(file_line, node_lo);
        rx_data(16#96#, node_hi, node_lo, 1, 1) -- NVSET, CBUS set node variable, index 1, value 1
        tx_check_no_message(2) -- Test if unexpected response sent
      end loop;
      --
      file_close(data_file);
      --
      report("test_name: Check original 3A fire time");
      rx_data(16#71#, 4, 2, 5) -- NVRD, CBUS read node variable, node 4 2, index 5 - output 3A fire time
      tx_wait_for_node_message(16#97#, 4, 2, 5, variable index, 5, fire time value) -- NVANS, CBUS node variable response node 4 2, index 5, value 5
      --
      report("test_name: Long off 0x0102,0x0204, trigger 3A");
      rx_data(16#91#, 1, 2, 2, 4) -- ACOF, CBUS long off, node 1 2, event 2 4
      --
      wait until PORTC != 0;
      fire_time1 := now();
      if PORTC == 32 then
        report("test_name: Triggered 3A");
      else
        report("test_name: Wrong output");
        test_state := fail;
      end if;
      wait until PORTC == 0;
      fire_time1 := now() - fire_time1;
      --
      report("test_name: Change 3A fire time");
      rx_data(16#96#, 4, 2, 5, 2) -- NVSET, CBUS set node variable, node 4 2, index 5 - output 3A fire time, value 2
      --
      -- FIXME No WRACK
      --TXB1CON.TXREQ <= '0';
      --wait until TXB1CON.TXREQ == '1';
      --if TXB1D0 != 16#59# then -- WRACK, CBUS write acknowledge response
      --  report("test_name: Sent wrong response");
      --  test_state := fail;
      --end if;
      --if TXB1D1 != 4 then
      --  report("test_name: Sent wrong Node Number (high)");
      --  test_state := fail;
      --end if;
      --if TXB1D2 != 2 then
      --  report("test_name: Sent wrong Node Number (low)");
      --  test_state := fail;
      --end if;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous Rx not yet processed
      report("test_name: Read back new 3A fire time");
      rx_data(16#71#, 4, 2, 5) -- NVRD, CBUS read node variable, node 4 2, index 5 - output 3A fire time
      tx_wait_for_node_message(16#97#, 4, 2, 5, variable index, 2, fire time value) -- NVANS, CBUS node variable response node 4 2, index 5, value 2
      --
      report("test_name: Repeat long off 0x0102,0x0204, trigger 3A");
      rx_data(16#91#, 1, 2, 2, 4) -- ACOF, CBUS long off, node 1 2, event 2 4
      --
      wait until PORTC != 0;
      fire_time2 := now();
      if PORTC == 32 then
        report("test_name: Triggered 3A");
      else
        report("test_name: Wrong output");
        test_state := fail;
      end if;
      wait until PORTC == 0;
      fire_time2 := now() - fire_time2;
      --
      if fire_time2 > fire_time1 / 2 then
        report("test_name: 3A trigger too long");
        test_state := fail;
      end if;
      --
      report("test_name: Node variable value too low");
      rx_data(16#96#, 4, 2, 5, 0) -- NVSET, CBUS set node variable, node 4 2, index 5 - output 3A fire time, value 0
      --
      -- FIXME No CMDERR
      --TXB1CON.TXREQ <= '0';
      --wait until TXB1CON.TXREQ == '1';
      --if TXB1D0 != 16#6F# then -- CMDERR, CBUS error response
      --  report("flim_param_test: Sent wrong response");
      --  test_state := fail;
      --end if;
      --if TXB1D1 != 4 then
      --  report("flim_param_test: Sent wrong Node Number (high)");
      --  test_state := fail;
      --end if;
      --if TXB1D2 != 2 then
      --  report("flim_param_test: Sent wrong Node Number (low)");
      --  test_state := fail;
      --end if;
      --if TXB1D3 != 10 then -- Invalid node variable index
      --  report("flim_param_test: Sent wrong error number");
      --  test_state := fail;
      --end if;
      --
      report("test_name: Node variable value too high");
      rx_data(16#96#, 4, 2, 5, 15) -- NVSET, CBUS set node variable, node 4 2, index 5 - output 3A fire time, value 15
      --
      -- FIXME No CMDERR
      --TXB1CON.TXREQ <= '0';
      --wait until TXB1CON.TXREQ == '1';
      --if TXB1D0 != 16#6F# then -- CMDERR, CBUS error response
      --  report("flim_param_test: Sent wrong response");
      --  test_state := fail;
      --end if;
      --if TXB1D1 != 4 then
      --  report("flim_param_test: Sent wrong Node Number (high)");
      --  test_state := fail;
      --end if;
      --if TXB1D2 != 2 then
      --  report("flim_param_test: Sent wrong Node Number (low)");
      --  test_state := fail;
      --end if;
      --if TXB1D3 != 10 then -- Invalid node variable index
      --  report("flim_param_test: Sent wrong error number");
      --  test_state := fail;
      --end if;
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
