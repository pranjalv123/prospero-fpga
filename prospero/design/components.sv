module const_element #(
    parameter WIDTH = 8,        // Total width of the operand
    parameter FRAC_BITS = 4,    // Number of fractional bits
    parameter real VALUE = 0.0  // The fixed-point value to represent
)(
    output logic [WIDTH-1:0] outp
);
    // Convert the real value to fixed-point representation
    // Scale by 2^FRAC_BITS to get the integer representation
    
    typedef logic [WIDTH-1:0] uintw_t;
    localparam uintw_t FIXED_VALUE = uintw_t'(VALUE * (64'h1 << FRAC_BITS));
    
    // Assign the fixed-point value
    assign outp = FIXED_VALUE[WIDTH-1:0];

endmodule

module fixed_point_mul #(
    parameter WIDTH = 8,        // Total width of each operand
    parameter FRAC_BITS = 4     // Number of fractional bits
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] outp,
    output logic [2*WIDTH-1:0] full_product,
    output logic [WIDTH-1:0] scaled_product
);
    // Internal signals
    //logic signed [2*WIDTH-1:0] full_product;
    //logic signed [WIDTH-1:0] scaled_product;
    logic round_bit; 
    logic sticky_bit;
    
    
    assign full_product = $signed(a) * $signed(b);
    assign scaled_product = full_product >>> (FRAC_BITS);

    
  //  assign round_bit = full_product[FRAC_BITS-1];
  //  assign sticky_bit = |full_product[FRAC_BITS-2:0];
  //  assign outp = scaled_product + ((round_bit && (sticky_bit || scaled_product[0])) ? 1'b1 : 1'b0);
    assign outp = scaled_product; 
    // Apply rounding (round to nearest, ties to even)
endmodule

module fixed_point_add #(
    parameter WIDTH = 8,        // Total width of each operand
    parameter FRAC_BITS = 4     // Number of fractional bits
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] outp
);
    // Add the fixed-point numbers directly
    // Since they have the same fixed-point format, we can add them as is
    logic [WIDTH:0] full_sum;
    
    // Perform the addition with an extra bit to detect overflow
    assign full_sum = $signed(a) + $signed(b);
    
    // Saturate the result if there's an overflow
    assign outp = (full_sum[WIDTH] != full_sum[WIDTH-1]) ? 
                  (full_sum[WIDTH] ? {1'b1, {(WIDTH-1){1'b0}}} : {1'b0, {(WIDTH-1){1'b1}}}) :
                  full_sum[WIDTH-1:0];
endmodule

module fixed_point_sub #(
    parameter WIDTH = 8,        // Total width of each operand
    parameter FRAC_BITS = 4     // Number of fractional bits
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] outp
);
    // Subtract the fixed-point numbers directly
    // Since they have the same fixed-point format, we can subtract them as is
    logic [WIDTH:0] full_diff;
    
    // Perform the subtraction with an extra bit to detect overflow
    assign full_diff = $signed(a) - $signed(b);
    
    // Saturate the result if there's an overflow
    assign outp = (full_diff[WIDTH] != full_diff[WIDTH-1]) ? 
                  (full_diff[WIDTH] ? {1'b1, {(WIDTH-1){1'b0}}} : {1'b0, {(WIDTH-1){1'b1}}}) :
                  full_diff[WIDTH-1:0];
endmodule

module fixed_point_max #(
    parameter WIDTH = 8,        // Total width of each operand
    parameter FRAC_BITS = 4     // Number of fractional bits
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] outp
);
    // Compare the two fixed-point numbers and select the maximum
    logic a_greater_than_b;
    
    // Compare two signed fixed-point numbers
    assign a_greater_than_b = $signed(a) > $signed(b);
    
    // Select the maximum value
    assign outp = a_greater_than_b ? a : b;
endmodule

module fixed_point_min #(
    parameter WIDTH = 8,        // Total width of each operand
    parameter FRAC_BITS = 4     // Number of fractional bits
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    output logic [WIDTH-1:0] outp
);
    // Compare the two fixed-point numbers and select the minimum
    logic a_less_than_b;
    
    // Compare two signed fixed-point numbers
    assign a_less_than_b = $signed(a) < $signed(b);
    
    // Select the minimum value
    assign outp = a_less_than_b ? a : b;
endmodule

module fixed_point_neg #(
    parameter WIDTH = 8,        // Total width of the operand
    parameter FRAC_BITS = 4     // Number of fractional bits
)(
    input  logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] outp
);
    // Special case handling for most negative value
    // In two's complement, negating the most negative value would cause overflow
    logic is_most_negative;
    logic [WIDTH-1:0] most_positive;
    
    // Check if input is the most negative value (10000...)
    assign is_most_negative = (in[WIDTH-1] == 1'b1) && (|in[WIDTH-2:0] == 1'b0);
    
    // The most positive value is 01111...
    assign most_positive = {1'b0, {(WIDTH-1){1'b1}}};
    
    // Perform the negation with overflow handling
    assign outp = is_most_negative ? most_positive : -$signed(in);
endmodule

module fixed_point_square #(
    parameter WIDTH = 8,        // Total width of the operand
    parameter FRAC_BITS = 4     // Number of fractional bits
)(
    input  logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] outp
);
    // Reuse the multiplication module to square the input
    fixed_point_mul #(
        .WIDTH(WIDTH),
        .FRAC_BITS(FRAC_BITS)
    ) mult_inst (
        .a(in),
        .b(in),
        .outp(outp)
    );
endmodule

module fixed_point_sqrt #(
    parameter WIDTH = 8,        // Total width of the operand
    parameter FRAC_BITS = 4     // Number of fractional bits
)(
    input  logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] outp
);
    // Enhanced non-restoring square root algorithm optimized for fixed-point accuracy
    
    // Double width for internal calculations to maintain precision
    localparam INTERNAL_WIDTH = WIDTH * 2;
    
    // Intermediate signals with extended precision
    logic [INTERNAL_WIDTH-1:0] x;                // Extended input value
    logic [INTERNAL_WIDTH/2:0] q;                // Current result
    logic [INTERNAL_WIDTH/2+1:0] ac;             // Accumulator
    logic [INTERNAL_WIDTH/2+1:0] test_res;       // Test subtraction result
    logic [WIDTH-1:0] temp_out;                  // Temporary output before adjustment
    logic [2*WIDTH-1:0] squared;                 // The result squared
    logic [WIDTH-1:0] error;                     // Error of the approximation
    
    // Special case detection using bitwise operations
    logic is_zero, is_negative;
    logic [WIDTH-1:0] msb_mask;
    
    // Create mask for MSB
    assign msb_mask = 1 << (WIDTH-1);
    
    // Check for special cases using bitwise operations
    assign is_zero = (in == 0);
    assign is_negative = (in & msb_mask) != 0;
    
    integer i;
    
    always_comb begin
        // Handle special cases
        if (is_zero) begin
            outp = 0;
        end
        // Negative inputs are invalid for square root
        else if (is_negative) begin
            outp = 0;
        end
        else begin
            // Initialize with extended precision
            // Shift input left to properly handle fixed-point format
            x = {in, {WIDTH{1'b0}}};
            q = 0;
            ac = 0;
            
            // Square root algorithm with higher precision
            for (i = INTERNAL_WIDTH/2-1; i >= 0; i--) begin
                // Shift accumulator left by 2 bits and add 2 bits from x
                ac = (ac << 2) | ((x >> (i*2)) & 2'b11);
                
                // Try to subtract (q << 1) | 1
                test_res = ac - ((q << 2) | 2'b01);
                
                // Check if result is negative using bitwise operation
                if ((test_res & (1 << (INTERNAL_WIDTH/2+1))) == 0) begin
                    ac = test_res;
                    q = (q << 1) | 1;
                end else begin
                    q = q << 1;
                end
            end
            
            // Scale result to the correct fixed-point representation
            outp = q >> (WIDTH/2 - FRAC_BITS/2);
        end
    end
endmodule


