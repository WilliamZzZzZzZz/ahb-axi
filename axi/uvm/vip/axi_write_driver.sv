`ifndef AXI_WRITE_DRIVER_SV
`define AXI_WRITE_DRIVER_SV

class axi_write_driver extends uvm_object;
    `uvm_object_utils(axi_write_driver)

    virtual axi_if      vif;
    axi_configuration   cfg;

    mailbox #(axi_transaction) req_mbx;
    mailbox #(axi_transaction) aw2w_mbx;
    mailbox #(axi_transaction) aw2b_mbx;

    function new(string name = "axi_write_driver");
        super.new(name);
        req_mbx  = new();
        aw2w_mbx = new();
        aw2b_mbx = new();
    endfunction

    virtual task run_write_channel();
        @(vif.arst === 1'b0);
        fork
            //start three threads
            drive_aw_channel();
            drive_w_channel();
            drive_b_channel();
        join_none
    endtask

    //write address channel
    virtual task drive_aw_channel();
        axi_transaction tr;
        forever begin
            req_mbx.get(tr);    //get response from B channel
            aw2w_mbx.put(tr);   //copy tr to W and B channel
            aw2b_mbx.put(tr);
            //drive AW signals
            @(posedge vif.aclk)
            vif.master_cb.awvalid   <= 1'b1;
            vif.master_cb.awid      <= tr.awid;
            vif.master_cb.awaddr    <= tr.awaddr;
            vif.master_cb.awlen     <= tr.awlen;
            vif.master_cb.awsize    <= tr.awsize;
            vif.master_cb.awburst   <= tr.awburst;
            vif.master_cb.awlock    <= tr.awlock;
            vif.master_cb.awcache   <= tr.awcache;
            vif.master_cb.awprot    <= tr.awprot;
            
            //hanshake polling
            do begin
                @(posedge vif.aclk);
            end while(vif.master_cb.awready === 1'b0);

            //jump out DO loop means handshake success
            vif.master_cb.awvalid <= 1'b0;
        end
    endtask

    //write data channel
    virtual task drive_w_channel();
        axi_transaction tr;
        forever begin
            aw2w_mbx.get(tr);
            for(int i = 0;  i <= tr.awlen; i++) begin
                @(posedge vif.aclk)
                vif.master_cb.wvalid <= 1'b1;
                vif.master_cb.wdata  <= tr.wdata[i];
                vif.master_cb.wstrb  <= tr.wstrb[i];

                //WLAST only at last beat pull 1, otherwise 0
                if(i == tr.awlen) vif.master_cb.wlast <= 1'b1;
                else              vif.master_cb.wlast <= 1'b0;

                //handshake polling
                do begin
                    @(posedge vif.aclk)
                end while(vif.master_cb.wready === 1'b0)
            end
            //transfer finish
            vif.master_cb.wvalid <= 1'b0;
            vif.master_cb.wlast  <= 1'b0;
        end
    endtask

    //write response channel
    virtual task drive_b_channel();
        axi_transaction tr;
        forever begin
            aw2b_mbx.get(tr);

            //ready get response from DUT
            vif.master_cb.bready <= 1'b1;

            //handshake polling
            do begin
                @(posedge vif.aclk);
            end while(vif.master_cb.bvalid === 1'b0)

            //check id
            if(vif.master_cb.bid != tr.awid) begin
                `uvm_error(get_type_name(), $sformatf("B Channel ID Mismatch! Expt: %0h, Act: %0h", tr.awid, vif.master_cb.bid))
            end
            else begin
                `uvm_info(get_type_name(), "ID Check PASS!", UVM_LOW)
            end

            //get response finish
            vif.master_cb.bready <= 1'b0;
        end
    endtask

endclass 

`endif 