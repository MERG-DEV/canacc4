configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 782 ms;
      report("flim_set_can_id_test: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  flim_set_can_id_test: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    variable test_sidl : integer;
    begin
      report("flim_set_can_id_test: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
      --
      wait until RB6 == '1'; -- Booted into FLiM
      report("flim_set_can_id_test: Yellow LED (FLiM) on");
      --
      report("flim_set_can_id_test: Check CAN Id");
      RXB0D0 <= 16#0D#; -- QNN, CBUS Query node request
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1SIDH != 16#B1# then
        report("flim_set_can_id_test: Incorrect SIDH");
        test_state := fail;
      end if;
      if TXB1SIDL != 16#80# then
        report("flim_set_can_id_test: Incorrect SIDL");
        test_state := fail;
      end if;

      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("flim_set_can_id_test: Set CAN Id");
      RXB0D0 <= 16#75#; -- CBUS set CAN Id request
      RXB0D1 <= 4;      -- NN high
      RXB0D2 <= 2;      -- NN low
      RXB0D3 <= 3;      -- New CAN Id
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#52# then -- NNACK, CBUS node number acknowledge
        report("flim_set_can_id_test: Sent wrong response");
        test_state := fail;
      end if;
      if TXB1D1 != 4 then
        report("flim_set_can_id_test: NN acknowledge wrong Node Number (high)");
        test_state := fail;
      end if;
      if TXB1D2 != 2 then
        report("flim_set_can_id_test: NN acknowledge wrong Node Number (low)");
        test_state := fail;
      end if;
      if TXB1SIDH != 16#B0# then
        report("flim_set_can_id_test: NN acknowledge wrong CAN Id, SIDH");
        test_state := fail;
      end if;
      if TXB1SIDL != 16#60# then
        report("flim_set_can_id_test: NN acknowledge wrong CAN Id, SIDL");
        test_state := fail;
      end if;
      --
      if test_state == pass then
        report("flim_set_can_id_test: PASS");
      else
        report("flim_set_can_id_test: FAIL");
      end if;          
      PC <= 0;
      wait;
    end process flim_set_can_id_test;
end testbench;
