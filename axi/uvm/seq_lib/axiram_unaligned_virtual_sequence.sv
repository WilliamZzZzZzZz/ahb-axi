`ifndef AXIRAM_UNALIGNED_VIRTUAL_SEQUENCE_SV
`define AXIRAM_UNALIGNED_VIRTUAL_SEQUENCE_SV

class axiram_unaligned_virtual_sequence extends axiram_base_virtual_sequence;
    `uvm_object_utils(axiram_unaligned_virtual_sequence)

    function new(string name = "axiram_unaligned_virtual_sequence");
        super.new(name);
    endfunction

    virtual task body();
        super.body();
        
    endtask
endclass

`endif 