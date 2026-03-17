`ifndef AXIRAM_RESET_VIRTUAL_SEQUENCE_SV
`define AXIRAM_RESET_VIRTUAL_SEQUENCE_SV

class axiram_reset_virtual_sequence extends axiram_base_virtual_sequence;
    `uvm_object_utils(axiram_reset_virtual_sequence)

    function new(string name = "axiram_reset_virtual_sequence");
        super.new(name);
    endfunction

    virtual task body();
        write_mid_reset_test();
    endtask

    virtual task write_mid_reset_test();
        bit [31:0] every_beat_data[];
        every_beat_data = new[8];
        foreach (every_beat_data[i]) every_beat_data[i] = 32'hf0f0_0000 + 1;
        
        `uvm_info(get_type_name(), "--- test_write_mid_reset START ---", UVM_LOW)
        fork
            begin
                single_write = axiram_single_write_sequence::type_id::create("single_write");
                single_write.addr = 16'h0300;
                single_write.data = every_beat_data[0];
                single_write.every_beat_data = every_beat_data;
                single_write.burst_len = BURST_LEN_8BEATS;
                single_write.burst_size = BURST_SIZE_4BYTES;
                single_write.burst_type = INCR;
                single_write.start(p_sequencer);
            end
            begin
                //wait AW handshake
                @(posedge vif.aclk iff(vif.awvalid && vif.awready));
                //let 3 beats transfer complete
                repeat(3) @(posedge vif.aclk iff(vif.wvalid && vif.wready));
                //assert reset
                vif.assert_reset();
                //wait 2 posedge for DUT registers to update(doubt!)
                repeat(2) @(posedge vif.aclk);
                //check DUT signals
                check_write_reset_signals();
                //hold reset for some cycles, then release
                repeat(3) @(posedge vif.aclk);
                vif.deassert_reset();
                wait_cycles(5);
            end
        join_any
        `uvm_info(get_type_name(), "--- test_write_mid_reset END ---", UVM_LOW)

    endtask

    local task check_write_reset_signals();
        if(vif.awready !== 1'b0)
            `uvm_error(get_type_name(), $sformatf("RESET FAIL: awready=%b, exp=0", vif.awready))
        if(vif.wready !== 1'b0)
            `uvm_error(get_type_name(), $sformatf("RESET FAIL: wready=%b, exp=0", vif.wready))
        if(vif.bvalid !== 1'b0)
            `uvm_error(get_type_name(), $sformatf("RESET FAIL: bvalid=%b, exp=0", vif.bvalid))
        `uvm_info(get_type_name(), "Write reset signals checked OK", UVM_MEDIUM)
    endtask

    local task do_single_write(bit [15:0] addr, bit [31:0] data);
        bit [31:0] wdata_arr[] = '{data};
        single_write = axiram_single_write_sequence::type_id::create("single_write");
        single_write.addr = addr;
        single_write.data = data;
        single_write.every_beat_data = wdata_arr;
        single_write.burst_len = BURST_LEN_SINGLE;
        single_write.burst_size = BURST_SIZE_4BYTES;
        single_write.burst_type = INCR;
        single_write.start(p_sequencer);
    endtask


endclass

`endif 