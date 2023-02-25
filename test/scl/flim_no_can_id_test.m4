include(common.inc)dnl
define(test_name, flim_no_can_id_test)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 1182 ms;
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
      wait until RB6 == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      report("test_name: Check CAN Id");
      RXB0D0 <= 16#0D#; -- QNN, CBUS Query node request
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1SIDH != 16#B1# then
        report("test_name: Incorrect SIDH");
        test_state := fail;
      end if;
      if TXB1SIDL != 16#80# then
        report("test_name: Incorrect SIDL");
        test_state := fail;
      end if;

      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      if RXB0CON.RXFUL != '0' then
        wait until RXB0CON.RXFUL == '0';
      end if;
      report("test_name: Request enumerate");
      RXB0D0 <= 16#5D#; -- CBUS enumerate request
      RXB0D1 <= 4;      -- NN high
      RXB0D2 <= 2;      -- NN low
      RXB0CON.RXFUL <= '1';
      RXB0DLC.DLC3 <= '1';
      CANSTAT <= 16#0C#;
      PIR3.RXB0IF <= '1';
      --
      TXB1CON.TXREQ <= '0';
      report("test_name: Waiting for RTR");
      wait until TXB1CON.TXREQ == '1';
      if TXB1DLC.TXRTR == '1' then
        report("test_name: RTR request");
      else
        report("test_name: not RTR request");
        test_state := fail;
      end if;
      if TXB1SIDH != 16#BF# then
        report("test_name: Incorrect default SIDH");
        test_state := fail;
      end if;
      if TXB1SIDL != 16#E0# then
        report("test_name: Incorrect default SIDL");
        test_state := fail;
      end if;
      --
      test_sidh := 0;
      test_sidl := 16#20#;
      while test_sidh < 16#10# loop
        while test_sidl < 16#100# loop
          RXB0SIDH <= test_sidh;
          RXB0SIDL <= test_sidl;
          RXB0CON.RXFUL <= '1';
          RXB0DLC <= 0;
          CANSTAT <= 16#0C#;
          PIR3.RXB0IF <= '1';
          wait until RXB0CON.RXFUL == '0';
          test_sidl := test_sidl + 16#20#;
        end loop;
        test_sidh := test_sidh + 1;
        test_sidl := 0;
      end loop;
      report("test_name: RTR, all CAN Ids taken");
      --
      TXB1CON.TXREQ <= '0';
      wait until TXB1CON.TXREQ == '1';
      if TXB1SIDH != 16#BF# then
        report("test_name: Unexpected SIDH change");
        test_state := fail;
      end if;
      if TXB1SIDL != 16#E0# then
        report("test_name: Unexpected SIDH change");
        test_state := fail;
      end if;
      if TXB1D0 != 16#6F# then -- CMDERR, CBUS error response
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
      if TXB1D3 != 7 then -- Invalid event
        report("test_name: Sent wrong error number");
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
