define(test_name, flim_unteach_test)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(25000)
    --
  test_name: process is
    type test_result is (pass, fail);
    variable test_state     : test_result;
    file     data_file      : text;
    variable file_stat      : file_open_status;
    variable file_line      : string;
    variable pulse_report : string;
    variable pulse_val    : integer;
    begin
      report("test_name: START");
      test_state := pass;
      setup_button <= '1'; -- Setup button not pressed
      dolearn_switch <= '1'; -- Learn off
      unlearn_switch <= '1'; -- Unlearn off
      --
      wait until flim_led == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      report("test_name: Check available event space");
      rx_data(OPC_NNEVN, 4, 2) -- NNEVN, CBUS request available event space to node 4 2
      tx_wait_for_node_message(OPC_EVNLF, 4, 2, 123, available event space) -- EVLNF, CBUS available event space response node 4 2
      --
      report("test_name: Check number of stored events");
      rx_data(OPC_RQEVN, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(OPC_NUMEV, 4, 2, 5, number of stored events) -- EVLNF, CBUS available event space response node 4 2
      --
      report("test_name: Enter learn mode");
      rx_data(OPC_NNLRN, 4, 2) -- NNLRN, CBUS enter learn mode to node 4 2
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      data_file_open(unlearn.dat)
      --
      report("test_name: Unlearn events");
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        data_file_report_line
        read(data_file, RXB0D0, 1); -- Ignore event type from data file
        RXB0D0 <= OPC_EVULN;            -- EVULN, CBUS unlearn event
        read(data_file, RXB0D1, 1);
        read(data_file, RXB0D2, 1);
        read(data_file, RXB0D3, 1);
        read(data_file, RXB0D4, 1);
        rx_frame(5)
        tx_wait_for_node_message(OPC_WRACK, 4, 2) -- WRACK, CBUS write acknowledge response node 4 2
      --
      end loop;
      --
      file_close(data_file);
      --
      report("test_name: Exit learn mode");
      rx_data(OPC_NNULN, 4, 2) -- NNULN, CBUS exit learn mode to node 4 2
      --
      report("test_name: Do not unlearn event");
      rx_data(OPC_EVULN, 1, 2, 2, 4) -- EVULN, CBUS unlearn event, node 1 2, event 2 4
      --
      -- FIXME SHould reject request as not in learn mode
      --TXB1CON.TXREQ <= '0';
      --wait until TXB1CON.TXREQ == '1';
      --if TXB1D0 != OPC_CMDERR then -- CMDERR, CBUS error response
      --  report("test_name: Sent wrong response");
      --  test_state := fail;
      --end if;
      --if TXB1D1 != 4 then
      --  report("test_name: Sent wrong Node Number (high)");
      --  test_state := fail;
      --end if;
      --if TXB1D2 != 2 then
      --  report("test_name: Sent wrong Node Number (low)");
      --  test_state := fail;
      --end if;
      --if TXB1D3 != 2 then -- Not in learn event mode
      --  report("test_name: Sent wrong error number");
      --  test_state := fail;
      --end if;
      --
      report("test_name: Recheck available event space");
      rx_data(OPC_NNEVN, 4, 2) -- NNEVN, CBUS request available event space to node 4 2
      tx_wait_for_node_message(OPC_EVNLF, 4, 2, 125, available event space) -- EVLNF, CBUS available event space response node 4 2
      --
      report("test_name: Recheck number of stored events");
      rx_data(OPC_RQEVN, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(OPC_NUMEV, 4, 2, 3, number of stored events) -- EVLNF, CBUS available event space response node 4 2
      --
      data_file_open(remaining_events.dat)
      --
      report("test_name: Check events");
      while endfile(data_file) == false loop
        rx_wait_if_not_ready
        data_file_report_line
        rx_data_file_event
        --
        output_wait_for_data_file_pulse(PORTC)
        --
        output_check_no_pulse(PORTC, 1005)
      end loop;
      --
      end_test
    end process test_name;
end testbench;
