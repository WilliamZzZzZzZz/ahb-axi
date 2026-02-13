`ifndef AXI_MASTER_DRIVER_SV
`define AXI_MASTER_DRIVER_SV

class axi_master_driver extends uvm_driver#(axi_transaction);
    `uvm_component_utils(axi_master_driver)

    axi_configuration cfg;
    virtual axi_if vif;

    axi_write_driver    write_drv;
    axi_read_driver     read_drv;

    function new(string name = "axi_master_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function build_phase(uvm_phase phase);
        super.build_phase(phase);
        write_drv = axi_write_driver::type_id::create("write_drv", this);
        read_drv  = axi_read_driver::type_id::create("read_drv", this);
    endfunction

    function connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        write_drv.cfg = cfg;
        write_drv.vif = vif;
        read_drv.cfg  = cfg;
        read_drv.vif  = vif;
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        write_drv.run_write_channel();
        read_drv.run_read_channel();
        forever begin
            //always monitor reset signals
            reset_listener();
            seq_item_port.get_next_item(req);
            //WRITE or READ
            if(req.trans_type == WRITE) begin
                write_drv.req_mbx.put(req);
                seq_item_port.item_done();
            end
            else begin  //READ
                read_drv.req_mbx.put(req);
                seq_item_port.item_done();
            end
        end
    endtask

    //AXI4 protocol：reset assert, 5 channels' VAILD should be 0  
    virtual task reset_listener();
        @(posedge vif.arst)
        vif.master_cb.awvalid   <= 1'b0;
        vif.master_cb.wvalid    <= 1'b0;
        vif.master_cb.bvalid    <= 1'b0;
        vif.master_cb.arvalid   <= 1'b0;
        vif.master_cb.rvalid    <= 1'b0;
    endtask

endclass

`endif 