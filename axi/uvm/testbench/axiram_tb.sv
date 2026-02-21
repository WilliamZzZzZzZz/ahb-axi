module axiram_tb;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import axiram_pkg::*;       //is still not created,

    logic clk;
    logic rst;

    initial begin 
        clk = 0;
        forever #2ns clk = !clk;
    end

    axi_if #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(16),
        .ID_WIDTH(18),
        .STRB_WIDTH(4)
    ) axi_if_inst(
        .aclk(clk),
        .arst(rst)
    );

    axi_ram #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(16),
        .STRB_WIDTH(4),
        .ID_WIDTH(8),
        .PIPELINE_OUTPUT(0)
        ) dut(
        .clk(axi_if.aclk),
        .rst(axi_if.arst),
        //AW channel
        .s_axi_awid(axi_if.awid),
        .s_axi_awaddr(axi_if.awaddr),
        .s_axi_awlen(axi_if.awlen),
        .s_axi_awsize(axi_if.awsize),
        .s_axi_awburst(axi_if.awburst),
        .s_axi_awlock(axi_if.awlock),
        .s_axi_awcache(axi_if.awcache),
        .s_axi_awprot(axi_if.awprot),
        .s_axi_awvalid(axi_if.awvalid),
        .s_axi_awready(axi_if.awready),
        //W channel
        .s_axi_wdata(axi_if.wdata),
        .s_axi_wstrb(axi_if.wstrb),
        .s_axi_wlast(axi_if.wlast),
        .s_axi_wvalid(axi_if.wvalid),
        .s_axi_wready(axi_if.wready),
        //B channel
        .s_axi_bid(axi_if.bid),
        .s_axi_bresp(axi_if.bresp),
        .s_axi_bvalid(axi_if.bvalid),
        .s_axi_bready(axi_if.bready),
        //AR channel
        .s_axi_arid(axi_if.arid),
        .s_axi_araddr(axi_if.araddr),
        .s_axi_arlen(axi_if.arlen),
        .s_axi_arsize(axi_if.arsize),
        .s_axi_arburst(axi_if.arburst),
        .s_axi_arlock(axi_if.arlock),
        .s_axi_arcache(axi_if.arcache),
        .s_axi_arprot(axi_if.arprot),
        .s_axi_arvalid(axi_if.arvalid),
        .s_axi_arready(axi_if.arready),
        //R channel
        .s_axi_rid(axi_if.rid),
        .s_axi_rdata(axi_if.rdata),
        .s_axi_rresp(axi_if.rresp),
        .s_axi_rlast(axi_if.rlast),
        .s_axi_rvalid(axi_if.rvalid),
        .s_axi_rready(axi_if.rready)
    );

    initial begin
        run_test();
    end
endmodule