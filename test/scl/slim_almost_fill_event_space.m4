define(test_name, slim_almost_fill_event_space)dnl
include(common.inc)dnl
include(rx_tx.inc)dnl
include(io.inc)dnl
include(hardware.inc)dnl
include(cbusdefs.inc)dnl
configuration for "processor_type" is
end configuration;
--
testbench for "processor_type" is
begin
  timeout_process(153995)
    --
  test_name: process is
    variable event_low   : integer;
    variable node_low    : integer;
    variable sel_setting : integer;
    variable pol_setting : boolean;
    variable short_event : boolean;
    begin
      report("test_name: START");
      setup_button <= '1'; -- Setup button not pressed
      dolearn_switch <= '1'; -- Learn off
      unlearn_switch <= '1'; -- Unlearn off
      --
      wait until slim_led == '1'; -- Booted into SLiM
      --
      -- Learn events for output 3
      dolearn_switch <= '0'; -- Learn on
      sel0_switch <= '0'; -- Sel 0 on
      sel1_switch <= '1'; -- Sel 1 off
      polarity_switch <= '1'; -- Polarity normal, On event => A, Off event => B
      --
      event_low   := 0;
      node_low    := 0;
      sel_setting := 0;
      pol_setting := false;
      short_event := false;
      while event_low < 127 loop
        if short_event then
          rx_data(OPC_ACON, 1, node_low, 9, event_low) -- ACON, CBUS accessory on, node 1 node_low, event 9 event_low
          short_event := true;
        else
          rx_data(OPC_ASON, 1, node_low, 9, event_low) -- ASON, CBUS accessory short on, node 1 node_low, event 9 event_low
          short_event := false;
        end if;
        --
        output_wait_for_any_pulse(PORTC)
        --
        event_low   := event_low + 1;
        sel_setting := sel_setting + 1;
        --
        if sel_setting == 0 then
          -- Select ouput pair 1
          sel0_switch <= '0'; -- Sel 0 on
          sel1_switch <= '0'; -- Sel 1 off
          if pol_setting then
            polarity_switch <= '0'; -- Polarity reversed, On event => B, Off event => A
            pol_setting := false;
          else
            polarity_switch <= '1'; -- Polarity normal, On event => A, Off event => B
            pol_setting := true;
          end if;
        end if;
        if sel_setting == 1 then
          -- Select ouput pair 2
          sel0_switch <= '1'; -- Sel 0 on
          sel1_switch <= '0'; -- Sel 1 off
        end if;
        if sel_setting == 2 then
          -- Select ouput pair 3
          sel0_switch <= '0'; -- Sel 0 on
          sel1_switch <= '1'; -- Sel 1 off
        end if;
        if sel_setting == 3 then
          -- Select ouput pair 4
          sel0_switch <= '1'; -- Sel 0 on
          sel1_switch <= '1'; -- Sel 1 off
          node_low    := node_low + 1;
          sel_setting := 0;
        end if;
      end loop;
      report("test_name: Learnt 127 events");
      --
      stop_test
    end process test_name;
end testbench;
