`ifndef AXIRAM_NARROW_VIRTUAL_SEQUENCE_SV
`define AXIRAM_NARROW_VIRTUAL_SEQUENCE_SV

class axiram_narrow_virtual_sequence extends axiram_base_test;
    `uvm_object_utils(axiram_narrow_virtual_sequence)

    function new(string name = "axiram_narrow_virtual_sequence");
        super.new(name);
    endfunction

    virtual task body();
        super.body();
        narrow_incr_test(16'h7000, 4, BURST_SIZE_1BYTE);    //no cross boundary test(full word)
        narrow_incr_test(16'h7100, 2, BURST_SIZE_2BYTE);    //no cross boundary test(full word)
        narrow_incr_test(16'h7202, 4, BURST_SIZE_1BYTE);    //cross boundary test
    endtask

    virtual task narrow_incr_test(bit [15:0] base_addr, int num_beats, burst_size_enum burst_size);
        bit [31:0] init_data;
        bit [31:0] wdata_arr;
        bit [3:0]  wstrb_arr;
        int stride = 1 << int'(burst_size);  //byte width of 1 beat
        bit [15:0] first_word_addr;
        bit [15:0] last_word_addr;
        bit [15:0] last_beat_addr;
        bit [15:0] current_beat_addr;
        
        wdata_arr = new[num_beats];
        wstrb_arr = new[num_beats];

        //no cross boundary: first_word_addr = last_word_addr
        //cross boundary:   first_word_addr != last_word_addr
        first_word_addr = {base_addr[15:2], 2'b00};
        last_beat_addr  = base_addr + (num_beats - 1) * stride;
        last_word_addr  = {last_beat_addr[15:0], 2'b00};

        //pre write-in initial data
        begin
            bit [15:0] address = first_word_addr;
            while (1) begin
                do_unaligned_write(address, init_data);
                if(address == last_word_addr) break;
                address = address + 4;
            end
        end

        //construct wdata and wstrb: place data on correct byte lane per beat
        for(int i = 0; i < num_beats; i++) begin
            current_beat_addr = base_addr + i * stride;     //every beat's address
            lane = current_beat_addr[1:0];
            wdata_arr[i] = 0;          //clear every lane, make sure only the choosen lane data write in
            case (burst_size)
                BURST_SIZE_1BYTE: begin
                    wdata_arr[i][lane*8 +: 8] = 8'hA0 + i;
                    wstrb_arr[i] = 4'b0001 << lane;     //only enable the choosen lane
                end
                BURST_SIZE_2BYTES: begin
                    wdata_arr[i][lane[1]*16 +: 16] = 16'hBB00 + i;
                    wstrb_arr[i] = lane[1] ? 4'b1100 : 4'b0011;
                end
                default: `uvm_fatal(get_type_name(), "unsupported narrow burst size")
            endcase
        end
        //write-in
        single_write = axiram_single_write_sequence::type_id::create("single_write");
        single_write.addr               = base_addr;
        single_write.data               = wdata_arr[0];
        single_write.every_beat_data    = wdata_arr;
        single_write.every_beat_wstrb   = wstrb_arr;
        single_write.burst_len          = burst_len_enum'(num_beats - 1);
        single_write.burst_size         = burst_size;
        single_write.burst_type         = INCR;
        single_write.start(p_sequencer);
        //read-back
        begin
            bit [15:0] address = first_word_addr;
            while (1) begin
                single_read = axiram_single_read_sequence::type_id::create("single_read");
                single_read.addr        = address;
                single_read.burst_len   = BURST_LEN_SINGLE;
                single_read.burst_size  = BURST_SIZE_4BYTE;
                single_read.burst_type  = INCR;
                singel_read.start(p_sequencer);
                if(address == last_word_addr) break;
                address = address + 4;
            end
        end
    endtask

    //single beat pre write-in initial data
    local task do_aligned_write(bit [15:0] addr, bit [31:0] data);
        bit [31:0] d[];
        d = new[1];
        d[0] = data;
        single_write = axiram_single_write_sequence::type_id::create("single_write");
        single_write.addr            = addr;
        single_write.data            = data;
        single_write.every_beat_data = d;
        single_write.burst_len       = BURST_LEN_SINGLE;
        single_write.burst_size      = BURST_SIZE_4BYTES;
        single_write.burst_type      = INCR;
        single_write.start(p_sequencer);
    endtask
endclass

`endif 