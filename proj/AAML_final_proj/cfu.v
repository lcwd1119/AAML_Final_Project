module Cfu (
    input               cmd_valid,
    output              cmd_ready,
    input      [9:0]    cmd_payload_function_id,
    input      [31:0]   cmd_payload_inputs_0,
    input      [31:0]   cmd_payload_inputs_1,
    output reg          rsp_valid,
    input               rsp_ready,
    output reg [31:0]   rsp_payload_outputs_0,
    input               reset,
    input               clk
  );

  // SIMD multiply step:
  reg signed [8:0] input_offset,filter_offset;
  wire signed [15:0] prod_0, prod_1, prod_2, prod_3;
  assign prod_0 =  ($signed(cmd_payload_inputs_0[7 : 0]) + input_offset)
         * ($signed(cmd_payload_inputs_1[7 : 0]) + filter_offset);
  assign prod_1 =  ($signed(cmd_payload_inputs_0[15: 8]) + input_offset)
         * ($signed(cmd_payload_inputs_1[15: 8]) + filter_offset);
  assign prod_2 =  ($signed(cmd_payload_inputs_0[23:16]) + input_offset)
         * ($signed(cmd_payload_inputs_1[23:16]) + filter_offset);
  assign prod_3 =  ($signed(cmd_payload_inputs_0[31:24]) + input_offset)
         * ($signed(cmd_payload_inputs_1[31:24]) + filter_offset);

  wire signed [31:0] sum_prods;
  assign sum_prods = prod_0 + prod_1 + prod_2 + prod_3;

  // Only not ready for a command when we have a response.
  assign cmd_ready = ~rsp_valid;

  // Constants for Function IDs
  parameter FUNC_ID_ADD = 7'd0;
  parameter FUNC_ID_RESET = 7'd1;
  parameter FUNC_ID_SET_OFFSET = 7'd2;
  parameter FUNC_ID_FULLY = 7'd3;

  //input offset
  always @(posedge clk) begin
    if (reset) input_offset <= 9'd128;
    else if(cmd_valid && cmd_payload_function_id[9:3]==FUNC_ID_SET_OFFSET) input_offset <= cmd_payload_inputs_0[8:0];  
  end

  //filter offset
  always @(posedge clk) begin
    if(reset) filter_offset <= 0;
    else if(cmd_valid && cmd_payload_function_id[9:3]==FUNC_ID_SET_OFFSET) filter_offset <= cmd_payload_inputs_1[8:0];
    else filter_offset <= 0;
  end
  //rsp_valid
  always @(posedge clk) begin
    if (reset) rsp_valid <= 0;
    else if(cmd_valid) rsp_valid <= 1;
    else rsp_valid <= 0;
  end

  //output
  always @(posedge clk) begin
    if(reset) rsp_payload_outputs_0 <= 0;
    else if(cmd_valid && cmd_payload_function_id[9:3]==FUNC_ID_ADD) rsp_payload_outputs_0 <= rsp_payload_outputs_0 + sum_prods;
    else if(cmd_valid && cmd_payload_function_id[9:3]==FUNC_ID_FULLY) rsp_payload_outputs_0 <= rsp_payload_outputs_0 + sum_prods;
    else if(cmd_valid && cmd_payload_function_id[9:3]==FUNC_ID_RESET) rsp_payload_outputs_0 <= 0;
  end
endmodule
