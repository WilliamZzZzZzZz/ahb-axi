`ifndef AXIRAM_BASE_VIRTUAL_SEQUENCE_SV
`define AXIRAM_BASE_VIRTUAL_SEQUENCE_SV

class axiram_base_virtual_sequence extends uvm_sequence;

    virtual axi_if vif;
    bit[31:0] wr_val, rd_val;

    

endclass

`endif 