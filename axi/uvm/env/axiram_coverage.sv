`ifndef AXIRAM_COVERAGE_SV
`define AXIRAM_COVERAGE_SV

class axiram_coverage extends uvm_subscriber #(axi_transaction);
    `uvm_component_utils(axiram_coverage)

    trans_type_enum trans_type;
    burst_len_enum  burst_len;
    burst_size_enum burst_size;
    burst_type_enum burst_type;
    bit [15:0]      addr;
    bit [3:0]       wstrb;

    function new(string name  = "axiram_coverage", uvm_component parent = null);
        super.new(name, parent);
        //TODO new every covergroup below
        cg_trans_type = new();
    endfunction

    //automatically callback while monitor finish every single transaction
    virtual function void write(axi_transaction tr);
        trans_type = tr.trans_type;
        if(tr.trans_type == WRITE) begin
            addr        = tr.awaddr;
            burst_len   = tr.awlen;
            burst_size  = tr.awsize;
            burst_type  = tr.awburst;
            wstrb       = (tr.wstrb.size() > 0) ? tr.wstrb[0][3:0] : 4'hF;
        end else begin  //READ
            addr        = tr.araddr;
            burst_len   = tr.arlen;
            burst_size  = tr.arsize;
            burst_type  = tr.arburst;
            wstrb       = 4'h0;
        end
        //TODO sample every covergroup
        cg_trans_type.sample();
    endfunction

    //trans_types' covergroup
    covergroup cg_trans_type;
        option.per_instance = 1;
        option.name = "transaction type coverage";

        TRANS_TYPE: coverpoint trans_type {
            bins write = {WRITE};
            bins read  = {READ};
        }
    endgroup
endclass

`endif 