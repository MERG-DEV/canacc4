configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 1182 ms;
      report("flim_enumerate_test: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  flim_enumerate_test: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    variable test_sidl : integer;
    begin
      report("flim_enumerate_test: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
      --
      wait until RB6 == '1'; -- Booted into FLiM
      report("flim_enumerate_test: Yellow LED (FLiM) on");
      --
      report("flim_enumerate_test: Check initial CAN Id");
      RXB0D0 <= 16#0D#; -- QNN, CBUS Query node request
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1SIDH != 16#B1# then
        report("flim_enumerate_test: Incorrect SIDH");
        test_state := fail;
      end if;
      if TXB1SIDL != 16#80# then
        report("flim_enumerate_test: Incorrect SIDL");
        test_state := fail;
      end if;

      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("flim_enumerate_test: Request enumerate");
      RXB0D0 <= 16#5D#; -- CBUS enumerate request
      RXB0D1 <= 4;      -- NN high
      RXB0D2 <= 2;      -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1DLC.TXRTR == '1' then
        report("flim_enumerate_test: RTR request");
      else
        report("flim_enumerate_test: not RTR request");
        test_state := fail;
      end if;
      if TXB1SIDH != 16#BF# then
        report("flim_enumerate_test: Incorrect default SIDH");
        test_state := fail;
      end if;
      if TXB1SIDL != 16#E0# then
        report("flim_enumerate_test: Incorrect default SIDL");
        test_state := fail;
      end if;
      --
      test_sidl := 16#20#;
      while test_sidl < 16#60# loop
        if RXB0CON.RXFUL != '0' then
          wait until RXB0CON.RXFUL == '0';
        end if;
        RXB0SIDH <= 0;
        RXB0SIDL <= test_sidl;
        RXB0CON.RXFUL <= '1';
        RXB0DLC <= 0;
        CANSTAT <= 16#0C#;
        PIR3.RXB0IF <= '1';
        test_sidl := test_sidl + 16#20#;
      end loop;
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      RXB0SIDH <= 0;
      RXB0SIDL <= 16#80#;
      RXB0CON.RXFUL <= '1';
      RXB0DLC <= 0;
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      report("flim_enumerate_test: RTR, first free CAN Id is 3");
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#52# then -- NNACK, CBUS node number acknowledge
        report("flim_enumerate_test: Sent wrong response");
        test_state := fail;
      end if;
      if TXB1D1 != 4 then
        report("flim_enumerate_test: NN acknowledge wrong Node Number (high)");
        test_state := fail;
      end if;
      if TXB1D2 != 2 then
        report("flim_enumerate_test: NN acknowledge wrong Node Number (low)");
        test_state := fail;
      end if;
      if TXB1SIDH != 16#B0# then
        report("flim_enumerate_test: NN acknowledge wrong CAN Id, SIDH");
        test_state := fail;
      end if;
      if TXB1SIDL != 16#60# then
        report("flim_enumerate_test: NN acknowledge wrong CAN Id, SIDL");
        test_state := fail;
      end if;
      --
      if test_state == pass then
        report("flim_enumerate_test: PASS");
      else
        report("flim_enumerate_test: FAIL");
      end if;          
      PC <= 0;
      wait;
    end process flim_enumerate_test;
end testbench;
