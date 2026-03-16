`ifndef AXIRAM_UNALIGNED_VIRTUAL_SEQUENCE_SV
`define AXIRAM_UNALIGNED_VIRTUAL_SEQUENCE_SV

class axiram_unaligned_virtual_sequence extends axiram_base_virtual_sequence;
    `uvm_object_utils(axiram_unaligned_virtual_sequence)

    function new(string name = "axiram_unaligned_virtual_sequence");
        super.new(name);
    endfunction

    virtual task body();
        super.body();
        //single beat transfer with 3 different offsets
        single_beat_unaligned_test(16'h2000, 1); 
        single_beat_unaligned_test(16'h2100, 2);
        single_beat_unaligned_test(16'h2200, 3);

        unaligned_incr_test(16'h3001, 2);
        unaligned_incr_test(16'h3102, 4);
        unaligned_incr_test(16'h3203, 8);

        unaligned_fixed_test(16'h4001, 2);
        unaligned_fixed_test(16'h4202, 4);
        unaligned_fixed_test(16'h4303, 8);
    endtask

    //AXI protocol: with FIXED mode, every beat wstrb are same as first beat
    virtual task unaligned_fixed_test(bit [15:0] base_addr, int num_beats);
        bit [31:0] every_beat_wdata[];
        bit [3:0]  every_beat_wstrb[];
        int offsets = base_addr[1:0];

        every_beat_wdata = new[num_beats];
        every_beat_wstrb = new[num_beats];

        for(int i = 0; i < num_beats; i++) begin
            every_beat_wdata[i] = 32'h1111_1111 + (i << 4) + i;
            every_beat_wstrb[i] = (4'hF << offsets) & 4'hF;
        end

        //write-in
        single_write = axiram_single_write_sequence::type_id::create("single_write");
        single_write.addr               = base_addr;
        single_write.data               = every_beat_data[0];
        single_write.every_beat_data    = every_beat_wdata;
        single_write.every_beat_wstrb   = every_beat_wstrb;
        single_write.burst_len          = burst_len_enum'(num_beats - 1);
        single_write.burst_size         = BURST_SIZE_4BYTES;
        single_write.burst_type         = FIXED;
        single_write.start(p_sequencer);

        //read-out
        single_read = axiram_single_read_sequence::type_id::create("single_read");
        single_read.addr                = base_addr;
        single_read.burst_len           = burst_len_enum'(num_beats - 1);
        single_read.burst_size          = BURST_SIZE_4BYTES;
        single_read.burst_type          = FIXED;
        single_read.start(p_sequencer);
    endtask
    
    //AXI protocol: with INCR mode, only first beat allow unaligned, following beats will aligned automatically
    virtual task unaligned_incr_test(bit [15:0] base_addr, int num_beats);
        bit [31:0] init_data = 32'hBBBB_BBBB;
        bit [15:0] aligned_addr = {base_addr[15:2], 2'b00};
        bit [31:0] every_beat_wdata[];
        bit [3:0]  every_beat_wstrb[];
        int offsets = base_addr[1:0];

        //create actual num of wdata and wstrb
        every_beat_wdata = new[num_beats];
        every_beat_wstrb = new[num_beats];

        //generate every beat's data and wstrb
        for(int i = 0; i < num_beats; i++) begin
            every_beat_wdata[i] = 32'h0000_0000 + (i << 4) + i;
            if(i == 0) begin
                every_beat_wstrb[i] = (4'hF << offsets) & 4'hF;  //first beat unaligned
            end else begin
                every_beat_wstrb[i] = 4'hF;    //following beats are aligned
            end
        end

        //write-in
        begin
            single_write = axiram_single_write_sequence::type_id::create("single_write");
            single_write.addr              = base_addr;
            single_write.data              = every_beat_wdata[0];
            single_write.every_beat_data   = every_beat_wdata;
            single_write.every_beat_wstrb  = every_beat_wstrb;
            single_write.burst_len         = burst_len_enum'(num_beats - 1);
            single_write.burst_size        = BURST_SIZE_4BYTES;
            single_write.burst_type        = INCR;
            single_write.start(p_sequencer);
        end
        //read-out
        begin
            single_read = axiram_single_read_sequence::type_id::create("single_read");
            single_read.addr               = base_addr;
            single_read.burst_len          = burst_len_enum'(num_beats - 1);
            single_read.burst_size         = BURST_SIZE_4BYTES;
            single_read.burst_type         = INCR;
            single_read.start(p_sequencer);
        end

    endtask

    virtual task single_beat_unaligned_test(bit [15:0] base_addr, int offset);
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
        do_aligned_write(base_addr, init_data, 1);

        //unaligned write in
        begin
            bit [31:0] wr_data_arr[];
            bit [3:0] wr_strb_arr[];
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

    local task do_aligned_write(bit [15:0] addr, bit [31:0] data, int num_beats);
        bit [31:0] d[];
        d = new[1];
        d[0] = data;
        single_write = axiram_single_write_sequence::type_id::create("single_write");
        single_write.addr            = addr;
        single_write.data            = data;
        single_write.every_beat_data = d;
        single_write.burst_len       = burst_len_enum'(num_beats - 1);
        single_write.burst_size      = BURST_SIZE_4BYTES;
        single_write.burst_type      = INCR;
        single_write.start(p_sequencer);
    endtask

endclass

`endif 