changecom(--)dnl
define(test_name, flim_enumerate_test)dnl
include(rx_tx.m4)dnl
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
      report("test_name: Check initial CAN Id");
      rx_0_data(16#0D#) -- QNN, CBUS Query node request)
      --
      tx_wait_for_ready()
      check_tx_can_id(initial, 16#B1#, 16#80#)

      wait for 1 ms; -- FIXME Next packet lost if previous Tx not yet completed
      report("test_name: Request enumerate");
      rx_2_data(16#5D#, 4, 2) -- CBUS enumerate request to node 4 2
      --
      tx_rtr()
      check_tx_can_id(default, 16#BF#, 16#E0#)
      --
      test_sidl := 16#20#;
      while test_sidl < 16#60# loop
        rx_sid(0, test_sidl)
        test_sidl := test_sidl + 16#20#;
      end loop;
      rx_sid(0, 16#80#)
      report("test_name: RTR, first free CAN Id is 3");
      --
      tx_wait_for_ready()
      if TXB1D0 != 16#52# then -- NNACK, CBUS node number acknowledge
        report("test_name: Sent wrong response");
        test_state := fail;
      end if;
      if TXB1D1 != 4 then
        report("test_name: NN acknowledge wrong Node Number (high)");
        test_state := fail;
      end if;
      if TXB1D2 != 2 then
        report("test_name: NN acknowledge wrong Node Number (low)");
        test_state := fail;
      end if;
      check_tx_can_id(`NN acknowledge', 16#B0#, 16#60#)
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
