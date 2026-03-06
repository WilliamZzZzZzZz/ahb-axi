`ifndef AXIRAM_SINGLE_READ_SEQUENCE_SV
`define AXIRAM_SINGLE_READ_SEQUENCE_SV

class axiram_single_read_sequence extends axiram_base_sequence;

    `uvm_object_utils(axiram_single_read_sequence)

    rand bit[31:0] addr;
    rand bit[31:0] data;
    rand burst_len_enum burst_len;
    rand burst_type_enum burst_type;

    bit [31:0] every_beat_data[];   //store every beat's data

    function new(string name = "axiram_single_read_sequence");
        super.new(name);
    endfunction

    virtual task body();
    axi_master_single_sequence axi_single;
    `uvm_info(get_type_name(), "entering...", UVM_LOW)

    axi_single = axi_master_single_sequence::type_id::create("axi_single");
    axi_single.trans_type  = READ;
    axi_single.addr        = addr;
    axi_single.burst_len   = burst_len;
    axi_single.burst_type  = burst_type;

    axi_single.start(p_sequencer.axi_mst_sqr);

    every_beat_data = axi_single.every_beat_data;
    data            = axi_single.data;

    // `uvm_do_on_with(axi_single, p_sequencer.axi_mst_sqr, {
    //     trans_type  == READ;
    //     addr        == local::addr;
    //     burst_len   == local::burst_len;
    //     burst_type  == local::burst_type;
    // })
    // data = axi_single.data;
    `uvm_info(get_type_name(), "exiting...", UVM_LOW)
    endtask
endclass

`endif 