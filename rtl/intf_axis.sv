`ifndef AXIS_IF_
`define AXIS_IF_

interface axis_if
#(
    parameter int TDATA_WIDTH = 16,
    parameter int TID_WIDTH = 8,
    parameter int TUSER_WIDTH = 8

)();


localparam int TKEEP_WIDTH = (TDATA_WIDTH / 8);
// AXIS Ports

// Uncomment the following to set interface specific parameter on the bus interface.
//(* X_INTERFACE_PARAMETER = "CLK_DOMAIN <value>,PHASE <value>,FREQ_HZ <value>,LAYERED_METADATA <value>,HAS_TLAST <value>,HAS_TKEEP <value>,HAS_TSTRB <value>,HAS_TREADY <value>,TUSER_WIDTH <value>,TID_WIDTH <value>,TDEST_WIDTH <value>,TDATA_NUM_BYTES <value>" *)
    
(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0  TVALID" *)
logic tvalid; // Transfer valid (required)

(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0  TID" *)
logic [TID_WIDTH-1:0] tid; // Transfer ID tag (optional)

(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0  TDATA" *)
logic [TDATA_WIDTH-1:0] tdata; // Transfer Data (optional)

(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0  TLAST" *)
logic tlast; // Packet Boundary Indicator (optional)

(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0  TUSER" *)
logic [TUSER_WIDTH-1:0] tuser; // Transfer user sideband (optional)

(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0  TKEEP" *)
logic [TKEEP_WIDTH-1:0] tkeep; // Transfer Null Byte Indicators (optional)

(* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0  TREADY" *)
logic tready; // Transfer ready (optional)


modport MASTER  (output tvalid, tid, tdata, tlast, tuser, tkeep, input tready);
modport SLAVE   (input  tvalid, tid, tdata, tlast, tuser, tkeep, output tready);

endinterface


/* instantiation template

    axis_if  #(.PARAMETER_NAME(PARAMETER_VALUE)) axis_if_inst_name();

*/

`endif // AXIS_IF_

