`ifndef AXIRAM_SMOKE_VIRTUAL_SEQUENCE_SV
`define AXIRAM_SMOKE_VIRTUAL_SEQUENCE_SV

class axiram_smoke_virtual_sequence extends axiram_base_virtual_sequence;

    `uvm_object_utils(axiram_smoke_virtual_sequence)

    function new(string name = "axiram_smoke_virtual_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit[31:0] addr, data;
        super.body();

        `uvm_info(get_type_name(), "entering...", UVM_LOW)
        for(int i = 0; i < 10; i++) begin
            std::randomize(addr) with {addr[1:0] == 0; addr inside {['h1000:'h1FFF]};};
            //data = 0x00 0x11 0x22 0x33 0x44 0x55...
            std::randomize(data) with {data == (i << 4) +i;};
            `uvm_do_with(single_write, {
                addr        == local::addr;
                data        == local::data;
                burst_len   == BURST_LEN_SINGLE;
                burst_type  == INCR;
            })
            `uvm_do_with(single_read, {
                addr == local::addr;
                burst_len   == BURST_LEN_SINGLE;
                burst_type  == INCR;
            })
            wr_val = data;
            rd_val = single_read.data;
            compare_data(wr_val, rd_val);
        end
        `uvm_info(get_type_name(), "entering...", UVM_LOW)
    endtask

endclass

`endif 