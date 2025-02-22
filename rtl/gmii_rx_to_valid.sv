module gmii_rx_to_valid

(
    input   logic   [7:0]   gmii_rxd,
    input   logic           gmii_rx_dv,
    input   logic           gmii_rx_er,

    output  logic   [7:0]   data_out,
    output  logic           data_valid
);

    assign  data_out    =   gmii_rxd;
    assign  data_valid  =   gmii_rx_dv & ~gmii_rx_er;

endmodule