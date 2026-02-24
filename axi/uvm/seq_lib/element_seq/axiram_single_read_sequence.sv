`ifndef AXIRAM_SINGLE_READ_SEQUENCE_SV
`define AXIRAM_SINGLE_READ_SEQUENCE_SV

class axiram_single_read_sequence extends axiram_base_sequence;

    `uvm_object_utils(axiram_single_read_sequence)

    rand bit[31:0] addr;
    rand bit[31:0] data;

    function new(string name = "axiram_single_read_sequence");
        super.new(name);
    endfunction

    virtual task body();
    axi_master_single_sequence axi_single;
    `uvm_info(get_type_name(), "entering...", UVM_LOW)
    `uvm_do_on_with(axi_single, p_sequencer.axi_mst_sqr, {
        trans_type  == READ;
        araddr      == local::addr;
    })
    data = axi_single.data;
    `uvm_info(get_type_name(), "exiting...", UVM_LOW)
    endtask
endclass

`endif 