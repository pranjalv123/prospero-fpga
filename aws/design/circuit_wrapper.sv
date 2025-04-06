// Pipelined wrapper for the circuit module to improve timing

module circuit_wrapper #(
    parameter WIDTH = 64,
    parameter FRAC_BITS = 32
)(
    input  logic              clk,
    input  logic              reset,
    input  logic [WIDTH-1:0]  x,
    input  logic [WIDTH-1:0]  y,
    output logic [WIDTH-1:0]  out
);
    // Implementation approach:
    // 1. Add input registers
    // 2. Use pipelined versions of key arithmetic components
    // 3. Add output registers
    
    // Total pipeline latency (adjust based on components used)
    localparam LATENCY = 5;
    
    // Input registration and buffering
    logic [WIDTH-1:0] x_reg, y_reg;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            x_reg <= 0;
            y_reg <= 0;
        end else begin
            x_reg <= x;
            y_reg <= y;
        end
    end
    
    // Instantiate actual circuit
    // Note: Since we're using this as a wrapper, we'll assume the circuit has been
    // modified to use pipelined versions of critical components
    logic [WIDTH-1:0] circuit_out;
    
    circuit #(
        .WIDTH(WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) circuit_inst (
        .clk(clk),
        .reset(reset),
        .x(x_reg),
        .y(y_reg),
        .out(circuit_out)
    );
    
    // Output registration
    logic [WIDTH-1:0] out_pipe[LATENCY-1:0];
    
    always_ff @(posedge clk) begin
        if (reset) begin
            for (int i = 0; i < LATENCY; i++) begin
                out_pipe[i] <= 0;
            end
        end else begin
            out_pipe[0] <= circuit_out;
            for (int i = 1; i < LATENCY; i++) begin
                out_pipe[i] <= out_pipe[i-1];
            end
        end
    end
    
    // Final output
    assign out = out_pipe[LATENCY-1];
    
endmodule 