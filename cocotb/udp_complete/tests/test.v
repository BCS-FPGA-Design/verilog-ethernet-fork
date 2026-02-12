
module udp_complete_tb;

  // Parameters
  localparam  ARP_CACHE_ADDR_WIDTH = 0;
  localparam  ARP_REQUEST_RETRY_COUNT = 0;
  localparam  ARP_REQUEST_RETRY_INTERVAL = 0;
  localparam  ARP_REQUEST_TIMEOUT = 0;
  localparam  UDP_CHECKSUM_GEN_ENABLE = 0;
  localparam  UDP_CHECKSUM_PAYLOAD_FIFO_DEPTH = 0;
  localparam  UDP_CHECKSUM_HEADER_FIFO_DEPTH = 0;

  //Ports
  reg  clk;
  reg  rst;
  reg  s_eth_hdr_valid;
  wire  s_eth_hdr_ready;
  reg [47:0] s_eth_dest_mac;
  reg [47:0] s_eth_src_mac;
  reg [15:0] s_eth_type;
  reg [7:0] s_eth_payload_axis_tdata;
  reg  s_eth_payload_axis_tvalid;
  wire  s_eth_payload_axis_tready;
  reg  s_eth_payload_axis_tlast;
  reg  s_eth_payload_axis_tuser;
  wire  m_eth_hdr_valid;
  reg  m_eth_hdr_ready;
  wire [47:0] m_eth_dest_mac;
  wire [47:0] m_eth_src_mac;
  wire [15:0] m_eth_type;
  wire [7:0] m_eth_payload_axis_tdata;
  wire  m_eth_payload_axis_tvalid;
  reg  m_eth_payload_axis_tready;
  wire  m_eth_payload_axis_tlast;
  wire  m_eth_payload_axis_tuser;
  reg  s_ip_hdr_valid;
  wire  s_ip_hdr_ready;
  reg [5:0] s_ip_dscp;
  reg [1:0] s_ip_ecn;
  reg [15:0] s_ip_length;
  reg [7:0] s_ip_ttl;
  reg [7:0] s_ip_protocol;
  reg [31:0] s_ip_source_ip;
  reg [31:0] s_ip_dest_ip;
  reg [7:0] s_ip_payload_axis_tdata;
  reg  s_ip_payload_axis_tvalid;
  wire  s_ip_payload_axis_tready;
  reg  s_ip_payload_axis_tlast;
  reg  s_ip_payload_axis_tuser;
  wire  m_ip_hdr_valid;
  reg  m_ip_hdr_ready;
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
  reg  s_udp_hdr_valid;
  wire  s_udp_hdr_ready;
  reg [5:0] s_udp_ip_dscp;
  reg [1:0] s_udp_ip_ecn;
  reg [7:0] s_udp_ip_ttl;
  reg [31:0] s_udp_ip_source_ip;
  reg [31:0] s_udp_ip_dest_ip;
  reg [15:0] s_udp_source_port;
  reg [15:0] s_udp_dest_port;
  reg [15:0] s_udp_length;
  reg [15:0] s_udp_checksum;
  reg [7:0] s_udp_payload_axis_tdata;
  reg  s_udp_payload_axis_tvalid;
  wire  s_udp_payload_axis_tready;
  reg  s_udp_payload_axis_tlast;
  reg  s_udp_payload_axis_tuser;
  wire  m_udp_hdr_valid;
  reg  m_udp_hdr_ready;
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
  wire [7:0] m_udp_payload_axis_tdata;
  wire  m_udp_payload_axis_tvalid;
  reg  m_udp_payload_axis_tready;
  wire  m_udp_payload_axis_tlast;
  wire  m_udp_payload_axis_tuser;
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
  reg [47:0] local_mac;
  reg [31:0] local_ip;
  reg [31:0] gateway_ip;
  reg [31:0] subnet_mask;
  reg  clear_arp_cache;

  udp_complete # (
    .ARP_CACHE_ADDR_WIDTH(ARP_CACHE_ADDR_WIDTH),
    .ARP_REQUEST_RETRY_COUNT(ARP_REQUEST_RETRY_COUNT),
    .ARP_REQUEST_RETRY_INTERVAL(ARP_REQUEST_RETRY_INTERVAL),
    .ARP_REQUEST_TIMEOUT(ARP_REQUEST_TIMEOUT),
    .UDP_CHECKSUM_GEN_ENABLE(UDP_CHECKSUM_GEN_ENABLE),
    .UDP_CHECKSUM_PAYLOAD_FIFO_DEPTH(UDP_CHECKSUM_PAYLOAD_FIFO_DEPTH),
    .UDP_CHECKSUM_HEADER_FIFO_DEPTH(UDP_CHECKSUM_HEADER_FIFO_DEPTH)
  )
  udp_complete_inst (
    .clk(clk),
    .rst(rst),
    .s_eth_hdr_valid(s_eth_hdr_valid),
    .s_eth_hdr_ready(s_eth_hdr_ready),
    .s_eth_dest_mac(s_eth_dest_mac),
    .s_eth_src_mac(s_eth_src_mac),
    .s_eth_type(s_eth_type),
    .s_eth_payload_axis_tdata(s_eth_payload_axis_tdata),
    .s_eth_payload_axis_tvalid(s_eth_payload_axis_tvalid),
    .s_eth_payload_axis_tready(s_eth_payload_axis_tready),
    .s_eth_payload_axis_tlast(s_eth_payload_axis_tlast),
    .s_eth_payload_axis_tuser(s_eth_payload_axis_tuser),
    .m_eth_hdr_valid(m_eth_hdr_valid),
    .m_eth_hdr_ready(m_eth_hdr_ready),
    .m_eth_dest_mac(m_eth_dest_mac),
    .m_eth_src_mac(m_eth_src_mac),
    .m_eth_type(m_eth_type),
    .m_eth_payload_axis_tdata(m_eth_payload_axis_tdata),
    .m_eth_payload_axis_tvalid(m_eth_payload_axis_tvalid),
    .m_eth_payload_axis_tready(m_eth_payload_axis_tready),
    .m_eth_payload_axis_tlast(m_eth_payload_axis_tlast),
    .m_eth_payload_axis_tuser(m_eth_payload_axis_tuser),
    .s_ip_hdr_valid(s_ip_hdr_valid),
    .s_ip_hdr_ready(s_ip_hdr_ready),
    .s_ip_dscp(s_ip_dscp),
    .s_ip_ecn(s_ip_ecn),
    .s_ip_length(s_ip_length),
    .s_ip_ttl(s_ip_ttl),
    .s_ip_protocol(s_ip_protocol),
    .s_ip_source_ip(s_ip_source_ip),
    .s_ip_dest_ip(s_ip_dest_ip),
    .s_ip_payload_axis_tdata(s_ip_payload_axis_tdata),
    .s_ip_payload_axis_tvalid(s_ip_payload_axis_tvalid),
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
    .m_ip_payload_axis_tready(m_ip_payload_axis_tready),
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
    .s_udp_payload_axis_tdata(s_udp_payload_axis_tdata),
    .s_udp_payload_axis_tvalid(s_udp_payload_axis_tvalid),
    .s_udp_payload_axis_tready(s_udp_payload_axis_tready),
    .s_udp_payload_axis_tlast(s_udp_payload_axis_tlast),
    .s_udp_payload_axis_tuser(s_udp_payload_axis_tuser),
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
    .m_udp_payload_axis_tdata(m_udp_payload_axis_tdata),
    .m_udp_payload_axis_tvalid(m_udp_payload_axis_tvalid),
    .m_udp_payload_axis_tready(m_udp_payload_axis_tready),
    .m_udp_payload_axis_tlast(m_udp_payload_axis_tlast),
    .m_udp_payload_axis_tuser(m_udp_payload_axis_tuser),
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

//always #5  clk = ! clk ;

endmodule