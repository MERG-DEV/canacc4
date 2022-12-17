define(TESTNAME, flim_enumerate_test)dnl
define(RX_DATA0, RXB0D0)dnl
define(RX_DATA1, RXB0D1)dnl
define(RX_DATA2, RXB0D2)dnl
define(TRACE, report("TESTNAME: $1");)dnl
define(TIMEOUT,
  test_timeout: process is
    begin
      wait for $1 ms;
      TRACE(TIMEDOUT)
      report(PC); -- Crashes simulator MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;)dnl
define(CBUS_QNN, `16#0D#')dnl # QNN, CBUS Query node request
define(CBUS_ENM, `16#5D#')dnl # CBUS enumerate request
define(TRIGGER_RX,
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';)dnl
define(TRIGGER_RTR_RX,
      RXB0CON.RXFUL <= '1';
      RXB0DLC <= 0;
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';)dnl
define(WAIT_FOR_TX,
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';)dnl
dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  TIMEOUT(1182)
    --
  TESTNAME: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    variable test_sidl : integer;
    begin
      TRACE(START)
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
      --
      wait until RB6 == '1'; -- Booted into FLiM
      TRACE(Yellow LED (FLiM) on)
      --
      TRACE(Check initial CAN Id)
      RX_DATA0 <= CBUS_QNN;
      TRIGGER_RX
      --
      WAIT_FOR_TX
      if TXB1SIDH != 16#B1# then
        TRACE(Incorrect SIDH)
        test_state := fail;
      end if;
      if TXB1SIDL != 16#80# then
        TRACE(Incorrect SIDL)
        test_state := fail;
      end if;

      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      TRACE(Request enumerate)
      RX_DATA0 <= CBUS_ENM;
      RX_DATA1 <= 4;      -- NN high
      RX_DATA2 <= 2;      -- NN low
      TRIGGER_RX
      --
      WAIT_FOR_TX
      if TXB1DLC.TXRTR == '1' then
        TRACE(RTR request)
      else
        TRACE(not RTR request)
        test_state := fail;
      end if;
      if TXB1SIDH != 16#BF# then
        TRACE(Incorrect default SIDH)
        test_state := fail;
      end if;
      if TXB1SIDL != 16#E0# then
        TRACE(Incorrect default SIDL)
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
        TRIGGER_RTR_RX
        test_sidl := test_sidl + 16#20#;
      end loop;
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      RXB0SIDH <= 0;
      RXB0SIDL <= 16#80#;
      TRIGGER_RTR_RX
      TRACE(RTR first free CAN Id is 3)
      --
      WAIT_FOR_TX
      if TXB1D0 != 16#52# then -- NNACK, CBUS node number acknowledge
        TRACE(Sent wrong response)
        test_state := fail;
      end if;
      if TXB1D1 != 4 then
        TRACE(NN acknowledge wrong Node Number (high))
        test_state := fail;
      end if;
      if TXB1D2 != 2 then
        TRACE(NN acknowledge wrong Node Number (low))
        test_state := fail;
      end if;
      if TXB1SIDH != 16#B0# then
        TRACE(NN acknowledge wrong CAN Id SIDH)
        test_state := fail;
      end if;
      if TXB1SIDL != 16#60# then
        TRACE(NN acknowledge wrong CAN Id SIDL)
        test_state := fail;
      end if;
      --
      if test_state == pass then
        TRACE(PASS)
      else
        TRACE(FAIL)
      end if;
      PC <= 0;
      wait;
    end process TESTNAME;
end testbench;
