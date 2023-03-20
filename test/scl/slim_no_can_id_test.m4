define(test_name, slim_no_can_id_test)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
include(hardware.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(23000)
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
      --
      wait until slim_led == '1'; -- Booted into SLiM
      report("test_name: Green LED (SLiM) on");
      --
      setup_button <= '0';
      report("test_name: Setup button pressed");
      wait until slim_led == '0';
      report("test_name: FLiM setup started");
      --
      setup_button <= '1';
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
      end_test
    end process test_name;
end testbench;
