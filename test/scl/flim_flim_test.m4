include(common.inc)dnl
define(test_name, flim_flim_test)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 1609 ms;
      report("test_name: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    variable test_sidh : integer;
    variable test_sidl : integer;
    begin
      report("test_name: START");
      test_state := pass;
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- DOLEARN off
      RA5 <= '1'; -- UNLEARN off
      --
      wait until RB6 == '1';
      report("test_name: Booted into FLiM");
      --
      RA3 <= '0';
      report("test_name: Setup button pressed");
      wait for 1 sec;
      RA3 <= '1';
      report("test_name: Setup button released");
      --
      report("test_name: Awaiting RTR");
      wait until TXB1CON.TXREQ == '1';
      if TXB1DLC.TXRTR != '1' then
        report("test_name: not RTR request");
        test_state := fail;
      end if;
      report("test_name: RTR request");
      if TXB1SIDH != 16#BF# then
        report("test_name: Incorrect default SIDH");
        test_state := fail;
      end if;
      if TXB1SIDL != 16#E0# then
        report("test_name: Incorrect default SIDL");
        test_state := fail;
      end if;
      --
      TXB1CON.TXREQ <= '0';
      report("test_name: Awaiting Node Number request");
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#50# then -- RQNN, CBUS request node number
        report("test_name: Sent wrong request");
        test_state := fail;
      end if;
      report("test_name: RQNN request");
      if TXB1SIDH != 16#B0# then
        report("test_name: Incorrect new SIDH");
        test_state := fail;
      end if;
      if TXB1SIDL != 16#20# then
        report("test_name: Incorrect new SIDL");
        test_state := fail;
      end if;
      if TXB1D1 != 4 then
        report("test_name: NN request wrong Node Number (high)");
        test_state := fail;
      end if;
      if TXB1D2 != 2 then
        report("test_name: NN request wrong Node Number (low)");
        test_state := fail;
      end if;
      --
      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Set Node Number");
      RXB0D0 <= 16#42#; -- SNN, CBUS set node number
      RXB0D1 <= 9;      -- New NN high
      RXB0D2 <= 8;      -- New NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      report("test_name: Awaiting Node Number acknowledge");
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#52# then -- NNACK, CBUS node number acknowledge
        report("test_name: Sent wrong response");
        test_state := fail;
      end if;
      report("test_name: Node number response");
      if TXB1D1 != 9 then
        report("test_name: NN acknowledge wrong Node Number (high)");
        test_state := fail;
      end if;
      if TXB1D2 != 8 then
        report("test_name: NN acknowledge wrong Node Number (low)");
        test_state := fail;
      end if;
      if TXB1SIDL != 16#20# then
        report("test_name: NN acknowledge wrong CAN Id, SIDL");
        test_state := fail;
      end if;
      if TXB1SIDH != 16#B0# then
        report("test_name: NN acknowledge wrong CAN Id, SIDH");
        test_state := fail;
      end if;
      --
      if RB6 == '0' then
        report("test_name: Awaiting yellow LED (FLiM)");
        wait until RB6 == '1';
      end if;
      report("test_name: Yellow LED (FLiM) on");
      --
      if RB7 == '1' then
        report("test_name: Green LED (SLiM) on");
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
