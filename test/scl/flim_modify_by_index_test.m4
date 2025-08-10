define(test_name, patsubst(__file__, {.m4},))dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(33372)
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
      rx_data(OPC_NNLRN, 4, 2) -- NNLRN, CBUS enter learn mode to node 4 2
      --
      report("test_name: Modify events");
      data_file_open(modify_indexed.dat)
      --
      while endfile(data_file) == false loop
        data_file_report_line
        --
        rx_wait_if_not_ready
        RXB0D0 <= 16#F5#;    -- EVLRNI, CBUS learn by index event
        read(data_file, RXB0D1, 1);
        read(data_file, RXB0D2, 1);
        read(data_file, RXB0D3, 1);
        read(data_file, RXB0D4, 1);
        read(data_file, RXB0D5, 1);
        read(data_file, RXB0D6, 1);
        read(data_file, RXB0D7, 1);
        rx_frame(8)
        --
        -- CANACC4 does not implement learn by index so no WRACK expected
        --TXB1CON.TXREQ <= '0';
        --wait until TXB1CON.TXREQ == '1';
        --if TXB1D0 != OPC_WRACK then -- WRACK, CBUS write acknowledge response
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
        tx_check_no_message(776) -- Test if unexpectedresponse sent
        --
        readline(data_file, file_line);
        while match(file_line, "Done") == false loop
          data_file_read(pulse_val)
          --
          output_check_no_pulse(PORTC, 1005)
          --
          readline(data_file, file_line);
        end loop;
        --
      end loop;
      --
      file_close(data_file);
      --
      report("test_name: Exit learn mode");
      rx_data(OPC_NNULN, 4, 2) -- NNULN, CBUS exit learn mode to node 4 2
      --
      rx_data(OPC_NNEVN, 4, 2) -- NNEVN, CBUS request available event space, node 4 2
      tx_wait_for_node_message(OPC_EVNLF, 4, 2, 123, available event space) -- EVLNF, CBUS available event space response
      --
      report("test_name: Check number of stored events");
      rx_data(OPC_RQEVN, 4, 2) -- RQEVN, CBUS request number of stored events to node 4 2
      tx_wait_for_node_message(OPC_NUMEV, 4, 2, 5, number of stored events) -- NUMEV, CBUS number of stored event response node 4 2
      --
      report("test_name: Check events");
      -- CANACC4 does not implement learn by index so events are unmodified
      -- file_open(file_stat, data_file, "./data/index_modified_events.dat", read_mode);
      data_file_open(learnt_events.dat)
      --
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
