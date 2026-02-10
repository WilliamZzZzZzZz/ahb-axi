class axi_read_driver extends uvm_object;
    `uvm_object_utils(axi_read_driver)

    virtual axi_if vif;
    axi_configuration cfg;

    mailbox #(axi_transaction) req_mbx;
    mailbox #(axi_transaction) ar2r_mbx;

    function new(string name = "axi_read_driver");
        super.new(name);
        req_mbx  = new();
        ar2r_mbx = new();
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        @(vif.arst === 1'b0);
        fork
            //two read channel threads
            drive_ar_channel();
            drive_r_channel();
        join_none
    endtask

    task drive_ar_channel();
        axi_transaction tr;
        forever begin
            req_mbx.get(tr);
            ar2r_mbx.put(tr);
            //drive AR signals
            @(posedge vif.aclk);
            vif.master_cb.arvalid   <= 1'b1;
            vif.master_cb.arid      <= tr.arid;
            vif.master_cb.araddr    <= tr.araddr;
            vif.master_cb.arlen     <= tr.arlen;
            vif.master_cb.arsize    <= tr.arsize;
            vif.master_cb.arburst   <= tr.arburst;
            vif.master_cb.arlock    <= tr.arlock;
            vif.master_cb.arcache   <= tr.arcache;
            vif.master_cb.arprot    <= tr.arprot;
            
            //handshake polling
            do begin
                @(posedge vif.aclk);
            end while(vif.master_cb.arready === 1'b0)

            vif.master_cb.arvalid <= 1'b0;
        end
    endtask

    task drive_r_channel();
        axi_transaction tr;
        forever begin
            ar2r_mbx.get(tr);
            
            for(int i = 0; i <= tr.arlen; i++) begin
                //ready read data from DUT
                vif.master_cb.rready <= 1'b1;

                //handshake polling
                do begin
                    @(posedge vif.aclk);
                end while(vif.master_cb.rvalid === 1'b0)
                //collect data
                tr.data[i] = vif.master_cb.rdata;

                //check ID
                if(vif.master_cb.rid != tr.arid) begin
                    `uvm_error(get_type_name(), $sformatf("Read Channel ID Mismatch! Expt: %0h, Act: %0h", tr.arid, vif.master_cb.rid))
                end
                else begin
                    `uvm_info(get_type_name(), "ID Check PASS!", UVM_LOW)
                end
                //check RLAST
                if((i == tr.arlen) && (vif.rlast == 1'b1)) begin 
                    `uvm_info(get_type_name(), "RLAST Check PASS!", UVM_LOW)
                end

            end
        end
    endtask

endclass