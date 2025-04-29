module rgmii_to_gmii_wrapper (
    input   wire           reset,

    output  wire   [3:0]   rgmii_td,
    output  wire           rgmii_tx_ctl,
    output  wire           rgmii_txc,
    
    input   wire   [3:0]   rgmii_rd,
    input   wire           rgmii_rx_ctl,
    input   wire           rgmii_rxc,

    input   wire   [7:0]   gmii_txd,
    input   wire           gmii_tx_en,
    input   wire           gmii_tx_er,
    output  wire           gmii_tx_clk,
    
    output  wire   [7:0]   gmii_rxd,
    output  wire           gmii_rx_dv,
    output  wire           gmii_rx_er,
    output  wire           gmii_rx_clk,

    // output  wire           gmii_crs,
    // output  wire           gmii_col,

    input   wire   [1:0]   speed_selection,
    input   wire           duplex_mode
);

    rgmii_to_gmii rgmii_to_gmii_inst 
    (
        .reset(reset),
        .rgmii_td(rgmii_td),
        .rgmii_tx_ctl(rgmii_tx_ctl),
        .rgmii_txc(rgmii_txc),
        .rgmii_rd(rgmii_rd),
        .rgmii_rx_ctl(rgmii_rx_ctl),
        .rgmii_rxc(rgmii_rxc),
        .gmii_txd(gmii_txd),
        .gmii_tx_en(gmii_tx_en),
        .gmii_tx_er(gmii_tx_er),
        .gmii_tx_clk(gmii_tx_clk),
        .gmii_rxd(gmii_rxd),
        .gmii_rx_dv(gmii_rx_dv),
        .gmii_rx_er(gmii_rx_er),
        .gmii_rx_clk(gmii_rx_clk),
        //.gmii_crs(gmii_crs),
        //.gmii_col(gmii_col),
        .speed_selection(speed_selection),
        .duplex_mode(duplex_mode)
    );

endmodule