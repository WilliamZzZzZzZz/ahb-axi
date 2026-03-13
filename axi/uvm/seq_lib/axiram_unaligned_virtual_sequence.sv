`ifndef AXIRAM_UNALIGNED_VIRTUAL_SEQUENCE_SV
`define AXIRAM_UNALIGNED_VIRTUAL_SEQUENCE_SV

class axiram_unaligned_virtual_sequence extends axiram_base_virtual_sequence;
    `uvm_object_utils(axiram_unaligned_virtual_sequence)

    function new(string name = "axiram_unaligned_virtual_sequence");
        super.new(name);
    endfunction

    virtual task body();
        super.body();
        test_single_beat_unaligned(16'h2000, 1); 

    endtask

    virtual task test_single_beat_unaligned( 
        bit [15:0] base_addr,
        int        offset  
    );
        bit [31:0] init_data = 32'hDEAD_BEEF;
        bit [31:0] new_data  = 32'h1234_5678;
        bit [3:0]  unaligned_wstrb;
        bit [31:0] expected_data;

        //calculate valid data with wstrb
        //offset=1 → 4'b1110, offset=2 → 4'b1100, offset=3 → 4'b1000
        unaligned_wstrb = (4'hF << offset) & 4'hF;

        //calculate the expected data via initial data and wstrb
        expected_data = init_data;
        for (int lane = 0; lane < 4; lane++) begin
            if (unaligned_wstrb[lane])
                expected_data[lane*8 +: 8] = new_data[lane*8 +: 8];
        end

        //write in initial data wiht wstrb = 4'hF
        do_agligned_write(base_addr, init_data);

        //unaligned write in
        begin
            bit [31:0] wr_data_arr[];
            bit [31:0] wr_strb_arr[];
            wr_data_arr = new[1];
            wr_strb_arr = new[1];
            wr_data_arr[0] = new_data;
            wr_strb_arr[0] = unaligned_wstrb;

            single_write = axiram_single_write_sequence::type_id::create("single_write");
            single_write.addr               = base_addr;
            single_write.data               = new_data;
            single_write.every_beat_data    = wr_data_arr;
            single_write.every_beat_wstrb   = wr_strb_arr;
            single_write.burst_len          = BURST_LEN_SINGLE;
            single_write.burst_type         = INCR;
            single_write.start(p_sequencer);
        end

        //read out and verify
        begin
            single_read = axiram_single_read_sequence::type_id::create("single_read");
            single_read.addr = base_addr;
            single_read.burst_len = BURST_LEN_SINGLE;
            single_read.burst_type = INCR;
            single_read.start(p_sequencer);

            //verify
            compare_single_data(expected_data, single_read.data);
        end

    endtask


    local task do_agligned_write(bit [15:0] addr, bit [31:0] data);
        bit [31:0] d[];
        d = new[1];
        d[0] = data;
        single_write = axiram_single_write_sequence::type_id::create("single_write");
        single_write.addr            = addr;
        single_write.data            = data;
        single_write.every_beat_data = d;
        single_write.burst_len       = BURST_LEN_SINGLE;
        single_write.burst_type      = INCR;
        single_write.start(p_sequencer);
    endtask

endclass

`endif 