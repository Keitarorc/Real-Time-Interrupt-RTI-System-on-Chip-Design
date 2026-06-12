`timescale 1 ns / 1 ps

module spi_controller_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6
)
(
    output wire sclk,
    output wire cs_n,
    output wire mosi,
    input  wire miso,

    input  wire                              S_AXI_ACLK,
    input  wire                              S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]   S_AXI_AWADDR,
    input  wire [2 : 0]                      S_AXI_AWPROT,
    input  wire                              S_AXI_AWVALID,
    output wire                              S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1 : 0]   S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                              S_AXI_WVALID,
    output wire                              S_AXI_WREADY,
    output wire [1 : 0]                      S_AXI_BRESP,
    output wire                              S_AXI_BVALID,
    input  wire                              S_AXI_BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]   S_AXI_ARADDR,
    input  wire [2 : 0]                      S_AXI_ARPROT,
    input  wire                              S_AXI_ARVALID,
    output wire                              S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0]   S_AXI_RDATA,
    output wire [1 : 0]                      S_AXI_RRESP,
    output wire                              S_AXI_RVALID,
    input  wire                              S_AXI_RREADY
);

    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    reg                            axi_awready;
    reg                            axi_wready;
    reg [1 : 0]                    axi_bresp;
    reg                            axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    reg                            axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    reg [1 : 0]                    axi_rresp;
    reg                            axi_rvalid;

    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 3;

    // Slave registers
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg4;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg5;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg6;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg7;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg8;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg9;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg10;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg11;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg12;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg13;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg14;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg15;

    wire                          slv_reg_rden;
    wire                          slv_reg_wren;
    reg  [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer                       byte_index;
    reg                           aw_en;

    // User logic signals
    reg         spi_en;
    reg [7:0]   clk_div;
    reg         start;
    reg [15:0]  tx_data;
    wire        busy;
    wire        done;
    reg         done_latched;
    wire [15:0] rx_data_wire;
    reg  [15:0] rx_data_latched;
    reg         sw_rst;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // AXI write address ready
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            axi_awready <= 1'b0;
            aw_en       <= 1'b1;
        end
        else
        begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            begin
                axi_awready <= 1'b1;
                aw_en       <= 1'b0;
            end
            else if (S_AXI_BREADY && axi_bvalid)
            begin
                aw_en       <= 1'b1;
                axi_awready <= 1'b0;
            end
            else
            begin
                axi_awready <= 1'b0;
            end
        end
    end

    // AXI write address latch
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            axi_awaddr <= 0;
        end
        else
        begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            begin
                axi_awaddr <= S_AXI_AWADDR;
            end
        end
    end

    // AXI write data ready
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            axi_wready <= 1'b0;
        end
        else
        begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en)
            begin
                axi_wready <= 1'b1;
            end
            else
            begin
                axi_wready <= 1'b0;
            end
        end
    end

    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    // Main register/control block
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0 || sw_rst == 1'b1)
        begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
            slv_reg4 <= 0;
            slv_reg5 <= 0;
            slv_reg6 <= 0;
            slv_reg7 <= 0;
            slv_reg8 <= 0;
            slv_reg9 <= 0;
            slv_reg10 <= 0;
            slv_reg11 <= 0;
            slv_reg12 <= 0;
            slv_reg13 <= 0;
            slv_reg14 <= 0;
            slv_reg15 <= 0;

            spi_en          <= 1'b0;
            clk_div         <= 8'h00;
            start           <= 1'b0;
            tx_data         <= 16'h0000;
            done_latched    <= 1'b0;
            rx_data_latched <= 16'h0000;
            sw_rst          <= 1'b0;
        end
        else
        begin
            // default pulse outputs
            start  <= 1'b0;
            sw_rst <= 1'b0;

            // latch done and received data
            if (done)
            begin
                done_latched    <= 1'b1;
                rx_data_latched <= rx_data_wire;
            end

            if (slv_reg_wren)
            begin
                case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])

                    // 0x00 FPGA revision register (RO)
                    4'h0:
                    begin
                        slv_reg0 <= slv_reg0;
                    end

                    // 0x04 software reset register
                    4'h1:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                        begin
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end

                        if (S_AXI_WSTRB[0] && S_AXI_WDATA[0])
                            sw_rst <= 1'b1;
                    end

                    // 0x08 SPI control register
                    4'h2:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                        begin
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end

                        if (S_AXI_WSTRB[0])
                        begin
                            spi_en <= S_AXI_WDATA[1];
                        end

                        if (S_AXI_WSTRB[0] && S_AXI_WDATA[0])
                        begin
                            start        <= 1'b1;
                            done_latched <= 1'b0;
                        end
                    end

                    // 0x0C status register (RO)
                    4'h3:
                    begin
                        slv_reg3 <= slv_reg3;
                    end

                    // 0x10 TX register
                    4'h4:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                        begin
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end
                        tx_data <= S_AXI_WDATA[15:0];
                    end

                    // 0x14 RX register (RO)
                    4'h5:
                    begin
                        slv_reg5 <= slv_reg5;
                    end

                    // 0x18 clock divider register
                    4'h6:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                        begin
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end
                        clk_div <= S_AXI_WDATA[7:0];
                    end

                    4'h7:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end

                    4'h8:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg8[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end

                    4'h9:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg9[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end

                    4'hA:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg10[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end

                    4'hB:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg11[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end

                    4'hC:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg12[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end

                    4'hD:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg13[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end

                    4'hE:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg14[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end

                    4'hF:
                    begin
                        for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1)
                            if (S_AXI_WSTRB[byte_index] == 1)
                                slv_reg15[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end

                    default:
                    begin
                        slv_reg0  <= slv_reg0;
                        slv_reg1  <= slv_reg1;
                        slv_reg2  <= slv_reg2;
                        slv_reg3  <= slv_reg3;
                        slv_reg4  <= slv_reg4;
                        slv_reg5  <= slv_reg5;
                        slv_reg6  <= slv_reg6;
                        slv_reg7  <= slv_reg7;
                        slv_reg8  <= slv_reg8;
                        slv_reg9  <= slv_reg9;
                        slv_reg10 <= slv_reg10;
                        slv_reg11 <= slv_reg11;
                        slv_reg12 <= slv_reg12;
                        slv_reg13 <= slv_reg13;
                        slv_reg14 <= slv_reg14;
                        slv_reg15 <= slv_reg15;
                    end
                endcase
            end
        end
    end

    // AXI write response
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            axi_bvalid <= 0;
            axi_bresp  <= 2'b0;
        end
        else
        begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
            begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0;
            end
            else if (S_AXI_BREADY && axi_bvalid)
            begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // AXI read address ready
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            axi_arready <= 1'b0;
            axi_araddr  <= 0;
        end
        else
        begin
            if (~axi_arready && S_AXI_ARVALID)
            begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end
            else
            begin
                axi_arready <= 1'b0;
            end
        end
    end

    // AXI read valid
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end
        else
        begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
            begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;
            end
            else if (axi_rvalid && S_AXI_RREADY)
            begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    // Read mux
    always @(*)
    begin
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            4'h0   : reg_data_out <= 32'h5600_0006;
            4'h1   : reg_data_out <= {31'h0000_0000, sw_rst};
            4'h2   : reg_data_out <= {30'h0000_0000, spi_en, start};
            4'h3   : reg_data_out <= {30'h0000_0000, done_latched, busy};
            4'h4   : reg_data_out <= {16'h0000, tx_data};
            4'h5   : reg_data_out <= {16'h0000, rx_data_latched};
            4'h6   : reg_data_out <= {24'h00_0000, clk_div};
            4'h7   : reg_data_out <= slv_reg7;
            4'h8   : reg_data_out <= slv_reg8;
            4'h9   : reg_data_out <= slv_reg9;
            4'hA   : reg_data_out <= slv_reg10;
            4'hB   : reg_data_out <= slv_reg11;
            4'hC   : reg_data_out <= slv_reg12;
            4'hD   : reg_data_out <= slv_reg13;
            4'hE   : reg_data_out <= slv_reg14;
            4'hF   : reg_data_out <= slv_reg15;
            default: reg_data_out <= 0;
        endcase
    end

    // Read data register
    always @(posedge S_AXI_ACLK)
    begin
        if (S_AXI_ARESETN == 1'b0)
        begin
            axi_rdata <= 0;
        end
        else
        begin
            if (slv_reg_rden)
            begin
                axi_rdata <= reg_data_out;
            end
        end
    end

    // SPI master only
    spi_master spi_master_inst_ (
        .sys_clk  (S_AXI_ACLK),
        .sys_rst_n(S_AXI_ARESETN),
        .spi_en   (spi_en),
        .clk_div  (clk_div),
        .start    (start),
        .tx_data  (tx_data),

        .miso     (miso),
        .cs_n     (cs_n),
        .sclk     (sclk),
        .mosi     (mosi),

        .rx_data  (rx_data_wire),
        .busy     (busy),
        .done     (done)
    );

endmodule