define(test_name, patsubst(__file__, {.m4},))dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  test_timeout: process is
    begin
      wait for 16929 ms;
      report("test_name: TIMEOUT");
      if slim_led == '1' then
        report("test_name: Green LED (SLiM) on");
      end if;
      report(PC); -- Crashes simulator, MDB will report current source line
      stop_test
    end process test_timeout;
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state : test_result;
    file     data_file : text;
    variable file_stat  : file_open_status;
    variable file_line  : string;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      dolearn_switch <= '1'; -- DOLEARN off
      unlearn_switch <= '1'; -- UNLEARN off
      --
      wait until flim_led == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      report("test_name: Check available event space");
      rx_data(OPC_NNEVN, 4, 2) -- NNEVN, CBUS request available event space to node 4 2
      tx_wait_for_node_message(OPC_EVNLF, 4, 2, 128, available event space) -- EVLNF, CBUS available event space response node 4 2
      --
      report("test_name: Check number of stored events");
      rx_data(OPC_RQEVN, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(OPC_NUMEV, 4, 2, 0, number of stored events) -- EVLNF, CBUS available event space response node 4 2
      --
      report("test_name: Check events");
      data_file_open(learnt_events.dat)
      --
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        data_file_report_line
        rx_data_file_event
        --
        readline(data_file, file_line);
        while match(file_line, "Done") == false loop
          readline(data_file, file_line);
        end loop;
        --
        output_check_no_pulse(PORTC, 1005)
      end loop;
      --
      if slim_led == '1' then
        report("test_name: Green LED (SLiM) on");
        test_state := fail;
      end if;
      --
      end_test
    end process test_name;
end testbench;
