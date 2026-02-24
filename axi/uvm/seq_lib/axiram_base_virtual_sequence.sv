`ifndef AXIRAM_BASE_VIRTUAL_SEQUENCE_SV
`define AXIRAM_BASE_VIRTUAL_SEQUENCE_SV

class axiram_base_virtual_sequence extends uvm_sequence;

    virtual axi_if vif;
    bit[31:0] wr_val, rd_val;

    axiram_single_write_sequence single_write;
    axiram_single_read_sequence single_read;

    `uvm_object_utils(axiram_base_virtual_sequence)
    `uvm_declare_p_sequencer(axiram_virtual_sequencer)

    function new(string name = "axiram_base_virtual_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info(get_type_name(), "entering...", UVM_LOW)

        `uvm_info(get_type_name(), "exiting...", UVM_LOW)
    endtask

    virtual function void compare_data(logic[31:0] val1, logic[31:0] val2);
        if(val1 === val2)
            `uvm_info("CMP-SUCCESS", $sformatf("val1 'h%0x === val2 'h%0x", val1, val2), UVM_LOW)
        else begin
            `uvm_error("CMP-ERROR", $sformatf("val1 'h%0x === val2 'h%0x", val1, val2))
        end
    endfunction  

    task wait_cycles(int n);
        repeat(n) @(posedge vif.aclk);
    endtask
endclass

`endif 