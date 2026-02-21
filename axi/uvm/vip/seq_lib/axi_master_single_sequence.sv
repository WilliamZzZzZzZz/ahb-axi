`ifndef AXI_MASTER_SINGLE_SEQUENCE_SV
`define AXI_MASTER_SINGLE_SEQUENCE_SV

class axi_master_single_sequence extends axi_base_sequence;
    `uvm_object_utils(axi_master_single_sequence)

    rand bit [15:0] addr;
    rand bit [31:0] data;
    rand trans_type_enum trans_type;

    constraint single_trans_type_cstr {
        trans_type inside {READ, WRITE};
    }

    function new(string name = "axi_master_single_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        `uvm_info(get_type_name(), "started sequence", UVM_LOW)
        if(trans_type == WRITE) begin
            do_write();
        end else begin
            do_read();
        end
    endtask

    virtual task do_write();
        `uvm_do_with(req, {
            trans_type      == WRITE;
            awid            == 0;                  //smoke test only
            awaddr          == local::addr;
            awlen           == BURST_LEN_SINGLE;
            awsize          == BURST_SIZE_4BYTES;
            awburst         == INCR;
            awlock          == NORMAL;
            awcache         == NONBUFFER;
            awprot          == NPRI_SEC_DATA;
            wdata.size()    == 1;
            wdata[0]        == local::data;
        })
        get_response(rsp);
        //id set 0 in smoke test, so no need to check id temporarily
        //check response
        if(rsp.bresp == OKAY) begin
            `uvm_info(get_type_name(), $sformatf("write complete: ADDR=%0h DATA=%0h", addr, data), UVM_MEDIUM)
        end else begin
            `uvm_error(get_type_name(), $sformatf("write error: ADDR=%0h DATA=%0h", addr, data))
        end
    endtask

    virtual task do_read();
        `uvm_do_with(req, {
            trans_type  == READ;
            arid        == 0;
            araddr      == local::addr;
            arlen       ==  BURST_LEN_SINGLE;
            arsize      == BURST_SIZE_4BYTES;
            arburst     == INCR;
            arlock      == NORMAL;
            arcache     == NONBUFFER;
            arprot      == NPRI_SEC_DATA;
        })
        get_response(rsp);
        //id set 0 in smoke test, so no need to check id temporarily
        //check response
        if(rsp.rresp == OKAY) begin
            data =rsp.rdata[0];
            `uvm_info(get_type_name(), $sformatf("read complete: ADDR=%0h DATA=%0h", addr, data), UVM_MEDIUM)
        end else begin
            `uvm_error(get_type_name(), $sformatf("read error: ADDR=%0h DATA=%0h", addr, data))
        end
    endtask

endclass

`endif 