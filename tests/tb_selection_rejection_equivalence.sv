`timescale 1ns/1ps
// Stage-1 test-only selection semantics. This is not production RTL.
// Exhaustively compares an independent loop against an O(1) shortcut.
module tb_selection_rejection_equivalence;
    localparam logic signed [383:0] M = (384'sd1 << 127) - 384'sd1;
    integer space, n, first, direction;
    integer picked_loop, rejects_loop, accepted_loop;
    integer picked_direct, rejects_direct, accepted_direct;
    integer cases = 0;
    logic signed [383:0] big_space, big_n, big_l, big_first;

    task automatic iterative_pick(
        input integer a,
        input integer choice_count,
        input integer domain,
        input integer step,
        output integer accepted,
        output integer rejects,
        output integer selected
    );
        integer limit;
        begin
            limit = (domain / choice_count) * choice_count;
            accepted = a;
            rejects = 0;
            while (accepted > limit) begin
                accepted = 1 + ((accepted - 1 + step + domain) % domain);
                rejects = rejects + 1;
                if (rejects > domain)
                    $fatal(1, "UNBOUNDED_ITERATIVE_REJECTION");
            end
            selected = 1 + ((accepted - 1) % choice_count);
        end
    endtask

    task automatic direct_pick(
        input integer a,
        input integer choice_count,
        input integer domain,
        input integer step,
        output integer accepted,
        output integer rejects,
        output integer selected
    );
        integer limit;
        begin
            limit = (domain / choice_count) * choice_count;
            if (a <= limit) begin
                accepted = a;
                rejects = 0;
            end else if (step == 1) begin
                accepted = 1;
                rejects = domain - a + 1;
            end else begin
                accepted = limit;
                rejects = a - limit;
            end
            selected = 1 + ((accepted - 1) % choice_count);
        end
    endtask

    initial begin
        for (space = 2; space <= 64; space = space + 1) begin
            for (n = 1; n <= space; n = n + 1) begin
                for (first = 1; first <= space; first = first + 1) begin
                    for (direction = -1; direction <= 1; direction = direction + 2) begin
                        iterative_pick(first, n, space, direction,
                                       accepted_loop, rejects_loop, picked_loop);
                        direct_pick(first, n, space, direction,
                                    accepted_direct, rejects_direct, picked_direct);
                        if (accepted_loop != accepted_direct ||
                            rejects_loop != rejects_direct ||
                            picked_loop != picked_direct)
                            $fatal(1,"SHORTCUT_PARITY");
                        cases = cases + 1;
                    end
                end
            end
        end

        // Full M, short-selection rejection at the last possible answer.
        big_space = M;
        big_n = M - 384'sd1;
        big_l = (big_space / big_n) * big_n;
        big_first = M;
        if (big_l != M - 384'sd1 || big_first <= big_l ||
            big_space - big_first + 384'sd1 != 384'sd1 ||
            big_first - big_l != 384'sd1)
            $fatal(1, "SHORT_DOMAIN_127BIT_BOUNDARY");

        // Wide-domain arithmetic uses more than 127 bits.
        // These are proofs of integer identities, not exhaustive wide ranks.
        big_space = M * M;
        big_n = M + 384'sd1;
        big_l = (big_space / big_n) * big_n;
        if (big_l > big_space || (big_space - big_l) >= big_n ||
            big_space <= M || big_l <= 384'sd0)
            $fatal(1, "WIDE_TWO_DIGITS_ARITHMETIC");
        big_first = big_space;
        if (big_space - big_first + 384'sd1 != 384'sd1 ||
            big_first - big_l <= 384'sd0)
            $fatal(1, "WIDE_TWO_DIGITS_BOUNDARY");

        big_space = M * M * M;
        big_n = M * M + 384'sd1;
        big_l = (big_space / big_n) * big_n;
        // Diagnostics are only printed on genuine failure. Preserve
        // the same acceptance predicate until we know why Icarus failed.
        if (big_l > big_space || (big_space - big_l) >= big_n ||
            big_space <= M * M || big_l <= 384'sd0) begin
            $display("WIDE3_DIAG space=%h",big_space);
            $display("WIDE3_DIAG n=%h",big_n);
            $display("WIDE3_DIAG quotient=%h",big_space/big_n);
            $display("WIDE3_DIAG l=%h",big_l);
            $display("WIDE3_DIAG remainder=%h",big_space-big_l);
            $display("WIDE3_DIAG expected_q=%h",M-384'sd1);
            $display("WIDE3_DIAG expected_r=%h",M*M-M+384'sd1);
            $display("WIDE3_DIAG predicates=%b %b %b %b",
                big_l>big_space,
                (big_space-big_l)>=big_n,
                big_space<=M*M,
                big_l<=384'sd0);
            $fatal(1, "WIDE_THREE_DIGITS_ARITHMETIC");
        end

        $display("STAGE1_SELECTION_REJECTION_EQUIVALENCE_PASS cases=%0d", cases);
        $finish;
    end
endmodule
