define(test_name, flim_slim_test)dnl
include(common.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
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
      tx_wait_for_node_message(16#51#, 4, 2) -- NNREL, CBUS release node number, node 4 2
      tx_check_can_id(release, 16#B1#, 16#80#)
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
