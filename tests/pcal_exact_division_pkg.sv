// Independent test-only long division for all 384-bit UNSIGNED operands.
// Unlike Icarus Verilog 12's native wide / on some 381-bit operands,
// this is binary long division with an explicit 385-bit remainder.
// Production RTL must not import this test-only package.
package pcal_exact_division_pkg;
    function automatic logic [383:0] exact_quotient_384(
        input logic [383:0] numerator,
        input logic [383:0] denominator
    );
        logic [384:0] remainder;
        logic [384:0] wide_denominator;
        logic [383:0] quotient;
        integer bit_index;
        begin
            quotient = 384'b0;
            remainder = 385'b0;
            wide_denominator = {1'b0, denominator};
            if (denominator == 384'b0) begin
                exact_quotient_384 = {384{1'bx}};
            end else begin
                for (bit_index=383; bit_index>=0; bit_index=bit_index-1) begin
                    remainder = {remainder[383:0], numerator[bit_index]};
                    if (remainder >= wide_denominator) begin
                        remainder = remainder - wide_denominator;
                        quotient[bit_index] = 1'b1;
                    end
                end
                exact_quotient_384 = quotient;
            end
        end
    endfunction

    function automatic logic [383:0] exact_remainder_384(
        input logic [383:0] numerator,
        input logic [383:0] denominator
    );
        logic [383:0] quotient;
        begin
            if (denominator == 384'b0) begin
                exact_remainder_384 = {384{1'bx}};
            end else begin
                quotient = exact_quotient_384(numerator,denominator);
                // q*d <= numerator by construction: no 384-bit overflow.
                exact_remainder_384 = numerator - quotient*denominator;
            end
        end
    endfunction
endpackage
