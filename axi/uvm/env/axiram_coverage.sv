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
        cg_burst_len  = new();
        cg_burst_size = new();
        cg_burst_type = new();
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
        cg_burst_len.sample();
        cg_burst_size.sample();
        cg_burst_type.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
    endfunction

    //trans_type
    covergroup cg_trans_type;
        option.per_instance = 1;
        option.name = "transaction type coverage";

        TRANS_TYPE: coverpoint trans_type {
            bins write = {WRITE};
            bins read  = {READ};
        }
    endgroup
    
    //burst_len
    covergroup cg_burst_len;
        option.per_instance = 1;
        option.name = "burst length coverage";

        BURST_LEN: coverpoint burst_len {
            bins beat_single = {BURST_LEN_SINGLE};
            bins beats_2     = {BURST_LEN_DOUBLE};
            bins beats_4     = {BURST_LEN_4BEATS};
            bins beats_8     = {BURST_LEN_8BEATS};
            bins beats_16    = {BURST_LEN_16BEATS};
        }
    endgroup
    
    //burst_size
    //for DATA_WIDTH = 32, burst size only can be 1, 2, 4
    covergroup cg_burst_size;
        option.per_instance = 1;
        option.name = "burst size coverage";

        BURST_SIZE: coverpoint burst_size {
            bins byte_1 = {BURST_SIZE_1BYTE};
            bins byte_2 = {BURST_SIZE_2BYTES};
            bins byte_4 = {BURST_SIZE_4BYTES};
        }
    endgroup

    //burst_type
    covergroup cg_burst_type;
        option.per_instance = 1;
        option.name = "burst type coverage";

        BURST_TYPE: coverpoint burst_type {
            bins fixed_mode = {FIXED};
            bins incr_mode  = {INCR};
        }
    endgroup
endclass

`endif 