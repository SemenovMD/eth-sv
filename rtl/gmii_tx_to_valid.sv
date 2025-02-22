module gmii_tx_to_valid

(
    input   logic   [7:0]   data_in,
    input   logic           data_valid,

    output  logic   [7:0]   gmii_txd,
    output  logic           gmii_tx_en,
    output  logic           gmii_tx_er
);

    assign  gmii_txd    =   data_in;
    assign  gmii_tx_en  =   data_valid;
    assign  gmii_tx_er  =   'd0;

endmodule