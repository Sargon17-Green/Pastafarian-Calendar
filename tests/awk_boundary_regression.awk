# Native boundary regression for AWK+nynorsk normative oracle.
# Run: awk -f src/bigint.awk -f src/normative_oracle.awk -f tests/awk_boundary_regression.awk

function expect_exact(label, actual, expected) {
    CASES++
    # Prefix strings to prevent AWK's numeric-string comparisons from losing digits.
    if (("x" actual) != ("x" expected)) {
        printf "FAIL %s: got %s; expected %s\n", label, actual, expected
        FAILURES++
    }
}

BEGIN {
    oracle_init()

    work_counts("999999999999999999999999999999999999", "-999999999999999999999999999999999999")
    expect_exact("large action", COUNT_ACTION, "2000000000000000000000000000030111341")
    expect_exact("large target", COUNT_TARGET, "1999999999999999999999999999969888656")
    expect_exact("large distance", COUNT_DISTANCE, "1999999999999999999999999999999999999")
    expect_exact("large connection", COUNT_CONNECTION, "3999999999999999999999999999999999997")
    expect_exact("large direction", COUNT_DIRECTION, "1")

    work_counts("-15055671", "-15055671")
    expect_exact("foundation count", COUNT_ACTION, "1")
    expect_exact("same-day distance", COUNT_DISTANCE, "1")
    expect_exact("same-day connection", COUNT_CONNECTION, "2")
    expect_exact("same-day direction", COUNT_DIRECTION, "2")

    work_counts("-15055672", "-15055670")
    expect_exact("before foundation", COUNT_ACTION, "2")
    expect_exact("after foundation", COUNT_TARGET, "3")
    expect_exact("cross-foundation distance", COUNT_DISTANCE, "3")
    expect_exact("cross-foundation direction", COUNT_DIRECTION, "3")

    STREAM_FIRST=M; STREAM_STEP=1
    choose_rank_short("720")
    expect_exact("real modulus short forward rejection", CHOSEN_RANK, "1")
    STREAM_STEP=-1
    choose_rank_short("720")
    expect_exact("real modulus short backward rejection", CHOSEN_RANK, "720")

    # A small test modulus forces both short and wide rejection edges.
    M="17"; STREAM_FIRST="17"; STREAM_STEP=1
    choose_rank_short("6")
    expect_exact("short forward wrap", CHOSEN_RANK, "1")
    STREAM_STEP=-1
    choose_rank_short("6")
    expect_exact("short backward acceptance", CHOSEN_RANK, "6")

    STREAM_FIRST="16"; STREAM_STEP=1
    choose_rank_wide("180")
    expect_exact("wide forward wrap", CHOSEN_RANK, "1")
    STREAM_FIRST="1"; STREAM_STEP=-1
    choose_rank_wide("180")
    expect_exact("wide backward acceptance", CHOSEN_RANK, "180")

    # At N=M+1=18, M^2 mod N = 1: limit=288.
    # With a legal unit-step stream the largest wide value is 288,
    # so the upper boundary is accepted. Rejection first appears at N=M+2.
    STREAM_FIRST="16"; STREAM_STEP=1
    choose_rank_wide("18")
    expect_exact("wide M+1 upper accepted boundary", CHOSEN_RANK, "18")
    STREAM_FIRST="17"; STREAM_STEP=1
    choose_rank_wide("18")
    expect_exact("wide M+1 forward digit wrap", CHOSEN_RANK, "17")
    STREAM_FIRST="1"; STREAM_STEP=-1
    choose_rank_wide("18")
    expect_exact("wide M+1 backward digit wrap", CHOSEN_RANK, "3")
    STREAM_FIRST="17"; STREAM_STEP=-1
    choose_rank_wide("18")
    expect_exact("wide M+1 backward nonwrap", CHOSEN_RANK, "2")
    STREAM_FIRST="16"; STREAM_STEP=1
    choose_rank_wide("19")
    expect_exact("wide M+2 first reachable rejection", CHOSEN_RANK, "1")

    # The exact 2-digit to 3-digit transition is N=M^2+1.
    # With M=17, N=289 uses two digits, N=290 uses three.
    STREAM_FIRST="15"; STREAM_STEP=1
    choose_rank_wide("289")
    expect_exact("wide square two-digit boundary", CHOSEN_RANK, "270")
    choose_rank_wide("290")
    expect_exact("wide square+1 three-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST="17"; STREAM_STEP=-1
    choose_rank_wide("290")
    expect_exact("wide square+1 three-digit backward acceptance", CHOSEN_RANK, "258")
    STREAM_STEP=1
    choose_rank_wide("290")
    expect_exact("wide square+1 three-digit forward wrap", CHOSEN_RANK, "16")

    # Original M=2^127-1, N=M+1. Both wide samples are accepted
    # under limit=M^2-1; these check full-width integer rank arithmetic.
    M="170141183460469231731687303715884105727"
    WIDE_N=bi_add(M,"1")
    STREAM_FIRST=bi_sub(M,"1"); STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original M+1 forward max rank", CHOSEN_RANK, WIDE_N)
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original M+1 backward rank two", CHOSEN_RANK, "2")

    # For N=M+2 at the original 127-bit modulus, M^2 mod N=4.
    # The stream (M-1,M) yields wide=M^2-1, three above limit=M^2-4.
    # A forward rejected rank must restart at 1, not reduce modulo N.
    WIDE_N=bi_add(M,"2")
    STREAM_FIRST=bi_sub(M,"1"); STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original M+2 forward rejection", CHOSEN_RANK, "1")

    # The same digit-count boundary at the original 127-bit modulus.
    WIDE_SQUARE=bi_square(M)
    STREAM_FIRST=bi_sub(M,"1"); STREAM_STEP=1
    choose_rank_wide(WIDE_SQUARE)
    expect_exact("wide original square two-digit boundary", CHOSEN_RANK, bi_sub(WIDE_SQUARE,"1"))

    WIDE_N=bi_add(WIDE_SQUARE,"1")
    STREAM_FIRST=bi_sub(M,"2"); STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original square+1 three-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original square+1 three-digit backward acceptance", CHOSEN_RANK, bi_add(bi_sub(WIDE_SQUARE,bi_mul_small(M,2)),"3"))
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original square+1 three-digit forward wrap", CHOSEN_RANK, bi_sub(M,"1"))


    # The three-digit to four-digit boundary at original M=2^127-1.
    # N=M^3 is within three digits, while N=M^3+1 requires four.
    WIDE_CUBE=bi_mul(WIDE_SQUARE,M)
    STREAM_FIRST=bi_sub(M,"3"); STREAM_STEP=1
    choose_rank_wide(WIDE_CUBE)
    expect_exact("wide original cube three-digit boundary", CHOSEN_RANK, bi_sub(bi_sub(bi_sub(WIDE_CUBE,WIDE_SQUARE),bi_mul_small(M,2)),"3"))

    WIDE_N=bi_add(WIDE_CUBE,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original cube+1 four-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original cube+1 four-digit backward acceptance", CHOSEN_RANK, bi_add(bi_sub(bi_sub(WIDE_CUBE,bi_mul_small(WIDE_SQUARE,2)),bi_mul_small(M,2)),"4"))
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original cube+1 four-digit forward wrap", CHOSEN_RANK, bi_sub(bi_add(WIDE_SQUARE,M),"2"))

    # Four-digit to five-digit transition at the original M=2^127-1.
    # N=M^4 uses four digits; N=M^4+1 requires five.
    WIDE_FOURTH=bi_square(WIDE_SQUARE)
    STREAM_FIRST=bi_sub(M,"4"); STREAM_STEP=1
    choose_rank_wide(WIDE_FOURTH)
    expect_exact("wide original fourth four-digit boundary", CHOSEN_RANK, bi_sub(bi_sub(bi_sub(bi_sub(WIDE_FOURTH,WIDE_CUBE),bi_mul_small(WIDE_SQUARE,2)),bi_mul_small(M,3)),"4"))

    WIDE_N=bi_add(WIDE_FOURTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original fourth+1 five-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original fourth+1 five-digit backward acceptance", CHOSEN_RANK, bi_add(bi_sub(bi_sub(bi_sub(WIDE_FOURTH,bi_mul_small(WIDE_CUBE,3)),bi_mul_small(WIDE_SQUARE,2)),bi_mul_small(M,2)),"5"))
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original fourth+1 five-digit forward wrap", CHOSEN_RANK, bi_sub(bi_add(bi_add(bi_mul_small(WIDE_CUBE,2),WIDE_SQUARE),M),"3"))

    # Five-digit to six-digit transition at the original M=2^127-1.
    # N=M^5 uses five digits; N=M^5+1 requires six.
    WIDE_FIFTH=bi_mul(WIDE_FOURTH,M)
    STREAM_FIRST=bi_sub(M,"5"); STREAM_STEP=1
    choose_rank_wide(WIDE_FIFTH)
    expect_exact("wide original fifth five-digit boundary", CHOSEN_RANK, bi_sub(bi_sub(bi_sub(bi_sub(bi_sub(WIDE_FIFTH,WIDE_FOURTH),bi_mul_small(WIDE_CUBE,2)),bi_mul_small(WIDE_SQUARE,3)),bi_mul_small(M,4)),"5"))

    WIDE_N=bi_add(WIDE_FIFTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original fifth+1 six-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original fifth+1 six-digit backward acceptance", CHOSEN_RANK, bi_add(bi_sub(bi_sub(bi_sub(bi_sub(WIDE_FIFTH,bi_mul_small(WIDE_FOURTH,4)),bi_mul_small(WIDE_CUBE,3)),bi_mul_small(WIDE_SQUARE,2)),bi_mul_small(M,2)),"6"))
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original fifth+1 six-digit forward wrap", CHOSEN_RANK, bi_sub(bi_add(bi_add(bi_add(bi_mul_small(WIDE_FOURTH,3),bi_mul_small(WIDE_CUBE,2)),WIDE_SQUARE),M),"4"))

    # Six-digit to seven-digit transition at the original M=2^127-1.
    # N=M^6 uses six digits; N=M^6+1 requires seven.
    WIDE_SIXTH=bi_square(WIDE_CUBE)
    STREAM_FIRST=bi_sub(M,"6"); STREAM_STEP=1
    choose_rank_wide(WIDE_SIXTH)
    expect_exact("wide original sixth six-digit boundary", CHOSEN_RANK, bi_sub(bi_sub(bi_sub(bi_sub(bi_sub(bi_sub(WIDE_SIXTH,WIDE_FIFTH),bi_mul_small(WIDE_FOURTH,2)),bi_mul_small(WIDE_CUBE,3)),bi_mul_small(WIDE_SQUARE,4)),bi_mul_small(M,5)),"6"))

    WIDE_N=bi_add(WIDE_SIXTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original sixth+1 seven-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original sixth+1 seven-digit backward acceptance", CHOSEN_RANK, bi_add(bi_sub(bi_sub(bi_sub(bi_sub(bi_sub(WIDE_SIXTH,bi_mul_small(WIDE_FIFTH,5)),bi_mul_small(WIDE_FOURTH,4)),bi_mul_small(WIDE_CUBE,3)),bi_mul_small(WIDE_SQUARE,2)),bi_mul_small(M,2)),"7"))
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original sixth+1 seven-digit forward wrap", CHOSEN_RANK, bi_sub(bi_add(bi_add(bi_add(bi_add(bi_mul_small(WIDE_FIFTH,4),bi_mul_small(WIDE_FOURTH,3)),bi_mul_small(WIDE_CUBE,2)),WIDE_SQUARE),M),"5"))


    # Seven-digit to eight-digit transition at original M=2^127-1.
    # N=M^7 uses seven digits; N=M^7+1 requires eight.
    WIDE_SEVENTH=bi_mul(WIDE_SIXTH,M)
    STREAM_FIRST=bi_sub(M,"7"); STREAM_STEP=1
    choose_rank_wide(WIDE_SEVENTH)
    expect_exact("wide original seventh seven-digit boundary", CHOSEN_RANK, bi_sub(bi_sub(bi_sub(bi_sub(bi_sub(bi_sub(bi_sub(WIDE_SEVENTH,WIDE_SIXTH),bi_mul_small(WIDE_FIFTH,2)),bi_mul_small(WIDE_FOURTH,3)),bi_mul_small(WIDE_CUBE,4)),bi_mul_small(WIDE_SQUARE,5)),bi_mul_small(M,6)),"7"))

    WIDE_N=bi_add(WIDE_SEVENTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original seventh+1 eight-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original seventh+1 eight-digit backward acceptance", CHOSEN_RANK, bi_add(bi_sub(bi_sub(bi_sub(bi_sub(bi_sub(bi_sub(WIDE_SEVENTH,bi_mul_small(WIDE_SIXTH,6)),bi_mul_small(WIDE_FIFTH,5)),bi_mul_small(WIDE_FOURTH,4)),bi_mul_small(WIDE_CUBE,3)),bi_mul_small(WIDE_SQUARE,2)),bi_mul_small(M,2)),"8"))
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    expect_exact("wide original seventh+1 eight-digit forward wrap", CHOSEN_RANK, bi_sub(bi_add(bi_add(bi_add(bi_add(bi_add(bi_mul_small(WIDE_SIXTH,5),bi_mul_small(WIDE_FIFTH,4)),bi_mul_small(WIDE_FOURTH,3)),bi_mul_small(WIDE_CUBE,2)),WIDE_SQUARE),M),"6"))

    if (FAILURES) {
        printf "FAIL: %d of %d AWK native boundary assertions\n", FAILURES, CASES
        exit 1
    }
    printf "PASS: %d AWK native boundary assertions\n", CASES
}
