define(test_name, flim_slim_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
include(hardware.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(19855)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    variable test_sidh : integer;
    variable test_sidl : integer;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      dolearn_switch <= '1'; -- DOLEARN off
      unlearn_switch <= '1'; -- UNLEARN off
      --
      wait until flim_led == '1'; -- Booted into FLiM
      report("flim_boot_test: Yellow LED (FLiM) on");
      --
      setup_button <= '0';
      report("test_name: Setup button pressed");
      wait until flim_led == '0';
      report("test_name: SLiM setup started");
      --
      tx_wait_for_node_message(16#51#, 4, 2) -- NNREL, CBUS release node number, node 4 2
      tx_check_can_id(release, 16#B1#, 16#80#)
      --
      setup_button <= '1'; -- Setup button released
      report("test_name: Setup button released");
      --
      if slim_led != '1' then
        report("test_name: Awaiting green LED (SLiM)");
        wait until slim_led == '1'; -- Booted into SLiM
      end if;
      report("test_name: Green LED (SLiM) on");
      --
      if flim_led == '1' then
        report("test_name: Yellow LED (FLiM) on");
        test_state := fail;
      end if;
      --
      end_test
    end process test_name;
end testbench;
