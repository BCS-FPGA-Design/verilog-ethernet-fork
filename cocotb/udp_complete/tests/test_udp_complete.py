"""
Test UDP RX path: inject raw Ethernet frames containing IP/UDP on s_eth_*,
verify parsed UDP datagrams appear on m_udp_*.
No loopback or ARP needed — we only exercise the receive stack.
"""
import struct

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

CLK_FREQ_MHZ = 125
CLK_PERIOD_NS = 1000/CLK_FREQ_MHZ
SIMULATION_US = 100
SIMULATION_CLKS = int(SIMULATION_US * 1000 / CLK_PERIOD_NS)

# ── Network constants ────────────────────────────────────────────────────────
LOCAL_MAC   = 0x020000000001
LOCAL_IP    = 0xC0A80164          # 192.168.1.100
REMOTE_MAC  = 0x020000000002
REMOTE_IP   = 0xC0A80101          # 192.168.1.1
GATEWAY_IP  = 0xC0A80101
SUBNET_MASK = 0xFFFFFF00

# ── Helpers ──────────────────────────────────────────────────────────────────

def _ip_checksum(hdr: bytes) -> int:
    """RFC-791 ones-complement checksum over *hdr* (with checksum field = 0)."""
    if len(hdr) % 2:
        hdr += b"\x00"
    s = sum(struct.unpack(f"!{len(hdr)//2}H", hdr))
    while s >> 16:
        s = (s & 0xFFFF) + (s >> 16)
    return ~s & 0xFFFF


def build_ip_udp_bytes(src_ip, dst_ip, src_port, dst_port, payload):
    """Return the Ethernet *payload* (IP header + UDP header + data)."""
    udp_len      = 8 + len(payload)
    ip_total_len = 20 + udp_len

    # IP header with checksum placeholder = 0
    ip_hdr = struct.pack(
        "!BBHHHBBH4s4s",
        0x45, 0x00, ip_total_len,
        0x0000, 0x0000,
        64, 0x11, 0x0000,
        src_ip.to_bytes(4, "big"),
        dst_ip.to_bytes(4, "big"),
    )
    csum   = _ip_checksum(ip_hdr)
    ip_hdr = ip_hdr[:10] + struct.pack("!H", csum) + ip_hdr[12:]

    udp_hdr = struct.pack("!HHHH", src_port, dst_port, udp_len, 0x0000)
    return ip_hdr + udp_hdr + bytes(payload)


async def reset_and_configure(dut):
    """Hold reset, tie off unused inputs, load config, then release reset."""
    dut.rst.value = 1

    # Ethernet RX — idle
    dut.s_eth_hdr_valid.value            = 0
    dut.s_eth_dest_mac.value             = 0
    dut.s_eth_src_mac.value              = 0
    dut.s_eth_type.value                 = 0
    dut.s_eth_payload_axis_tdata.value   = 0
    dut.s_eth_payload_axis_tvalid.value  = 0
    dut.s_eth_payload_axis_tlast.value   = 0
    dut.s_eth_payload_axis_tuser.value   = 0

    # IP TX input — idle (we don't send raw IP in this test)
    dut.s_ip_hdr_valid.value             = 0
    dut.s_ip_dscp.value                  = 0
    dut.s_ip_ecn.value                   = 0
    dut.s_ip_length.value                = 0
    dut.s_ip_ttl.value                   = 0
    dut.s_ip_protocol.value              = 0
    dut.s_ip_source_ip.value             = 0
    dut.s_ip_dest_ip.value               = 0
    dut.s_ip_payload_axis_tdata.value    = 0
    dut.s_ip_payload_axis_tvalid.value   = 0
    dut.s_ip_payload_axis_tlast.value    = 0
    dut.s_ip_payload_axis_tuser.value    = 0

    # UDP TX input — idle (we don't send UDP in this test)
    dut.s_udp_hdr_valid.value            = 0
    dut.s_udp_ip_dscp.value              = 0
    dut.s_udp_ip_ecn.value               = 0
    dut.s_udp_ip_ttl.value               = 0
    dut.s_udp_ip_source_ip.value         = 0
    dut.s_udp_ip_dest_ip.value           = 0
    dut.s_udp_source_port.value          = 0
    dut.s_udp_dest_port.value            = 0
    dut.s_udp_length.value               = 0
    dut.s_udp_checksum.value             = 0
    dut.s_udp_payload_axis_tdata.value   = 0
    dut.s_udp_payload_axis_tvalid.value  = 0
    dut.s_udp_payload_axis_tlast.value   = 0
    dut.s_udp_payload_axis_tuser.value   = 0

    # Outputs — always accept
    dut.m_eth_hdr_ready.value            = 1
    dut.m_eth_payload_axis_tready.value  = 1
    dut.m_ip_hdr_ready.value             = 1
    dut.m_ip_payload_axis_tready.value   = 1
    dut.m_udp_hdr_ready.value            = 1
    dut.m_udp_payload_axis_tready.value  = 1

    # Configuration
    dut.local_mac.value       = LOCAL_MAC
    dut.local_ip.value        = LOCAL_IP
    dut.gateway_ip.value      = GATEWAY_IP
    dut.subnet_mask.value     = SUBNET_MASK
    dut.clear_arp_cache.value = 0

    for _ in range(5):
        await RisingEdge(dut.clk)
    dut.rst.value = 0
    for _ in range(5):
        await RisingEdge(dut.clk)


async def send_eth_frame(dut, dest_mac, src_mac, eth_type, payload_bytes):
    """Drive one Ethernet frame on s_eth_* with proper AXI-Stream handshake."""
    # Present the header
    dut.s_eth_hdr_valid.value  = 1
    dut.s_eth_dest_mac.value   = dest_mac
    dut.s_eth_src_mac.value    = src_mac
    dut.s_eth_type.value       = eth_type
    await RisingEdge(dut.clk)
    while dut.s_eth_hdr_ready.value == 0:
        await RisingEdge(dut.clk)
    dut.s_eth_hdr_valid.value = 0

    # Stream payload bytes
    for i, byte_val in enumerate(payload_bytes):
        is_last = i == len(payload_bytes) - 1
        dut.s_eth_payload_axis_tdata.value  = byte_val
        dut.s_eth_payload_axis_tvalid.value = 1
        dut.s_eth_payload_axis_tlast.value  = int(is_last)
        dut.s_eth_payload_axis_tuser.value  = 0
        await RisingEdge(dut.clk)
        while dut.s_eth_payload_axis_tready.value == 0:
            await RisingEdge(dut.clk)

    dut.s_eth_payload_axis_tvalid.value = 0
    dut.s_eth_payload_axis_tlast.value  = 0


async def wait_signal(dut, signal, max_clocks=SIMULATION_CLKS):
    """Wait up to *max_clocks* for *signal* == 1."""
    for _ in range(max_clocks):
        if signal.value == 1:
            return
        await RisingEdge(dut.clk)
    raise TimeoutError(f"{signal._path} did not assert within {max_clocks} clocks")


# ── Tests ────────────────────────────────────────────────────────────────────

@cocotb.test()
async def test_udp_rx_single_frame(dut):
    """Inject one Ethernet/IP/UDP frame → verify header and payload on m_udp_*."""
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, units="ns").start())
    await reset_and_configure(dut)

    src_port = 1234
    dst_port = 5678
    payload  = [0xDE, 0xAD, 0xBE, 0xEF]

    frame = build_ip_udp_bytes(REMOTE_IP, LOCAL_IP, src_port, dst_port, payload)
    await send_eth_frame(dut, LOCAL_MAC, REMOTE_MAC, 0x0800, frame)

    # ── Check UDP header ─────────────────────────────────────────────────
    await wait_signal(dut, dut.m_udp_hdr_valid)

    assert int(dut.m_udp_source_port.value)    == src_port
    assert int(dut.m_udp_dest_port.value)      == dst_port
    assert int(dut.m_udp_ip_source_ip.value)   == REMOTE_IP
    assert int(dut.m_udp_ip_dest_ip.value)     == LOCAL_IP
    assert int(dut.m_udp_ip_protocol.value)    == 0x11
    dut._log.info("UDP header fields OK")

    # ── Read payload bytes ───────────────────────────────────────────────
    received = []
    for _ in range(SIMULATION_CLKS):
        if dut.m_udp_payload_axis_tvalid.value == 1:
            received.append(int(dut.m_udp_payload_axis_tdata.value))
            if dut.m_udp_payload_axis_tlast.value == 1:
                break
        await RisingEdge(dut.clk)
    else:
        raise TimeoutError("Timed out reading UDP payload")

    dut._log.info(f"Payload: {[hex(b) for b in received]}")
    assert received == payload, f"Payload mismatch: got {received}, expected {payload}"


@cocotb.test()
async def test_udp_rx_longer_payload(dut):
    """Same RX test with a 16-byte payload to exercise multi-beat streaming."""
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, units="ns").start())
    await reset_and_configure(dut)

    src_port = 4000
    dst_port = 8000
    payload  = list(range(16))  # [0x00 .. 0x0F]

    frame = build_ip_udp_bytes(REMOTE_IP, LOCAL_IP, src_port, dst_port, payload)
    await send_eth_frame(dut, LOCAL_MAC, REMOTE_MAC, 0x0800, frame)

    await wait_signal(dut, dut.m_udp_hdr_valid)
    assert int(dut.m_udp_source_port.value) == src_port
    assert int(dut.m_udp_dest_port.value)   == dst_port
    dut._log.info("UDP header fields OK")

    received = []
    for _ in range(SIMULATION_CLKS):
        if dut.m_udp_payload_axis_tvalid.value == 1:
            received.append(int(dut.m_udp_payload_axis_tdata.value))
            if dut.m_udp_payload_axis_tlast.value == 1:
                break
        await RisingEdge(dut.clk)
    else:
        raise TimeoutError("Timed out reading UDP payload")

    dut._log.info(f"Payload: {[hex(b) for b in received]}")
    assert received == payload, f"Payload mismatch: got {received}, expected {payload}"