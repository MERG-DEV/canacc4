define(test_name, flim_teach_test)dnl
include(common.inc)dnl
include(data_file.inc)dnl
include(rx_tx.inc)dnl
include(io.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(39071)
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
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- Learn off
      RA5 <= '1'; -- Unlearn off
      --
      wait until RB6 == '1'; -- Booted into FLiM
      report("test_name: Yellow LED (FLiM) on");
      --
      report("test_name: Enter learn mode");
      rx_data(16#53#, 4, 2) -- NNLRN, CBUS enter learn mode to node 4 2
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Event Variable index too low long 0x0102,0x0402");
      rx_data(16#D2#, 1, 2, 4, 2, 0, 4) -- EVLRN, CBUS learn event, node 1 2, event 4 2, variable index too low, variable value 4
      tx_wait_for_cmderr_message(4, 2, 6) -- CMDERR, CBUS error response, node 4 2, Invalid event variable index
      --
      report("test_name: Event Variable index too high long 0x0102,0x0402");
      rx_data(16#D2#, 1, 2, 4, 2, 3, 4) -- EVLRN, CBUS learn event, node 1 2, event 4 2, variable index too high, variable value 4
      tx_wait_for_cmderr_message(4, 2, 6) -- CMDERR, CBUS error response, node 4 2, Invalid event variable index
      --
      data_file_open(teach.dat)
      --
      report("test_name: Teach events");
      while endfile(data_file) == false loop
        data_file_report_line
        --
        rx_wait_if_not_ready
        RXB0D0 <= 16#D2#;    -- EVLRN, CBUS learn event
        read(data_file, RXB0D1, 1);
        read(data_file, RXB0D2, 1);
        read(data_file, RXB0D3, 1);
        read(data_file, RXB0D4, 1);
        read(data_file, RXB0D5, 1);
        read(data_file, RXB0D6, 1);
        rx_frame(7)
        tx_wait_for_node_message(16#59#, 4, 2) -- WRACK, CBUS write acknowledge response node 4 2
        --
        output_wait_for_data_file_pulse(PORTC)
        --
        output_check_no_pulse(PORTC, 1005)
      end loop;
      --
      file_close(data_file);
      --
      report("test_name: Exit learn mode");
      rx_data(16#54#, 4, 2) -- NNULN, CBUS exit learn mode to node 4 2
      wait for 1 ms; -- FIXME Next packet lost if previous not yet processed
      --
      report("test_name: Do not learn event");
      rx_data(16#D2#, 9, 9, 8, 8, 1, 4) -- EVLRN, CBUS unlearn event, node 9 9, event 8 8, variable index 1, variable value 4
      --
      -- FIXME Should reject request as not in learn mode
      --TXB1CON.TXREQ <= '0';
      --wait until TXB1CON.TXREQ == '1';
      --if TXB1D0 != 16#6F# then -- CMDERR, CBUS error response
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
      rx_data(16#58#, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(16#74#, 4, 2, 5, number of stored events) -- NUMEV, CBUS number of stored event response node 4 2
      --
      data_file_open(learnt_events.dat)
      --
      report("test_name: Check events");
      while endfile(data_file) == false loop
        data_file_report_line
        rx_wait_if_not_ready
        rx_data_file_event
        --
        output_wait_for_data_file_pulse(PORTC)
        --
        output_check_no_pulse(PORTC, 1005)
      end loop;
      --
      file_close(data_file);
      --
      end_test
    end process test_name;
end testbench;
