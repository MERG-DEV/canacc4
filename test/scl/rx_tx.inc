define(check_tx_can_id,
       if TXB1SIDH != $2 then
         report("test_name: Incorrect $1 CAN Id SIDH");
         test_state := fail;
       end if;
       if TXB1SIDL != $3 then
         report("test_name: Incorrect $1 CAN Id SIDL");
         test_state := fail;
       end if;)dnl
define(tx_wait_for_ready,
       TXB1CON.TXREQ <= '0';
       {ifelse($1, {}, wait until TXB1CON.TXREQ == '1';, wait until TXB1CON.TXREQ == '1' for $1 ms;)})dnl
define(tx_rtr,
       tx_wait_for_ready
       if TXB1DLC.TXRTR == '1' then
         report("test_name: RTR request");
       else
         report("test_name: not RTR request");
         test_state := fail;
       end if;)dnl
define(rx_frame,
       RXB0DLC <= 16#0$1#;
       RXB0CON.RXFUL <= '1';
       CANSTAT <= 16#0C#;
       PIR3.RXB0IF <= '1';)dnl
define(rx_wait_for_ready,
       if RXB0CON.RXFUL != '0' then
         wait until RXB0CON.RXFUL == '0';
       end if;)dnl
define(rx_sid,
       rx_wait_for_ready()
       RXB0SIDH <= $1;
       RXB0SIDL <= $2;
       rx_frame(0))dnl
define(rx_data,
       rx_wait_for_ready
       {ifelse($1, {}, RXB0D0 <= 0;, RXB0D0 <= $1;)}
       {ifelse($2, {}, RXB0D1 <= 0;, RXB0D1 <= $2;)}
       {ifelse($3, {}, RXB0D2 <= 0;, RXB0D2 <= $3;)}
       {ifelse($4, {}, RXB0D3 <= 0;, RXB0D3 <= $4;)}
       {ifelse($5, {}, RXB0D4 <= 0;, RXB0D4 <= $5;)}
       {ifelse($6, {}, RXB0D5 <= 0;, RXB0D5 <= $6;)}
       {ifelse($7, {}, RXB0D6 <= 0;, RXB0D6 <= $7;)}
       {ifelse($8, {}, RXB0D7 <= 0;, RXB0D7 <= $8;)}
       rx_frame($#))dnl
