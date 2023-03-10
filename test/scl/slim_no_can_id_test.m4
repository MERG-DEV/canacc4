define(test_name, slim_no_can_id_test)dnl
include(common.inc)dnl
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
      report("test_name: Setup button released, awaiting RTR");
      tx_rtr
      tx_check_can_id(default, 16#BF#, 16#E0#)
      --
      test_sidh := 0;
      test_sidl := 16#20#;
      while test_sidh < 16#10# loop
        while test_sidl < 16#100# loop
          rx_sid(test_sidh, test_sidl)
          test_sidl := test_sidl + 16#20#;
        end loop;
        test_sidh := test_sidh + 1;
        test_sidl := 0;
      end loop;
      report("test_name: RTR, all CAN Ids taken");
      --
      report("test_name: Awaiting CMDERR");
      tx_wait_for_cmderr_message(0, 0 ,7) -- CMDERR, CBUS error response, node 0 0, error 7
      tx_check_can_id(unchanged, 16#BF#, 16#E0#)
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
