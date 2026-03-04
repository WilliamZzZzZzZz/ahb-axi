`ifndef AXIRAM_SINGLE_WRITE_SEQUENCE_SV
`define AXIRAM_SINGLE_WRITE_SEQUENCE_SV

class axiram_single_write_sequence extends axiram_base_sequence;

    `uvm_object_utils(axiram_single_write_sequence)

    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand burst_len_enum burst_len;
    rand burst_type_enum burst_type;    

    function new(string name = "axiram_single_write_sequence");
        super.new(name);
    endfunction

    virtual task body();
        axi_master_single_sequence axi_single;
        `uvm_info(get_type_name(), "entering...", UVM_LOW)
        `uvm_do_on_with(axi_single, p_sequencer.axi_mst_sqr, {
            trans_type  == WRITE;
            addr        == local::addr;
            data        == local::data;
            burst_len   == local::burst_len;
            burst_type  == local::burst_type;
        })
        `uvm_info(get_type_name(), "exiting...", UVM_LOW)
    endtask
endclass

`endif 