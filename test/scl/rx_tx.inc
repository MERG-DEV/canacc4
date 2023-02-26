define(tx_wait_if_not_ready,
       if TXB1CON.TXREQ == '0'then
       {ifelse($1, {},   wait until TXB1CON.TXREQ == '1';,   wait until TXB1CON.TXREQ == '1' for $1 ms;)}
       end if;
       if TXB1CON.TXREQ == '1' then
         report("test_name: Tx");
       else
         {ifelse($1, {},   report("test_name: No Tx");,   report("test_name: No Tx in $1 ms");)}
       end if;)dnl
define(tx_not_ready,
       TXB1CON.TXREQ <= '0';)dnl
define(tx_wait_for_ready,
       tx_not_ready
       {ifelse($1, {}, tx_wait_if_not_ready, tx_wait_if_not_ready($1))})dnl
define(tx_check_data,
       if $1 != $2 then
         report("test_name: Tx wrong $3");
         test_state := fail;
       end if;)dnl
define(tx_check_response,
       tx_wait_if_not_ready
       {ifelse( $1, {}, {--}, tx_check_data(TXB1D0,  $1,   $2))}
       {ifelse( $3, {}, {--}, tx_check_data(TXB1D1,  $3,   $4))}
       {ifelse( $5, {}, {--}, tx_check_data(TXB1D2,  $5,   $6))}
       {ifelse( $7, {}, {--}, tx_check_data(TXB1D3,  $7,   $5))}
       {ifelse( $9, {}, {--}, tx_check_data(TXB1D4,  $9,  $10))}
       {ifelse($11, {}, {--}, tx_check_data(TXB1D5, $11,  $12))}
       {ifelse($13, {}, {--}, tx_check_data(TXB1D6, $13,  $14))}
       {ifelse($15, {}, {--}, tx_check_data(TXB1D7, $15,  $16))})dnl
define(tx_wait_for_response,
       tx_not_ready
       {tx_check_response($*)})dnl
define(tx_check_node_response,
       tx_wait_if_not_ready
       {tx_check_response $1, response, $2, Node Number (high), $3, Node Number (low), $4, $5, $6, $7, $8, $9), $10, $11, $12, $13))})dnl
define(tx_wait_for_node_response,
       tx_not_ready
       {tx_check_node_response($*)})dnl
define(tx_check_no_response,
       {ifelse($1, {}, {--}, tx_wait_for_ready($1))}
       if TXB1CON.TXREQ == '1' then
         report("test_name: Unexpected response sent");
         test_state := fail;
       else
         {ifelse($1, {}, report("test_name: No response sent");, report("test_name: No response sent in $1 ms");)}
       end if;)dnl
define(tx_check_rtr_response,
       TXB2CON.TXREQ <= '0';
       wait until TXB2CON.TXREQ == '1';
       report("test_name: RTR response sent");
       if TXB2SIDH != $1 then
         report("test_name: Incorrect RTR SIDH");
         test_state := fail;
       end if;
       if TXB2SIDL != $2 then
         report("test_name: Incorrect RTR SIDL");
         test_state := fail;
       end if;
       if TXB2DLC != 0 then
         report("test_name: Incorrect RTR data length");
         test_state := fail;
       end if;)dnl
define(tx_check_no_rtr_response,
       TXB2CON.TXREQ <= '0';
       wait until TXB2CON.TXREQ == '1' for $1 ms;
       if TXB2CON.TXREQ == '1' then
         report("test_name: Unexpected RTR response sent");
         test_state := fail;
       else
         report("test_name: No RTR response sent in $1 ms");
       end if;)dnl
define(tx_rtr,
       tx_wait_for_ready
       if TXB1DLC.TXRTR == '1' then
         report("test_name: RTR request");
       else
         report("test_name: not RTR request");
         test_state := fail;
       end if;)dnl
define(tx_check_can_id,
       if TXB1SIDH != $2 then
         report("test_name: Incorrect $1 CAN Id SIDH");
         test_state := fail;
       end if;
       if TXB1SIDL != $3 then
         report("test_name: Incorrect $1 CAN Id SIDL");
         test_state := fail;
       end if;)dnl
define(tx_can_id,
       tx_wait_for_ready
       tx_check_can_id($1, $2, $3))dnl
define(rx_wait_if_not_ready,
       if RXB0CON.RXFUL != '0' then
         wait until RXB0CON.RXFUL == '0';
       end if;)dnl
define(rx_frame,
       RXB0DLC <= 16#0$1#;
       RXB0CON.RXFUL <= '1';
       CANSTAT <= 16#0C#;
       PIR3.RXB0IF <= '1';)dnl
define(rx_rtr,
       rx_wait_if_not_ready
       rx_frame(40))dnl
define(rx_sid,
       rx_wait_if_not_ready
       RXB0SIDH <= $1;
       RXB0SIDL <= $2;
       rx_frame(0))dnl
define(rx_data,
       rx_wait_if_not_ready
       {ifelse($1, {}, RXB0D0 <= 0;, RXB0D0 <= $1;)}
       {ifelse($2, {}, RXB0D1 <= 0;, RXB0D1 <= $2;)}
       {ifelse($3, {}, RXB0D2 <= 0;, RXB0D2 <= $3;)}
       {ifelse($4, {}, RXB0D3 <= 0;, RXB0D3 <= $4;)}
       {ifelse($5, {}, RXB0D4 <= 0;, RXB0D4 <= $5;)}
       {ifelse($6, {}, RXB0D5 <= 0;, RXB0D5 <= $6;)}
       {ifelse($7, {}, RXB0D6 <= 0;, RXB0D6 <= $7;)}
       {ifelse($8, {}, RXB0D7 <= 0;, RXB0D7 <= $8;)}
       rx_frame($#))dnl
