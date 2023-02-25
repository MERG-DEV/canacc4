include(common.inc)dnl
define(test_name, slim_no_can_id_test)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 23000 ms;
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
      --
      wait until RB7 == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      RA3 <= '0';
      report("test_name: Setup button pressed");
      wait until RB7 == '0';
      report("test_name: FLiM setup started");
      --
      RA3 <= '1';
      report("test_name: Setup button released");
      --
      report("test_name: Awaiting RTR");
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
      report("test_name: Awaiting CMDERR");
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
      if TXB1D1 != 0 then
        report("test_name: Sent wrong Node Number (high)");
        test_state := fail;
      end if;
      if TXB1D2 != 0 then
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
