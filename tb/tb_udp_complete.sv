//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps
`define SIMULATION




module tb_udp_complete();

//--------------------------------------------------------------------
// Parameters
//--------------------------------------------------------------------

localparam CLK_FREQ_125 = 125_000_000; // 125 MHz
localparam CLK_FREQ_125_MHZ = 125; // 125 MHz
localparam real CLK_PERIOD_125_NS = 1000/CLK_FREQ_125_MHZ; // ns

localparam UDP_PAYLOAD_BYTES = 223;
localparam IP_LENGTH = 20 + 8 + UDP_PAYLOAD_BYTES; // IP header (20) + UDP header (8) + payload
//--------------------------------------------------------------------
// Clocks
//--------------------------------------------------------------------
logic clk_125;

//--------------------------------------------------------------------
// Resets
//--------------------------------------------------------------------
logic reset, resetn;

//--------------------------------------------------------------------
// Signals
//--------------------------------------------------------------------
axis_if #(.TDATA_WIDTH(8), .TUSER_WIDTH(1)) s_axis_ethernet_payload ();

axis_if #(.TDATA_WIDTH(8), .TUSER_WIDTH(1)) s_axis_udp_payload ();
axis_if #(.TDATA_WIDTH(8), .TUSER_WIDTH(1)) m_axis_udp_payload ();

axis_if #(.TDATA_WIDTH(8), .TUSER_WIDTH(1)) s_axis_ip_hdr ();
axis_if #(.TDATA_WIDTH(8), .TUSER_WIDTH(1)) m_axis_ip_hdr ();
axis_if #(.TDATA_WIDTH(8), .TUSER_WIDTH(1)) m_axis_if ();

logic stimulus_enable;

  // Parameters
  localparam  ARP_CACHE_ADDR_WIDTH = 2;
  localparam  ARP_REQUEST_RETRY_COUNT = 4;
  localparam  ARP_REQUEST_RETRY_INTERVAL = 150;
  localparam  ARP_REQUEST_TIMEOUT = 400;
  localparam  UDP_CHECKSUM_GEN_ENABLE = 0;
  localparam  UDP_CHECKSUM_PAYLOAD_FIFO_DEPTH = 2048;
  localparam  UDP_CHECKSUM_HEADER_FIFO_DEPTH = 8;
  localparam  SRC_IP = 32'hC0A8_0164; //
  localparam  DEST_IP = 32'hFFFF_FFFF; // Broadcast

  //Ports — Ethernet header (unused regs, loopback is in DUT port connections)
  wire  s_eth_hdr_ready;

  // Ethernet loopback wires (m_eth output → s_eth input)
  wire        m_eth_hdr_valid;
  wire [47:0] m_eth_dest_mac;
  wire [47:0] m_eth_src_mac;
  wire [15:0] m_eth_type;
  wire [7:0]  m_eth_payload_axis_tdata;
  wire        m_eth_payload_axis_tvalid;
  wire        s_eth_payload_axis_tready;
  wire        m_eth_payload_axis_tlast;
  wire        m_eth_payload_axis_tuser;
  reg  s_ip_hdr_valid = 1'b1;
  wire  s_ip_hdr_ready;
  reg [5:0] s_ip_dscp = '0;
  reg [1:0] s_ip_ecn = '0;
  reg [15:0] s_ip_length = IP_LENGTH;
  reg [7:0] s_ip_ttl = 64;
  reg [7:0] s_ip_protocol = 8'h11; // UDP
  reg [31:0] s_ip_source_ip = SRC_IP;
  reg [31:0] s_ip_dest_ip = DEST_IP; // loopback: same as local_ip (192.168.1.100)
  reg [7:0] s_ip_payload_axis_tdata;
  reg  s_ip_payload_axis_tvalid;
  wire  s_ip_payload_axis_tready;
  reg  s_ip_payload_axis_tlast;
  reg  s_ip_payload_axis_tuser;
  wire  m_ip_hdr_valid;
  reg  m_ip_hdr_ready = 1'b1;
  wire [47:0] m_ip_eth_dest_mac;
  wire [47:0] m_ip_eth_src_mac;
  wire [15:0] m_ip_eth_type;
  wire [3:0] m_ip_version;
  wire [3:0] m_ip_ihl;
  wire [5:0] m_ip_dscp;
  wire [1:0] m_ip_ecn;
  wire [15:0] m_ip_length;
  wire [15:0] m_ip_identification;
  wire [2:0] m_ip_flags;
  wire [12:0] m_ip_fragment_offset;
  wire [7:0] m_ip_ttl;
  wire [7:0] m_ip_protocol;
  wire [15:0] m_ip_header_checksum;
  wire [31:0] m_ip_source_ip;
  wire [31:0] m_ip_dest_ip;
  wire [7:0] m_ip_payload_axis_tdata;
  wire  m_ip_payload_axis_tvalid;
  reg  m_ip_payload_axis_tready;
  wire  m_ip_payload_axis_tlast;
  wire  m_ip_payload_axis_tuser;
  reg  s_udp_hdr_valid = 1'b1;
  wire  s_udp_hdr_ready;
  reg [5:0] s_udp_ip_dscp = '0;
  reg [1:0] s_udp_ip_ecn = '0;
  reg [7:0] s_udp_ip_ttl = 64;
  reg [31:0] s_udp_ip_source_ip = SRC_IP;
  reg [31:0] s_udp_ip_dest_ip = DEST_IP; // loopback: send to self (192.168.1.100)
  reg [15:0] s_udp_source_port = 501;
  reg [15:0] s_udp_dest_port = 501;
  reg [15:0] s_udp_length = UDP_PAYLOAD_BYTES + 8; // UDP header (8) + payload
  reg [15:0] s_udp_checksum = '0;
//   reg [7:0] s_udp_payload_axis_tdata;
//   reg  s_udp_payload_axis_tvalid;
//   wire  s_udp_payload_axis_tready;
//   reg  s_udp_payload_axis_tlast;
//   reg  s_udp_payload_axis_tuser;
  wire  m_udp_hdr_valid;
  reg  m_udp_hdr_ready = 1'b1;
  wire [47:0] m_udp_eth_dest_mac;
  wire [47:0] m_udp_eth_src_mac;
  wire [15:0] m_udp_eth_type;
  wire [3:0] m_udp_ip_version;
  wire [3:0] m_udp_ip_ihl;
  wire [5:0] m_udp_ip_dscp;
  wire [1:0] m_udp_ip_ecn;
  wire [15:0] m_udp_ip_length;
  wire [15:0] m_udp_ip_identification;
  wire [2:0] m_udp_ip_flags;
  wire [12:0] m_udp_ip_fragment_offset;
  wire [7:0] m_udp_ip_ttl;
  wire [7:0] m_udp_ip_protocol;
  wire [15:0] m_udp_ip_header_checksum;
  wire [31:0] m_udp_ip_source_ip;
  wire [31:0] m_udp_ip_dest_ip;
  wire [15:0] m_udp_source_port;
  wire [15:0] m_udp_dest_port;
  wire [15:0] m_udp_length;
  wire [15:0] m_udp_checksum;
//   wire [7:0] m_udp_payload_axis_tdata;
//   wire  m_udp_payload_axis_tvalid;
//   reg  m_udp_payload_axis_tready;
//   wire  m_udp_payload_axis_tlast;
//   wire  m_udp_payload_axis_tuser;
  wire  ip_rx_busy;
  wire  ip_tx_busy;
  wire  udp_rx_busy;
  wire  udp_tx_busy;
  wire  ip_rx_error_header_early_termination;
  wire  ip_rx_error_payload_early_termination;
  wire  ip_rx_error_invalid_header;
  wire  ip_rx_error_invalid_checksum;
  wire  ip_tx_error_payload_early_termination;
  wire  ip_tx_error_arp_failed;
  wire  udp_rx_error_header_early_termination;
  wire  udp_rx_error_payload_early_termination;
  wire  udp_tx_error_payload_early_termination;
  reg [47:0] local_mac = 48'hAABBCCDDEEFF;
  reg [31:0] local_ip = SRC_IP;
  reg [31:0] gateway_ip = 32'hC0A8_0101;   // 192.168.1.1
  reg [31:0] subnet_mask = 32'hFFFF_FF00;  // 255.255.255.0 (/24)
  reg  clear_arp_cache = '0;
//--------------------------------------------------------------------
// Initialization
//--------------------------------------------------------------------


//`CREATE_CLK(clk,  65104.16667); // 15.36 MHz
always begin
 clk_125 = 1'b1;
 #(CLK_PERIOD_125_NS/2) clk_125 = 1'b0;
 #(CLK_PERIOD_125_NS/2);
end




initial begin
    reset = 1'b1;
    #(CLK_PERIOD_125_NS * 50);
    @(posedge clk_125);
    reset = 1'b0;
end

assign resetn = ~reset;





//--------------------------------------------------------------------
// Stimulus
//--------------------------------------------------------------------

typedef enum {
    SEND_HDR,
    SEND_PAYLOAD
} udp_state_t;

udp_state_t udp_state;

always_ff @(posedge clk_125) begin
    if (reset) begin
        s_axis_udp_payload.tvalid               <= 1'b0;
        s_axis_udp_payload.tdata                <= UDP_PAYLOAD_BYTES - 1; // Start at max value to test rollover
        s_axis_udp_payload.tlast                <= 1'b0;
        s_axis_udp_payload.tuser                <= '0;
        udp_state                               <= SEND_HDR;
        s_udp_hdr_valid                         <= 1'b0;

    end else begin
        case (udp_state)


        SEND_HDR: begin
            s_axis_udp_payload.tvalid           <= 1'b0;
            s_udp_hdr_valid                     <= 1'b1;

            if (s_udp_hdr_ready) begin
                s_udp_hdr_valid                 <= 1'b0;
                udp_state                       <= SEND_PAYLOAD;
            end
            
        end

        SEND_PAYLOAD: begin
            s_axis_udp_payload.tvalid           <= stimulus_enable; // Keep valid high to continuously send data

            if (s_axis_udp_payload.tready || !s_axis_udp_payload.tvalid) begin
                s_axis_udp_payload.tdata        <= s_axis_udp_payload.tdata == UDP_PAYLOAD_BYTES - 1 ? '0 : s_axis_udp_payload.tdata + 1; // Increment data for each beat
                s_axis_udp_payload.tlast        <= s_axis_udp_payload.tdata == UDP_PAYLOAD_BYTES - 2; 
                s_axis_udp_payload.tuser        <= s_axis_udp_payload.tdata == UDP_PAYLOAD_BYTES - 1; // Assert tuser on the first sample
                if (s_axis_udp_payload.tdata == UDP_PAYLOAD_BYTES - 2) begin
                    // Completed one full UDP payload, can add logic here if needed
                    udp_state                   <= SEND_HDR; // Go back to SEND_HDR state (if needed)
                end
            end
        end
        endcase
    end
end


always_ff @(posedge clk_125) begin
    if (reset) begin
        s_axis_ip_hdr.tvalid <= 1'b0;
        s_axis_ip_hdr.tdata <= '0;
        s_axis_ip_hdr.tlast <= 1'b0;
        s_axis_ip_hdr.tuser <= '0;
    end else begin
        // For this testbench, we won't send any IP header data on s_axis_ip_hdr.
        // The UDP header will be sent directly to the UDP module, bypassing the IP header interface.
        s_axis_ip_hdr.tvalid <= 1'b0; 
        s_axis_ip_hdr.tdata <= '0;
        s_axis_ip_hdr.tlast <= 1'b0;
        s_axis_ip_hdr.tuser <= '0;
    end
end



//--------------------------------------------------------------------
// DUT 
//--------------------------------------------------------------------


  udp_complete udp_complete_inst (
    .clk(clk_125),
    .rst(reset),
    // --- Ethernet loopback: m_eth_* output wired back to s_eth_* input ---
    .s_eth_hdr_valid(m_eth_hdr_valid),
    .s_eth_hdr_ready(s_eth_hdr_ready),
    .s_eth_dest_mac(m_eth_dest_mac),
    .s_eth_src_mac(m_eth_src_mac),
    .s_eth_type(m_eth_type),
    .s_eth_payload_axis_tdata(m_eth_payload_axis_tdata),
    .s_eth_payload_axis_tvalid(m_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(s_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(m_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(m_eth_payload_axis_tuser),
    .m_eth_hdr_valid(m_eth_hdr_valid),
    .m_eth_hdr_ready(s_eth_hdr_ready),
    .m_eth_dest_mac(m_eth_dest_mac),
    .m_eth_src_mac(m_eth_src_mac),
    .m_eth_type(m_eth_type),
    .m_eth_payload_axis_tdata(m_eth_payload_axis_tdata),
    .m_eth_payload_axis_tvalid(m_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(s_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(m_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(m_eth_payload_axis_tuser),
    .s_ip_hdr_valid(1'b0),
    .s_ip_hdr_ready(s_ip_hdr_ready),
    .s_ip_dscp(s_ip_dscp),
    .s_ip_ecn(s_ip_ecn),
    .s_ip_length(s_ip_length),
    .s_ip_ttl(s_ip_ttl),
    .s_ip_protocol(s_ip_protocol),
    .s_ip_source_ip(s_ip_source_ip),
    .s_ip_dest_ip(s_ip_dest_ip),
    .s_ip_payload_axis_tdata(s_ip_payload_axis_tdata),
    .s_ip_payload_axis_tvalid(1'b0),
    .s_ip_payload_axis_tready(s_ip_payload_axis_tready),
    .s_ip_payload_axis_tlast(s_ip_payload_axis_tlast),
    .s_ip_payload_axis_tuser(s_ip_payload_axis_tuser),
    .m_ip_hdr_valid(m_ip_hdr_valid),
    .m_ip_hdr_ready(m_ip_hdr_ready),
    .m_ip_eth_dest_mac(m_ip_eth_dest_mac),
    .m_ip_eth_src_mac(m_ip_eth_src_mac),
    .m_ip_eth_type(m_ip_eth_type),
    .m_ip_version(m_ip_version),
    .m_ip_ihl(m_ip_ihl),
    .m_ip_dscp(m_ip_dscp),
    .m_ip_ecn(m_ip_ecn),
    .m_ip_length(m_ip_length),
    .m_ip_identification(m_ip_identification),
    .m_ip_flags(m_ip_flags),
    .m_ip_fragment_offset(m_ip_fragment_offset),
    .m_ip_ttl(m_ip_ttl),
    .m_ip_protocol(m_ip_protocol),
    .m_ip_header_checksum(m_ip_header_checksum),
    .m_ip_source_ip(m_ip_source_ip),
    .m_ip_dest_ip(m_ip_dest_ip),
    .m_ip_payload_axis_tdata(m_ip_payload_axis_tdata),
    .m_ip_payload_axis_tvalid(m_ip_payload_axis_tvalid),
    .m_ip_payload_axis_tready(1'b1),
    .m_ip_payload_axis_tlast(m_ip_payload_axis_tlast),
    .m_ip_payload_axis_tuser(m_ip_payload_axis_tuser),
    .s_udp_hdr_valid(s_udp_hdr_valid),
    .s_udp_hdr_ready(s_udp_hdr_ready),
    .s_udp_ip_dscp(s_udp_ip_dscp),
    .s_udp_ip_ecn(s_udp_ip_ecn),
    .s_udp_ip_ttl(s_udp_ip_ttl),
    .s_udp_ip_source_ip(s_udp_ip_source_ip),
    .s_udp_ip_dest_ip(s_udp_ip_dest_ip),
    .s_udp_source_port(s_udp_source_port),
    .s_udp_dest_port(s_udp_dest_port),
    .s_udp_length(s_udp_length),
    .s_udp_checksum(s_udp_checksum),
    .s_udp_payload_axis_tdata(s_axis_udp_payload.tdata),
    .s_udp_payload_axis_tvalid(s_axis_udp_payload.tvalid),
    .s_udp_payload_axis_tready(s_axis_udp_payload.tready),
    .s_udp_payload_axis_tlast(s_axis_udp_payload.tlast),
    .s_udp_payload_axis_tuser(s_axis_udp_payload.tuser),
    .m_udp_hdr_valid(m_udp_hdr_valid),
    .m_udp_hdr_ready(m_udp_hdr_ready),
    .m_udp_eth_dest_mac(m_udp_eth_dest_mac),
    .m_udp_eth_src_mac(m_udp_eth_src_mac),
    .m_udp_eth_type(m_udp_eth_type),
    .m_udp_ip_version(m_udp_ip_version),
    .m_udp_ip_ihl(m_udp_ip_ihl),
    .m_udp_ip_dscp(m_udp_ip_dscp),
    .m_udp_ip_ecn(m_udp_ip_ecn),
    .m_udp_ip_length(m_udp_ip_length),
    .m_udp_ip_identification(m_udp_ip_identification),
    .m_udp_ip_flags(m_udp_ip_flags),
    .m_udp_ip_fragment_offset(m_udp_ip_fragment_offset),
    .m_udp_ip_ttl(m_udp_ip_ttl),
    .m_udp_ip_protocol(m_udp_ip_protocol),
    .m_udp_ip_header_checksum(m_udp_ip_header_checksum),
    .m_udp_ip_source_ip(m_udp_ip_source_ip),
    .m_udp_ip_dest_ip(m_udp_ip_dest_ip),
    .m_udp_source_port(m_udp_source_port),
    .m_udp_dest_port(m_udp_dest_port),
    .m_udp_length(m_udp_length),
    .m_udp_checksum(m_udp_checksum),
    .m_udp_payload_axis_tdata(m_axis_udp_payload.tdata),
    .m_udp_payload_axis_tvalid(m_axis_udp_payload.tvalid),
    .m_udp_payload_axis_tready(m_axis_udp_payload.tready),
    .m_udp_payload_axis_tlast(m_axis_udp_payload.tlast),
    .m_udp_payload_axis_tuser(m_axis_udp_payload.tuser),
    .ip_rx_busy(ip_rx_busy),
    .ip_tx_busy(ip_tx_busy),
    .udp_rx_busy(udp_rx_busy),
    .udp_tx_busy(udp_tx_busy),
    .ip_rx_error_header_early_termination(ip_rx_error_header_early_termination),
    .ip_rx_error_payload_early_termination(ip_rx_error_payload_early_termination),
    .ip_rx_error_invalid_header(ip_rx_error_invalid_header),
    .ip_rx_error_invalid_checksum(ip_rx_error_invalid_checksum),
    .ip_tx_error_payload_early_termination(ip_tx_error_payload_early_termination),
    .ip_tx_error_arp_failed(ip_tx_error_arp_failed),
    .udp_rx_error_header_early_termination(udp_rx_error_header_early_termination),
    .udp_rx_error_payload_early_termination(udp_rx_error_payload_early_termination),
    .udp_tx_error_payload_early_termination(udp_tx_error_payload_early_termination),
    .local_mac(local_mac),
    .local_ip(local_ip),
    .gateway_ip(gateway_ip),
    .subnet_mask(subnet_mask),
    .clear_arp_cache(clear_arp_cache)
);



initial begin
    m_axis_udp_payload.tready = 1'b1;
    stimulus_enable = 1'b1;

end


    
endmodule
