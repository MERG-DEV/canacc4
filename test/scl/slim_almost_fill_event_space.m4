configuration for "PIC18F2480" is
end configuration;
--
testbench for "PIC18F2480" is
begin
  test_timeout: process is
    begin
      wait for 153995 ms;
      report("slim_almost_fill_event_space: TIMEOUT");
      report(PC); -- Crashes simulator, MDB will report current source line
      PC <= 0;
      wait;
    end process test_timeout;
    --
  slim_almost_fill_event_space: process is
    variable event_low   : integer;
    variable node_low    : integer;
    variable sel_setting : integer;
    variable pol_setting : boolean;
    variable short_event : boolean;
    begin
      report("slim_almost_fill_event_space: START");
      RA3 <= '1'; -- Setup button not pressed
      RB4 <= '1'; -- Learn off
      RA5 <= '1'; -- Unlearn off
      --
      wait until RB7 == '1'; -- Booted into SLiM
      --
      -- Learn events for output 3
      RB4 <= '0'; -- Learn on
      RB0 <= '0'; -- Sel 0 on
      RB1 <= '1'; -- Sel 1 off
      RB5 <= '1'; -- Polarity normal, On event => A, Off event => B
      --
      event_low   := 0;
      node_low    := 0;
      sel_setting := 0;
      pol_setting := false;
      short_event := false;
      while event_low < 127 loop
        if RXB0CON.RXFUL != '0' then
          wait until RXB0CON.RXFUL == '0';
        end if;
        if short_event then
          RXB0D0 <= 16#90#;   -- ACON, CBUS accessory on
          RXB0D1 <= 1;        -- NN high
          RXB0D2 <= node_low; -- NN low
          RXB0D3 <= 9;
          RXB0D4 <= event_low;
          RXB0CON.RXFUL <= '1';
          RXB0DLC.DLC3 <= '1';
          CANSTAT <= 16#0C#;
          PIR3.RXB0IF <= '1';
          short_event := true;
        else
          RXB0D0 <= 16#98#;   -- ACON, CBUS accessory short on
          RXB0D1 <= 1;        -- NN high
          RXB0D2 <= node_low; -- NN low
          RXB0D3 <= 9;
          RXB0D4 <= event_low;
          RXB0CON.RXFUL <= '1';
          RXB0DLC.DLC3 <= '1';
          CANSTAT <= 16#0C#;
          PIR3.RXB0IF <= '1';
          short_event := false;
        end if;
        --
        wait until PORTC != 0;
        wait until PORTC == 0;
        --
        event_low   := event_low + 1;
        sel_setting := sel_setting + 1;
        --
        if sel_setting == 0 then
          -- Select ouput pair 1
          RB0 <= '0'; -- Sel 0 on
          RB1 <= '0'; -- Sel 1 off
          if pol_setting then
            RB5 <= '0'; -- Polarity reversed, On event => B, Off event => A
            pol_setting := false;
          else
            RB5 <= '1'; -- Polarity normal, On event => A, Off event => B
            pol_setting := true;
          end if;
        end if;
        if sel_setting == 1 then
          -- Select ouput pair 2
          RB0 <= '1'; -- Sel 0 on
          RB1 <= '0'; -- Sel 1 off
        end if;
        if sel_setting == 2 then
          -- Select ouput pair 3
          RB0 <= '0'; -- Sel 0 on
          RB1 <= '1'; -- Sel 1 off
        end if;
        if sel_setting == 3 then
          -- Select ouput pair 4
          RB0 <= '1'; -- Sel 0 on
          RB1 <= '1'; -- Sel 1 off
          node_low    := node_low + 1;
          sel_setting := 0;
        end if;
      end loop;
      report("slim_almost_fill_event_space: Learnt 127 events");
      --
      PC <= 0;
      wait;
    end process slim_almost_fill_event_space;
end testbench;
