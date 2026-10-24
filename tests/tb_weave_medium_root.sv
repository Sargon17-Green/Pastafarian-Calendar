`timescale 1ns/1ps
// Test-only exact root woven-month counter for the first six actual
// Foundation month lengths (115,108,119,109,106,81).
// Arithmetic is 2048-bit. No floating point, no calendar production RTL.
module tb_weave_medium_root;
    localparam integer WIDTH=2048;
    localparam integer LIMBS=64;
    localparam integer MAXLEN=638;
    logic [WIDTH-1:0] old_first [0:MAXLEN];
    logic [WIDTH-1:0] new_first [0:MAXLEN];
    logic [WIDTH-1:0] choose_coefficient [0:MAXLEN];
    logic [WIDTH-1:0] prefix, total, product_term;
    integer actual_lengths [0:5];
    integer n_months, old_n, new_n, k, t, p;
    integer expected_bits[2:6];

    function automatic logic [WIDTH-1:0] mul_small(
        input logic [WIDTH-1:0] input_value,
        input integer factor
    );
        begin
            mul_small = input_value * $unsigned(factor);
        end
    endfunction

    function automatic logic [WIDTH-1:0] exact_div_small(
        input logic [WIDTH-1:0] numerator,
        input integer denominator
    );
        logic [WIDTH-1:0] quotient;
        logic [63:0] numerator_limb, carry;
        integer index_limb;
        begin
            quotient='0;
            carry=64'd0;
            if(denominator<=0 || denominator>MAXLEN)
                $fatal(1,"SMALL_DIVISOR_RANGE");
            for(index_limb=LIMBS-1;index_limb>=0;index_limb=index_limb-1) begin
                numerator_limb=(carry << 32) |
                    {32'b0,numerator[index_limb*32 +: 32]};
                quotient[index_limb*32 +: 32] =
                    (numerator_limb / $unsigned(denominator));
                carry=numerator_limb % $unsigned(denominator);
            end
            if(carry!=64'd0)
                $fatal(1,"NON_EXACT_BINOMIAL_SMALL_DIVISION");
            exact_div_small=quotient;
        end
    endfunction

    function automatic integer used_bits(input logic [WIDTH-1:0] val);
        integer z;
        begin
            used_bits=0;
            for(z=WIDTH-1;z>=0;z=z-1)
                if(val[z] && used_bits==0) used_bits=z+1;
        end
    endfunction

    initial begin
        actual_lengths[0]=115;
        actual_lengths[1]=108;
        actual_lengths[2]=119;
        actual_lengths[3]=109;
        actual_lengths[4]=106;
        actual_lengths[5]=81;
        expected_bits[2]=217;
        expected_bits[3]=528;
        expected_bits[4]=880;
        expected_bits[5]=1262;
        expected_bits[6]=1602;
        for(k=0;k<=MAXLEN;k=k+1) begin
            old_first[k]='0;
            new_first[k]='0;
            choose_coefficient[k]='0;
        end
        // Only first occurrence of month #1 is at position 1.
        old_first[1]=2048'd1;
        old_n=actual_lengths[0];
        for(n_months=2;n_months<=6;n_months=n_months+1) begin
            new_n=old_n+actual_lengths[n_months-1];
            for(k=0;k<=new_n;k=k+1) new_first[k]='0;

            // For t=0..old_n-1:
            // coef[t] = C(current_month_length + t - 2,t).
            // Multiply by a small integer and divide exactly by t.
            choose_coefficient[0]=2048'd1;
            for(t=1;t<old_n;t=t+1) begin
                product_term=mul_small(choose_coefficient[t-1],
                    actual_lengths[n_months-1]+t-2);
                choose_coefficient[t]=exact_div_small(product_term,t);
            end

            // Lexical first-position transfer.
            prefix='0;
            for(k=1;k<=old_n;k=k+1) begin
                prefix=prefix+old_first[k];
                if(k==old_n) new_first[k+1]=prefix;
                else new_first[k+1]=prefix*choose_coefficient[old_n-k];
            end
            total='0;
            for(k=1;k<=new_n;k=k+1) begin
                total=total+new_first[k];
                old_first[k]=new_first[k];
            end
            if(used_bits(total)!=expected_bits[n_months])
                $fatal(1,"MEDIUM_WEAVE_BIT_LENGTH n=%0d bits=%0d",
                    n_months,used_bits(total));
            case(n_months)
                2: if(total!==2048'h18948a7e0534467e62c15e1c0d46305e3ce7668d0f9916fa229eb88)
                    $fatal(1,"MEDIUM_WEAVE_EXACT_ROOT n=2");
                3: if(total!==2048'hda581ab5cd215efc374a1f3ca4de12809b63d9271ace1fa380e145fc3d7f991dc582ba1f6c1403fa96919bf6dd48e417f46a917a0fddebc6481f368d4451da12b575)
                    $fatal(1,"MEDIUM_WEAVE_EXACT_ROOT n=3");
                4: if(total!==2048'h8ccd0578f34d96b25c29a168a6f352cfb5c0482b789f33c4f15397c2273a6b821c1f1b03b2bd14bc8b3bdfb19163912efa4fea61952f5936eef27884b863d82cdbf1d886bf30e37e9a4fc86153082d57dbf54f025fd1c5c8443c93bfd79818589e0dae5d80014e4f57a0ebdb2410)
                    $fatal(1,"MEDIUM_WEAVE_EXACT_ROOT n=4");
                5: if(total!==2048'h214f25473a0cd30ec4488805a3b322d19b5da97e596f845dc9cc04e8c46e568fa6f4756d2ae44a992860fd3f15f2a0faa034a7614ed94311fe4ed36175ced89d8c10eb6ae2a57fe3ab7fd1733c85a9cc86a49c99e3e3e429cb5452d65ca37a1cc987ecc6c0e78562a9a3290d8ecf6cffad5ff0f2816d1102f8a2046ce668da434b5755bd22e5b80267c412c4a3ff06c20ec4d00eeba40bde8cc6face5162)
                    $fatal(1,"MEDIUM_WEAVE_EXACT_ROOT n=5");
                6: if(total!==2048'h3dbc36bdd8d0df2e7711f0c036831cb35ad4246a9f95b455e3ff30638060b82b3132c2b7904ca14805bb240862408ff4c054a2030e5ffa067b49c6114af17673ef7de19e35bc33b11311700ca82ca3d444467a3a2858b2e4ec38bcc9b54bfd7fc03d87460453bbdd62fe205c34782a28b80e1223f7259c9b87f4c4c964ebd7d3ab50f6229285bfd496f645854d639dd41a374bd2bcd72ac028c52b6bd56f290528d51aa9ec21fc354cab9c65d20ab38c4a94c86a8c2ace2ef307a18729b807b12df4d9a072abafce6)
                    $fatal(1,"MEDIUM_WEAVE_EXACT_ROOT n=6");
            endcase
            old_n=new_n;
            $display("STAGE1_MEDIUM_WEAVE_COUNT_PASS months=%0d days=%0d bits=%0d",
                     n_months,new_n,used_bits(total));
        end
        $display("STAGE1_MEDIUM_WEAVE_ALL_FIVE_GOLDENS_PASS");
        $finish;
    end
endmodule
