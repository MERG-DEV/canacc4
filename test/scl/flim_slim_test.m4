include(common.inc)dnl
define(test_name, flim_slim_test)dnl
configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 19855 ms;
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
      report("flim_boot_test: Yellow LED (FLiM) on");
      --
      RA3 <= '0';
      report("test_name: Setup button pressed");
      wait until RB6 == '0';
      report("test_name: SLiM setup started");
      --
      wait until TXB1CON.TXREQ == '1';
      if TXB1D0 != 16#51# then -- NNREL, CBUS release node number
        report("test_name: Sent wrong message");
        test_state := fail;
      end if;
      if TXB1D1 != 4 then
        report("test_name: NN release wrong Node Number (high)");
        test_state := fail;
      end if;
      if TXB1D2 != 2 then
        report("test_name: NN release wrong Node Number (low)");
        test_state := fail;
      end if;
      if TXB1SIDL != 16#80# then
        report("test_name: NN release wrong CAN Id, SIDL");
        test_state := fail;
      end if;
      if TXB1SIDH != 16#B1# then
        report("test_name: NN release wrong CAN Id, SIDH");
        test_state := fail;
      end if;
      --
      RA3 <= '1'; -- Setup button released
      report("test_name: Setup button released");
      --
      if RB7 != '1' then
        report("test_name: Awaiting green LED (SLiM)");
        wait until RB7 == '1'; -- Booted into SLiM
      end if;
      report("test_name: Green LED (SLiM) on");
      --
      if RB6 == '1' then
        report("test_name: Yellow LED (FLiM) on");
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
