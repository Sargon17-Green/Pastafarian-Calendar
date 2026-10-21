// Independent, test-only arithmetic reference for the pinned Scroll.
// These functions are not imported or instantiated by production RTL.
// Stage 1 does NOT yet implement the full independent calendar oracle.
package pcal_stage1_oracle_pkg;
    localparam logic signed [255:0] ORACLE_M =
        (256'sd1 << 127) - 256'sd1;
    localparam logic signed [255:0] ORACLE_FOUNDATION =
        -256'sd15055671;

    function automatic logic signed [255:0] oracle_save(
        input logic signed [255:0] x
    );
        logic signed [255:0] r;
        begin
            r = (x - 256'sd1) % ORACLE_M;
            if (r < 0) r = r + ORACLE_M;
            oracle_save = r + 256'sd1;
        end
    endfunction

    function automatic logic signed [255:0] oracle_day_count(
        input logic signed [63:0] d
    );
        logic signed [255:0] a;
        begin
            a = d;
            if (a < ORACLE_FOUNDATION)
                oracle_day_count = (ORACLE_FOUNDATION - a) * 256'sd2;
            else
                oracle_day_count = (a - ORACLE_FOUNDATION) * 256'sd2
                                   + 256'sd1;
        end
    endfunction

    function automatic logic signed [255:0] oracle_distance(
        input logic signed [63:0] c,
        input logic signed [63:0] t
    );
        logic signed [255:0] diff;
        begin
            diff = $signed(t) - $signed(c);
            if (diff < 0) diff = -diff;
            oracle_distance = diff + 256'sd1;
        end
    endfunction

    function automatic logic signed [255:0] oracle_sum(
        input logic signed [63:0] c,
        input logic signed [63:0] t
    );
        begin
            oracle_sum = oracle_day_count(c) + oracle_day_count(t);
        end
    endfunction

    function automatic logic [1:0] oracle_direction(
        input logic signed [63:0] c,
        input logic signed [63:0] t
    );
        if (t < c)      oracle_direction = 2'd1;
        else if (t == c) oracle_direction = 2'd2;
        else             oracle_direction = 2'd3;
    endfunction
endpackage
