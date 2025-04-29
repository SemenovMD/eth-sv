module rgmii_to_gmii

(
    input   logic           reset,

    output  logic   [3:0]   rgmii_td,
    output  logic           rgmii_tx_ctl,
    output  logic           rgmii_txc,
    
    input   logic   [3:0]   rgmii_rd,
    input   logic           rgmii_rx_ctl,
    input   logic           rgmii_rxc,

    input   logic   [7:0]   gmii_txd,
    input   logic           gmii_tx_en,
    input   logic           gmii_tx_er,
    output  logic           gmii_tx_clk,
    
    output  logic   [7:0]   gmii_rxd,
    output  logic           gmii_rx_dv,
    output  logic           gmii_rx_er,
    output  logic           gmii_rx_clk,

    // output  logic           gmii_crs,
    // output  logic           gmii_col,

    input   logic   [1:0]   speed_selection,
    input   logic           duplex_mode
);

    logic gigabit;
    logic gmii_tx_clk_s;
    logic gmii_rx_dv_s;
    logic [7:0] gmii_rxd_s;
    logic rgmii_rx_ctl_delay;
    logic rgmii_rx_ctl_s;

    logic tx_reset_d1;
    logic tx_reset_sync;
    logic rx_reset_d1;
    logic [7:0] gmii_txd_r;
    logic gmii_tx_en_r;
    logic gmii_tx_er_r;
    logic [7:0] gmii_txd_r_d1;
    logic gmii_tx_en_r_d1;
    logic gmii_tx_er_r_d1;

    logic rgmii_tx_ctl_r;
    logic [3:0] gmii_txd_low;

    assign gigabit = speed_selection[1];
    assign gmii_tx_clk = gmii_tx_clk_s;
    assign gmii_tx_clk_s = gmii_rx_clk;

    always_ff @(posedge gmii_rx_clk) begin
        gmii_rxd   = gmii_rxd_s;
        gmii_rx_dv = gmii_rx_dv_s;
        gmii_rx_er = gmii_rx_dv_s ^ rgmii_rx_ctl_s;
    end

    always_ff @(posedge gmii_tx_clk_s) begin
        tx_reset_d1   <= reset;
        tx_reset_sync <= tx_reset_d1;
    end

    always_ff @(posedge gmii_tx_clk_s) begin
        rgmii_tx_ctl_r = gmii_tx_en_r ^ gmii_tx_er_r;
        gmii_txd_low   = gigabit ? gmii_txd_r[7:4] : gmii_txd_r[3:0];
        // gmii_col       = duplex_mode ? 1'b0 : (gmii_tx_en_r | gmii_tx_er_r) & (gmii_rx_dv | gmii_rx_er);
        // gmii_crs       = duplex_mode ? 1'b0 : (gmii_tx_en_r | gmii_tx_er_r | gmii_rx_dv | gmii_rx_er);
    end

    always_ff @(posedge gmii_tx_clk_s) begin
        if (!tx_reset_sync) begin
            gmii_txd_r      <= 8'h0;
            gmii_tx_en_r    <= 1'b0;
            gmii_tx_er_r    <= 1'b0;
        end else begin
            gmii_txd_r      <= gmii_txd;
            gmii_tx_en_r    <= gmii_tx_en;
            gmii_tx_er_r    <= gmii_tx_er;
            gmii_txd_r_d1   <= gmii_txd_r;
            gmii_tx_en_r_d1 <= gmii_tx_en_r;
            gmii_tx_er_r_d1 <= gmii_tx_er_r;
        end
    end

    //////////////////////////////////////////////////////////////////////////////
    // RX
    //////////////////////////////////////////////////////////////////////////////

    assign gmii_rx_clk = rgmii_rxc;

    generate
        for (genvar i = 0; i < 4; i++) begin : gen_rx_data
            IDDR #(
                .DDR_CLK_EDGE("OPPOSITE_EDGE"),
                .INIT_Q1(1'b0),
                .INIT_Q2(1'b0),
                .SRTYPE("SYNC")
            ) rgmii_rx_iddr (
                .Q1(gmii_rxd_s[i]),
                .Q2(gmii_rxd_s[i+4]),
                .C(gmii_rx_clk),
                .CE(1'b1),
                .D(rgmii_rd[i]),
                .R(1'b0),
                .S(1'b0)
            );
        end
    endgenerate

    IDDR #(
        .DDR_CLK_EDGE("OPPOSITE_EDGE"),
        .INIT_Q1(1'b0),
        .INIT_Q2(1'b0),
        .SRTYPE("SYNC")
    ) rgmii_rx_ctl_iddr (
        .Q1(gmii_rx_dv_s),
        .Q2(rgmii_rx_ctl_s),
        .C(gmii_rx_clk),
        .CE(1'b1),
        .D(rgmii_rx_ctl),
        .R(1'b0),
        .S(1'b0)
    );

    //////////////////////////////////////////////////////////////////////////////
    // TX
    //////////////////////////////////////////////////////////////////////////////

    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .INIT(1'b0),
        .SRTYPE("ASYNC")
    ) U_ODDR2 (
        .Q(rgmii_txc),
        .C(gmii_tx_clk_s),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );

    generate
        genvar i;
        for (i = 0; i < 4; i++) begin : gen_tx_data
            ODDR #(
                .DDR_CLK_EDGE("SAME_EDGE"),
                .INIT(1'b0),
                .SRTYPE("ASYNC")
            ) U2_ODDR2 (
                .Q(rgmii_td[i]),
                .C(gmii_tx_clk_s),
                .CE(1'b1),
                .D1(gmii_txd_r_d1[i]),
                .D2(gmii_txd_low[i]),
                .R(1'b0),
                .S(1'b0)
            );
        end
    endgenerate

    ODDR #(
        .DDR_CLK_EDGE("SAME_EDGE"),
        .INIT(1'b0),
        .SRTYPE("ASYNC")
    ) U3_ODDR2 (
        .Q(rgmii_tx_ctl),
        .C(gmii_tx_clk_s),
        .CE(1'b1),
        .D1(gmii_tx_en_r_d1),
        .D2(rgmii_tx_ctl_r),
        .R(1'b0),
        .S(1'b0)
    );

endmodule
