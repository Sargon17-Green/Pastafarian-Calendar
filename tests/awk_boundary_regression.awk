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


    # Eight-digit to nine-digit transition at original M=2^127-1.
    # N=M^8 uses eight digits; N=M^8+1 requires nine.
    # Expected ranks were checked independently with Python arbitrary integers.
    WIDE_EIGHTH=bi_square(WIDE_FOURTH)
    STREAM_FIRST=bi_sub(M,"8"); STREAM_STEP=1
    choose_rank_wide(WIDE_EIGHTH)
    EXPECTED_EIGHTH=bi_sub(WIDE_EIGHTH,WIDE_SEVENTH)
    EXPECTED_EIGHTH=bi_sub(EXPECTED_EIGHTH,bi_mul_small(WIDE_SIXTH,2))
    EXPECTED_EIGHTH=bi_sub(EXPECTED_EIGHTH,bi_mul_small(WIDE_FIFTH,3))
    EXPECTED_EIGHTH=bi_sub(EXPECTED_EIGHTH,bi_mul_small(WIDE_FOURTH,4))
    EXPECTED_EIGHTH=bi_sub(EXPECTED_EIGHTH,bi_mul_small(WIDE_CUBE,5))
    EXPECTED_EIGHTH=bi_sub(EXPECTED_EIGHTH,bi_mul_small(WIDE_SQUARE,6))
    EXPECTED_EIGHTH=bi_sub(EXPECTED_EIGHTH,bi_mul_small(M,7))
    EXPECTED_EIGHTH=bi_sub(EXPECTED_EIGHTH,"8")
    expect_exact("wide original eighth eight-digit boundary", CHOSEN_RANK, EXPECTED_EIGHTH)

    WIDE_N=bi_add(WIDE_EIGHTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original eighth+1 nine-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=bi_sub(WIDE_EIGHTH,bi_mul_small(WIDE_SEVENTH,7))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SIXTH,6))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FIFTH,5))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FOURTH,4))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_CUBE,3))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SQUARE,2))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(M,2))
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"9")
    expect_exact("wide original eighth+1 nine-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_mul_small(WIDE_SEVENTH,6)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SIXTH,5))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FIFTH,4))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FOURTH,3))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_CUBE,2))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,WIDE_SQUARE)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,M)
    EXPECTED_WRAP=bi_sub(EXPECTED_WRAP,"7")
    expect_exact("wide original eighth+1 nine-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Nine-digit to ten-digit transition at original M=2^127-1.
    # N=M^9 fits nine base-M digits; N=M^9+1 needs ten.
    # Expected ranks checked independently with Python arbitrary integers.
    WIDE_NINTH=bi_mul(WIDE_EIGHTH,M)
    STREAM_FIRST=bi_sub(M,"9"); STREAM_STEP=1
    choose_rank_wide(WIDE_NINTH)
    EXPECTED_NINTH=bi_sub(WIDE_NINTH,WIDE_EIGHTH)
    EXPECTED_NINTH=bi_sub(EXPECTED_NINTH,bi_mul_small(WIDE_SEVENTH,2))
    EXPECTED_NINTH=bi_sub(EXPECTED_NINTH,bi_mul_small(WIDE_SIXTH,3))
    EXPECTED_NINTH=bi_sub(EXPECTED_NINTH,bi_mul_small(WIDE_FIFTH,4))
    EXPECTED_NINTH=bi_sub(EXPECTED_NINTH,bi_mul_small(WIDE_FOURTH,5))
    EXPECTED_NINTH=bi_sub(EXPECTED_NINTH,bi_mul_small(WIDE_CUBE,6))
    EXPECTED_NINTH=bi_sub(EXPECTED_NINTH,bi_mul_small(WIDE_SQUARE,7))
    EXPECTED_NINTH=bi_sub(EXPECTED_NINTH,bi_mul_small(M,8))
    EXPECTED_NINTH=bi_sub(EXPECTED_NINTH,"9")
    expect_exact("wide original ninth nine-digit boundary", CHOSEN_RANK, EXPECTED_NINTH)

    WIDE_N=bi_add(WIDE_NINTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original ninth+1 ten-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=bi_sub(WIDE_NINTH,bi_mul_small(WIDE_EIGHTH,8))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SEVENTH,7))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SIXTH,6))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FIFTH,5))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FOURTH,4))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_CUBE,3))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SQUARE,2))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(M,2))
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"10")
    expect_exact("wide original ninth+1 ten-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_mul_small(WIDE_EIGHTH,7)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SEVENTH,6))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SIXTH,5))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FIFTH,4))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FOURTH,3))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_CUBE,2))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,WIDE_SQUARE)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,M)
    EXPECTED_WRAP=bi_sub(EXPECTED_WRAP,"8")
    expect_exact("wide original ninth+1 ten-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Ten-digit to eleven-digit transition at original M=2^127-1.
    # N=M^10 fits ten base-M digits; N=M^10+1 requires eleven.
    # Expected polynomial ranks independently checked with arbitrary-size integers.
    WIDE_TENTH=bi_mul(WIDE_NINTH,M)
    STREAM_FIRST=bi_sub(M,"10"); STREAM_STEP=1
    choose_rank_wide(WIDE_TENTH)
    EXPECTED_TENTH=bi_sub(WIDE_TENTH,WIDE_NINTH)
    EXPECTED_TENTH=bi_sub(EXPECTED_TENTH,bi_mul_small(WIDE_EIGHTH,2))
    EXPECTED_TENTH=bi_sub(EXPECTED_TENTH,bi_mul_small(WIDE_SEVENTH,3))
    EXPECTED_TENTH=bi_sub(EXPECTED_TENTH,bi_mul_small(WIDE_SIXTH,4))
    EXPECTED_TENTH=bi_sub(EXPECTED_TENTH,bi_mul_small(WIDE_FIFTH,5))
    EXPECTED_TENTH=bi_sub(EXPECTED_TENTH,bi_mul_small(WIDE_FOURTH,6))
    EXPECTED_TENTH=bi_sub(EXPECTED_TENTH,bi_mul_small(WIDE_CUBE,7))
    EXPECTED_TENTH=bi_sub(EXPECTED_TENTH,bi_mul_small(WIDE_SQUARE,8))
    EXPECTED_TENTH=bi_sub(EXPECTED_TENTH,bi_mul_small(M,9))
    EXPECTED_TENTH=bi_sub(EXPECTED_TENTH,"10")
    expect_exact("wide original tenth ten-digit boundary", CHOSEN_RANK, EXPECTED_TENTH)

    WIDE_N=bi_add(WIDE_TENTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original tenth+1 eleven-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=bi_sub(WIDE_TENTH,bi_mul_small(WIDE_NINTH,9))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_EIGHTH,8))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SEVENTH,7))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SIXTH,6))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FIFTH,5))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FOURTH,4))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_CUBE,3))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SQUARE,2))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(M,2))
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"11")
    expect_exact("wide original tenth+1 eleven-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_mul_small(WIDE_NINTH,8)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_EIGHTH,7))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SEVENTH,6))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SIXTH,5))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FIFTH,4))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FOURTH,3))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_CUBE,2))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,WIDE_SQUARE)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,M)
    EXPECTED_WRAP=bi_sub(EXPECTED_WRAP,"9")
    expect_exact("wide original tenth+1 eleven-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Eleven-digit to twelve-digit transition at original M=2^127-1.
    # N=M^11 fits eleven base-M digits; N=M^11+1 requires twelve.
    # Four expected ranks independently checked with arbitrary-size integers.
    WIDE_ELEVENTH=bi_mul(WIDE_TENTH,M)
    STREAM_FIRST=bi_sub(M,"11"); STREAM_STEP=1
    choose_rank_wide(WIDE_ELEVENTH)
    EXPECTED_ELEVENTH=bi_sub(WIDE_ELEVENTH,WIDE_TENTH)
    EXPECTED_ELEVENTH=bi_sub(EXPECTED_ELEVENTH,bi_mul_small(WIDE_NINTH,2))
    EXPECTED_ELEVENTH=bi_sub(EXPECTED_ELEVENTH,bi_mul_small(WIDE_EIGHTH,3))
    EXPECTED_ELEVENTH=bi_sub(EXPECTED_ELEVENTH,bi_mul_small(WIDE_SEVENTH,4))
    EXPECTED_ELEVENTH=bi_sub(EXPECTED_ELEVENTH,bi_mul_small(WIDE_SIXTH,5))
    EXPECTED_ELEVENTH=bi_sub(EXPECTED_ELEVENTH,bi_mul_small(WIDE_FIFTH,6))
    EXPECTED_ELEVENTH=bi_sub(EXPECTED_ELEVENTH,bi_mul_small(WIDE_FOURTH,7))
    EXPECTED_ELEVENTH=bi_sub(EXPECTED_ELEVENTH,bi_mul_small(WIDE_CUBE,8))
    EXPECTED_ELEVENTH=bi_sub(EXPECTED_ELEVENTH,bi_mul_small(WIDE_SQUARE,9))
    EXPECTED_ELEVENTH=bi_sub(EXPECTED_ELEVENTH,bi_mul_small(M,10))
    EXPECTED_ELEVENTH=bi_sub(EXPECTED_ELEVENTH,"11")
    expect_exact("wide original eleventh eleven-digit boundary", CHOSEN_RANK, EXPECTED_ELEVENTH)

    WIDE_N=bi_add(WIDE_ELEVENTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original eleventh+1 twelve-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=bi_sub(WIDE_ELEVENTH,bi_mul_small(WIDE_TENTH,10))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_NINTH,9))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_EIGHTH,8))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SEVENTH,7))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SIXTH,6))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FIFTH,5))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FOURTH,4))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_CUBE,3))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SQUARE,2))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(M,2))
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"12")
    expect_exact("wide original eleventh+1 twelve-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_mul_small(WIDE_TENTH,9)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_NINTH,8))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_EIGHTH,7))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SEVENTH,6))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SIXTH,5))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FIFTH,4))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FOURTH,3))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_CUBE,2))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,WIDE_SQUARE)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,M)
    EXPECTED_WRAP=bi_sub(EXPECTED_WRAP,"10")
    expect_exact("wide original eleventh+1 twelve-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)

    # Twelve-digit to thirteen-digit transition at original M=2^127-1.
    # N=M^12 uses twelve base-M digits; N=M^12+1 needs thirteen.
    # Expected ranks checked independently with arbitrary-precision integers.
    WIDE_TWELFTH=bi_mul(WIDE_ELEVENTH,M)
    STREAM_FIRST=bi_sub(M,"12"); STREAM_STEP=1
    choose_rank_wide(WIDE_TWELFTH)
    EXPECTED_TWELFTH=bi_sub(WIDE_TWELFTH,WIDE_ELEVENTH)
    EXPECTED_TWELFTH=bi_sub(EXPECTED_TWELFTH,bi_mul_small(WIDE_TENTH,2))
    EXPECTED_TWELFTH=bi_sub(EXPECTED_TWELFTH,bi_mul_small(WIDE_NINTH,3))
    EXPECTED_TWELFTH=bi_sub(EXPECTED_TWELFTH,bi_mul_small(WIDE_EIGHTH,4))
    EXPECTED_TWELFTH=bi_sub(EXPECTED_TWELFTH,bi_mul_small(WIDE_SEVENTH,5))
    EXPECTED_TWELFTH=bi_sub(EXPECTED_TWELFTH,bi_mul_small(WIDE_SIXTH,6))
    EXPECTED_TWELFTH=bi_sub(EXPECTED_TWELFTH,bi_mul_small(WIDE_FIFTH,7))
    EXPECTED_TWELFTH=bi_sub(EXPECTED_TWELFTH,bi_mul_small(WIDE_FOURTH,8))
    EXPECTED_TWELFTH=bi_sub(EXPECTED_TWELFTH,bi_mul_small(WIDE_CUBE,9))
    EXPECTED_TWELFTH=bi_sub(EXPECTED_TWELFTH,bi_mul_small(WIDE_SQUARE,10))
    EXPECTED_TWELFTH=bi_sub(EXPECTED_TWELFTH,bi_mul_small(M,11))
    EXPECTED_TWELFTH=bi_sub(EXPECTED_TWELFTH,"12")
    expect_exact("wide original twelfth twelve-digit boundary", CHOSEN_RANK, EXPECTED_TWELFTH)

    WIDE_N=bi_add(WIDE_TWELFTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original twelfth+1 thirteen-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=bi_sub(WIDE_TWELFTH,bi_mul_small(WIDE_ELEVENTH,11))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_TENTH,10))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_NINTH,9))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_EIGHTH,8))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SEVENTH,7))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SIXTH,6))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FIFTH,5))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FOURTH,4))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_CUBE,3))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SQUARE,2))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(M,2))
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"13")
    expect_exact("wide original twelfth+1 thirteen-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_mul_small(WIDE_ELEVENTH,10)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_TENTH,9))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_NINTH,8))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_EIGHTH,7))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SEVENTH,6))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SIXTH,5))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FIFTH,4))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FOURTH,3))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_CUBE,2))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SQUARE,1))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,M)
    EXPECTED_WRAP=bi_sub(EXPECTED_WRAP,"11")
    expect_exact("wide original twelfth+1 thirteen-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)

    # Thirteen-digit to fourteen-digit transition at original M=2^127-1.
    # N=M^13 fits thirteen base-M digits; N=M^13+1 needs fourteen.
    # Four expected ranks independently checked with arbitrary-precision integers.
    WIDE_THIRTEENTH=bi_mul(WIDE_TWELFTH,M)
    STREAM_FIRST=bi_sub(M,"13"); STREAM_STEP=1
    choose_rank_wide(WIDE_THIRTEENTH)
    EXPECTED_THIRTEENTH=bi_sub(WIDE_THIRTEENTH,WIDE_TWELFTH)
    EXPECTED_THIRTEENTH=bi_sub(EXPECTED_THIRTEENTH,bi_mul_small(WIDE_ELEVENTH,2))
    EXPECTED_THIRTEENTH=bi_sub(EXPECTED_THIRTEENTH,bi_mul_small(WIDE_TENTH,3))
    EXPECTED_THIRTEENTH=bi_sub(EXPECTED_THIRTEENTH,bi_mul_small(WIDE_NINTH,4))
    EXPECTED_THIRTEENTH=bi_sub(EXPECTED_THIRTEENTH,bi_mul_small(WIDE_EIGHTH,5))
    EXPECTED_THIRTEENTH=bi_sub(EXPECTED_THIRTEENTH,bi_mul_small(WIDE_SEVENTH,6))
    EXPECTED_THIRTEENTH=bi_sub(EXPECTED_THIRTEENTH,bi_mul_small(WIDE_SIXTH,7))
    EXPECTED_THIRTEENTH=bi_sub(EXPECTED_THIRTEENTH,bi_mul_small(WIDE_FIFTH,8))
    EXPECTED_THIRTEENTH=bi_sub(EXPECTED_THIRTEENTH,bi_mul_small(WIDE_FOURTH,9))
    EXPECTED_THIRTEENTH=bi_sub(EXPECTED_THIRTEENTH,bi_mul_small(WIDE_CUBE,10))
    EXPECTED_THIRTEENTH=bi_sub(EXPECTED_THIRTEENTH,bi_mul_small(WIDE_SQUARE,11))
    EXPECTED_THIRTEENTH=bi_sub(EXPECTED_THIRTEENTH,bi_mul_small(M,12))
    EXPECTED_THIRTEENTH=bi_sub(EXPECTED_THIRTEENTH,"13")
    expect_exact("wide original thirteenth thirteen-digit boundary", CHOSEN_RANK, EXPECTED_THIRTEENTH)

    WIDE_N=bi_add(WIDE_THIRTEENTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original thirteenth+1 fourteen-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=bi_sub(WIDE_THIRTEENTH,bi_mul_small(WIDE_TWELFTH,12))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_ELEVENTH,11))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_TENTH,10))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_NINTH,9))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_EIGHTH,8))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SEVENTH,7))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SIXTH,6))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FIFTH,5))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FOURTH,4))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_CUBE,3))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SQUARE,2))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(M,2))
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"14")
    expect_exact("wide original thirteenth+1 fourteen-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_mul_small(WIDE_TWELFTH,11)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_ELEVENTH,10))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_TENTH,9))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_NINTH,8))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_EIGHTH,7))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SEVENTH,6))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SIXTH,5))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FIFTH,4))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FOURTH,3))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_CUBE,2))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,WIDE_SQUARE)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,M)
    EXPECTED_WRAP=bi_sub(EXPECTED_WRAP,"12")
    expect_exact("wide original thirteenth+1 fourteen-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)

    # Fourteen-digit to fifteen-digit transition at original M=2^127-1.
    # N=M^14 fits fourteen base-M digits; N=M^14+1 needs fifteen.
    # Four ranks cross-checked with independent BigInt arithmetic.
    WIDE_FOURTEENTH=bi_mul(WIDE_THIRTEENTH,M)
    STREAM_FIRST=bi_sub(M,"14"); STREAM_STEP=1
    choose_rank_wide(WIDE_FOURTEENTH)
    EXPECTED_FOURTEENTH=bi_sub(WIDE_FOURTEENTH,WIDE_THIRTEENTH)
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,bi_mul_small(WIDE_TWELFTH,2))
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,bi_mul_small(WIDE_ELEVENTH,3))
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,bi_mul_small(WIDE_TENTH,4))
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,bi_mul_small(WIDE_NINTH,5))
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,bi_mul_small(WIDE_EIGHTH,6))
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,bi_mul_small(WIDE_SEVENTH,7))
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,bi_mul_small(WIDE_SIXTH,8))
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,bi_mul_small(WIDE_FIFTH,9))
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,bi_mul_small(WIDE_FOURTH,10))
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,bi_mul_small(WIDE_CUBE,11))
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,bi_mul_small(WIDE_SQUARE,12))
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,bi_mul_small(M,13))
    EXPECTED_FOURTEENTH=bi_sub(EXPECTED_FOURTEENTH,"14")
    expect_exact("wide original fourteenth fourteen-digit boundary", CHOSEN_RANK, EXPECTED_FOURTEENTH)

    WIDE_N=bi_add(WIDE_FOURTEENTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original fourteenth+1 fifteen-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=bi_sub(WIDE_FOURTEENTH,bi_mul_small(WIDE_THIRTEENTH,13))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_TWELFTH,12))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_ELEVENTH,11))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_TENTH,10))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_NINTH,9))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_EIGHTH,8))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SEVENTH,7))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SIXTH,6))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FIFTH,5))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FOURTH,4))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_CUBE,3))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SQUARE,2))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(M,2))
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"15")
    expect_exact("wide original fourteenth+1 fifteen-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_mul_small(WIDE_THIRTEENTH,12)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_TWELFTH,11))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_ELEVENTH,10))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_TENTH,9))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_NINTH,8))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_EIGHTH,7))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SEVENTH,6))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SIXTH,5))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FIFTH,4))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FOURTH,3))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_CUBE,2))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SQUARE,1))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,M)
    EXPECTED_WRAP=bi_sub(EXPECTED_WRAP,"13")
    expect_exact("wide original fourteenth+1 fifteen-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)

    # Fifteen-digit to sixteen-digit transition, original M = 2^127 - 1.
    # Independently evaluated 4 bounded BigInt ranks; no production oracle changes.
    WIDE_FIFTEENTH=bi_mul(WIDE_FOURTEENTH,M)
    STREAM_FIRST=bi_sub(M,"15"); STREAM_STEP=1
    choose_rank_wide(WIDE_FIFTEENTH)
    EXPECTED_FIFTEENTH=bi_sub(WIDE_FIFTEENTH,WIDE_FOURTEENTH)
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(WIDE_THIRTEENTH,2))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(WIDE_TWELFTH,3))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(WIDE_ELEVENTH,4))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(WIDE_TENTH,5))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(WIDE_NINTH,6))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(WIDE_EIGHTH,7))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(WIDE_SEVENTH,8))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(WIDE_SIXTH,9))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(WIDE_FIFTH,10))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(WIDE_FOURTH,11))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(WIDE_CUBE,12))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(WIDE_SQUARE,13))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,bi_mul_small(M,14))
    EXPECTED_FIFTEENTH=bi_sub(EXPECTED_FIFTEENTH,"15")
    expect_exact("wide original fifteenth fifteen-digit boundary", CHOSEN_RANK, EXPECTED_FIFTEENTH)
    WIDE_N=bi_add(WIDE_FIFTEENTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original fifteenth+1 sixteen-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=bi_sub(WIDE_FIFTEENTH,bi_mul_small(WIDE_FOURTEENTH,14))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_THIRTEENTH,13))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_TWELFTH,12))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_ELEVENTH,11))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_TENTH,10))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_NINTH,9))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_EIGHTH,8))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SEVENTH,7))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SIXTH,6))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FIFTH,5))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_FOURTH,4))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_CUBE,3))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(WIDE_SQUARE,2))
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(M,2))
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"16")
    expect_exact("wide original fifteenth+1 sixteen-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_mul_small(WIDE_FOURTEENTH,13)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_THIRTEENTH,12))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_TWELFTH,11))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_ELEVENTH,10))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_TENTH,9))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_NINTH,8))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_EIGHTH,7))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SEVENTH,6))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_SIXTH,5))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FIFTH,4))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_FOURTH,3))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(WIDE_CUBE,2))
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,WIDE_SQUARE)
    EXPECTED_WRAP=bi_add(EXPECTED_WRAP,M)
    EXPECTED_WRAP=bi_sub(EXPECTED_WRAP,"14")
    expect_exact("wide original fifteenth+1 sixteen-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)

    # Sixteen-digit to seventeen-digit transition at original M=2^127-1.
    # All four expected ranks independently checked with direct 127-bit BigInt
    # positional expansion: boundary, rejection, backward, and forward wrap.
    WIDE_SIXTEENTH=bi_mul(WIDE_FIFTEENTH,M)
    STREAM_FIRST=bi_sub(M,"16"); STREAM_STEP=1
    choose_rank_wide(WIDE_SIXTEENTH)
    EXPECTED_SIXTEENTH=WIDE_SIXTEENTH
    QA_POWER="1"
    for (QA_I=0;QA_I<16;QA_I++) {
        EXPECTED_SIXTEENTH=bi_sub(EXPECTED_SIXTEENTH,bi_mul_small(QA_POWER,16-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original sixteenth sixteen-digit boundary", CHOSEN_RANK, EXPECTED_SIXTEENTH)

    WIDE_N=bi_add(WIDE_SIXTEENTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original sixteenth+1 seventeen-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_SIXTEENTH
    QA_POWER=M
    for (QA_I=1;QA_I<16;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"17")
    expect_exact("wide original sixteenth+1 seventeen-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"15")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<16;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original sixteenth+1 seventeen-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)

    # Seventeen-digit to eighteen-digit transition at original M=2^127-1.
    # Independent direct BigInt positional checks: 4/4 agree with these
    # expected ranks; production oracle and previous test cases are unchanged.
    WIDE_SEVENTEENTH=bi_mul(WIDE_SIXTEENTH,M)
    STREAM_FIRST=bi_sub(M,"17"); STREAM_STEP=1
    choose_rank_wide(WIDE_SEVENTEENTH)
    EXPECTED_SEVENTEENTH=WIDE_SEVENTEENTH
    QA_POWER="1"
    for (QA_I=0;QA_I<17;QA_I++) {
        EXPECTED_SEVENTEENTH=bi_sub(EXPECTED_SEVENTEENTH,bi_mul_small(QA_POWER,17-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original seventeenth seventeen-digit boundary", CHOSEN_RANK, EXPECTED_SEVENTEENTH)

    WIDE_N=bi_add(WIDE_SEVENTEENTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original seventeenth+1 eighteen-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_SEVENTEENTH
    QA_POWER=M
    for (QA_I=1;QA_I<17;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"18")
    expect_exact("wide original seventeenth+1 eighteen-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"16")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<17;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original seventeenth+1 eighteen-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)

    # Eighteen-digit to nineteen-digit transition at original M=2^127-1.
    # Four independently verified 127-bit BigInt positional ranks:
    # boundary, forward rejection, backward acceptance, forward wrap.
    WIDE_EIGHTEENTH=bi_mul(WIDE_SEVENTEENTH,M)
    STREAM_FIRST=bi_sub(M,"18"); STREAM_STEP=1
    choose_rank_wide(WIDE_EIGHTEENTH)
    EXPECTED_EIGHTEENTH=WIDE_EIGHTEENTH
    QA_POWER="1"
    for (QA_I=0;QA_I<18;QA_I++) {
        EXPECTED_EIGHTEENTH=bi_sub(EXPECTED_EIGHTEENTH,bi_mul_small(QA_POWER,18-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original eighteenth eighteen-digit boundary", CHOSEN_RANK, EXPECTED_EIGHTEENTH)

    WIDE_N=bi_add(WIDE_EIGHTEENTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original eighteenth+1 nineteen-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_EIGHTEENTH
    QA_POWER=M
    for (QA_I=1;QA_I<18;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"19")
    expect_exact("wide original eighteenth+1 nineteen-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"17")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<18;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original eighteenth+1 nineteen-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Nineteen-digit to twenty-digit transition at original M=2^127-1.
    # Independent positional BigInt witnesses: boundary, forward rejection,
    # backward acceptance, and forward wrap (4/4 verified before commit).
    WIDE_NINETEENTH=bi_mul(WIDE_EIGHTEENTH,M)
    STREAM_FIRST=bi_sub(M,"19"); STREAM_STEP=1
    choose_rank_wide(WIDE_NINETEENTH)
    EXPECTED_NINETEENTH=WIDE_NINETEENTH
    QA_POWER="1"
    for (QA_I=0;QA_I<19;QA_I++) {
        EXPECTED_NINETEENTH=bi_sub(EXPECTED_NINETEENTH,bi_mul_small(QA_POWER,19-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original nineteenth nineteen-digit boundary", CHOSEN_RANK, EXPECTED_NINETEENTH)

    WIDE_N=bi_add(WIDE_NINETEENTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original nineteenth+1 twenty-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_NINETEENTH
    QA_POWER=M
    for (QA_I=1;QA_I<19;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"20")
    expect_exact("wide original nineteenth+1 twenty-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"18")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<19;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original nineteenth+1 twenty-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Twenty-digit to twenty-one-digit transition at original M=2^127-1.
    # All four ranks cross-checked with independent direct BigInt positional oracle.
    WIDE_TWENTIETH=bi_mul(WIDE_NINETEENTH,M)
    STREAM_FIRST=bi_sub(M,"20"); STREAM_STEP=1
    choose_rank_wide(WIDE_TWENTIETH)
    EXPECTED_TWENTIETH=WIDE_TWENTIETH
    QA_POWER="1"
    for (QA_I=0;QA_I<20;QA_I++) {
        EXPECTED_TWENTIETH=bi_sub(EXPECTED_TWENTIETH,bi_mul_small(QA_POWER,20-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twentieth twenty-digit boundary", CHOSEN_RANK, EXPECTED_TWENTIETH)

    WIDE_N=bi_add(WIDE_TWENTIETH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original twentieth+1 twenty-one-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_TWENTIETH
    QA_POWER=M
    for (QA_I=1;QA_I<20;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"21")
    expect_exact("wide original twentieth+1 twenty-one-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"19")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<20;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twentieth+1 twenty-one-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Twenty-one-digit to twenty-two-digit transition, M = 2^127 - 1.
    # Four independent 127-bit BigInt positional witnesses verified before edit:
    # boundary, forward rejection, backward acceptance, and forward wrap.
    WIDE_TWENTY_FIRST=bi_mul(WIDE_TWENTIETH,M)
    STREAM_FIRST=bi_sub(M,"21"); STREAM_STEP=1
    choose_rank_wide(WIDE_TWENTY_FIRST)
    EXPECTED_TWENTY_FIRST=WIDE_TWENTY_FIRST
    QA_POWER="1"
    for (QA_I=0;QA_I<21;QA_I++) {
        EXPECTED_TWENTY_FIRST=bi_sub(EXPECTED_TWENTY_FIRST,bi_mul_small(QA_POWER,21-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-first twenty-one-digit boundary", CHOSEN_RANK, EXPECTED_TWENTY_FIRST)

    WIDE_N=bi_add(WIDE_TWENTY_FIRST,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original twenty-first+1 twenty-two-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_TWENTY_FIRST
    QA_POWER=M
    for (QA_I=1;QA_I<21;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"22")
    expect_exact("wide original twenty-first+1 twenty-two-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"20")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<21;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-first+1 twenty-two-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Twenty-two-digit to twenty-three-digit transition at original M=2^127-1.
    # Independently checked direct BigInt witnesses (4/4):
    # boundary, forward rejection, backward acceptance, and forward wrap.
    WIDE_TWENTY_SECOND=bi_mul(WIDE_TWENTY_FIRST,M)
    STREAM_FIRST=bi_sub(M,"22"); STREAM_STEP=1
    choose_rank_wide(WIDE_TWENTY_SECOND)
    EXPECTED_TWENTY_SECOND=WIDE_TWENTY_SECOND
    QA_POWER="1"
    for (QA_I=0;QA_I<22;QA_I++) {
        EXPECTED_TWENTY_SECOND=bi_sub(EXPECTED_TWENTY_SECOND,bi_mul_small(QA_POWER,22-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-second twenty-two-digit boundary", CHOSEN_RANK, EXPECTED_TWENTY_SECOND)

    WIDE_N=bi_add(WIDE_TWENTY_SECOND,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original twenty-second+1 twenty-three-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_TWENTY_SECOND
    QA_POWER=M
    for (QA_I=1;QA_I<22;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"23")
    expect_exact("wide original twenty-second+1 twenty-three-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"21")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<22;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-second+1 twenty-three-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Twenty-three-digit to twenty-four-digit transition at original M=2^127-1.
    # Four independent direct positional BigInt witnesses (4/4):
    # boundary, forward rejection, backward acceptance, and forward wrap.
    WIDE_TWENTY_THIRD=bi_mul(WIDE_TWENTY_SECOND,M)
    STREAM_FIRST=bi_sub(M,"23"); STREAM_STEP=1
    choose_rank_wide(WIDE_TWENTY_THIRD)
    EXPECTED_TWENTY_THIRD=WIDE_TWENTY_THIRD
    QA_POWER="1"
    for (QA_I=0;QA_I<23;QA_I++) {
        EXPECTED_TWENTY_THIRD=bi_sub(EXPECTED_TWENTY_THIRD,bi_mul_small(QA_POWER,23-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-third twenty-three-digit boundary", CHOSEN_RANK, EXPECTED_TWENTY_THIRD)

    WIDE_N=bi_add(WIDE_TWENTY_THIRD,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original twenty-third+1 twenty-four-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_TWENTY_THIRD
    QA_POWER=M
    for (QA_I=1;QA_I<23;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"24")
    expect_exact("wide original twenty-third+1 twenty-four-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"22")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<23;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-third+1 twenty-four-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Twenty-four-digit to twenty-five-digit transition at original M=2^127-1.
    # Four results cross-checked against independent direct positional BigInt oracle.
    WIDE_TWENTY_FOURTH=bi_mul(WIDE_TWENTY_THIRD,M)
    STREAM_FIRST=bi_sub(M,"24"); STREAM_STEP=1
    choose_rank_wide(WIDE_TWENTY_FOURTH)
    EXPECTED_TWENTY_FOURTH=WIDE_TWENTY_FOURTH
    QA_POWER="1"
    for (QA_I=0;QA_I<24;QA_I++) {
        EXPECTED_TWENTY_FOURTH=bi_sub(EXPECTED_TWENTY_FOURTH,bi_mul_small(QA_POWER,24-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-fourth twenty-four-digit boundary", CHOSEN_RANK, EXPECTED_TWENTY_FOURTH)

    WIDE_N=bi_add(WIDE_TWENTY_FOURTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original twenty-fourth+1 twenty-five-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_TWENTY_FOURTH
    QA_POWER=M
    for (QA_I=1;QA_I<24;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"25")
    expect_exact("wide original twenty-fourth+1 twenty-five-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"23")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<24;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-fourth+1 twenty-five-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)

    # Twenty-five-digit to twenty-six-digit transition, M = 2^127 - 1.
    # Independent direct positional BigInt witnesses (4/4 verified):
    # boundary, forward rejection, backward acceptance, forward wrap.
    WIDE_TWENTY_FIFTH=bi_mul(WIDE_TWENTY_FOURTH,M)
    STREAM_FIRST=bi_sub(M,"25"); STREAM_STEP=1
    choose_rank_wide(WIDE_TWENTY_FIFTH)
    EXPECTED_TWENTY_FIFTH=WIDE_TWENTY_FIFTH
    QA_POWER="1"
    for (QA_I=0;QA_I<25;QA_I++) {
        EXPECTED_TWENTY_FIFTH=bi_sub(EXPECTED_TWENTY_FIFTH,bi_mul_small(QA_POWER,25-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-fifth twenty-five-digit boundary", CHOSEN_RANK, EXPECTED_TWENTY_FIFTH)

    WIDE_N=bi_add(WIDE_TWENTY_FIFTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original twenty-fifth+1 twenty-six-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_TWENTY_FIFTH
    QA_POWER=M
    for (QA_I=1;QA_I<25;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"26")
    expect_exact("wide original twenty-fifth+1 twenty-six-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"24")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<25;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-fifth+1 twenty-six-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Twenty-six-digit to twenty-seven-digit transition, M = 2^127 - 1.
    # Independently checked direct positional BigInt witnesses (4/4):
    # 995-digit boundary, forward rejection, 995-digit backward
    # acceptance, and 958-digit forward wrap (27 digit draws).
    WIDE_TWENTY_SIXTH=bi_mul(WIDE_TWENTY_FIFTH,M)
    STREAM_FIRST=bi_sub(M,"26"); STREAM_STEP=1
    choose_rank_wide(WIDE_TWENTY_SIXTH)
    EXPECTED_TWENTY_SIXTH=WIDE_TWENTY_SIXTH
    QA_POWER="1"
    for (QA_I=0;QA_I<26;QA_I++) {
        EXPECTED_TWENTY_SIXTH=bi_sub(EXPECTED_TWENTY_SIXTH,bi_mul_small(QA_POWER,26-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-sixth twenty-six-digit boundary", CHOSEN_RANK, EXPECTED_TWENTY_SIXTH)

    WIDE_N=bi_add(WIDE_TWENTY_SIXTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original twenty-sixth+1 twenty-seven-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_TWENTY_SIXTH
    QA_POWER=M
    for (QA_I=1;QA_I<26;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"27")
    expect_exact("wide original twenty-sixth+1 twenty-seven-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"25")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<26;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-sixth+1 twenty-seven-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Twenty-seven-digit to twenty-eight-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt preflight: 4/4 witnesses verified.
    # Boundary and backward acceptance are 1033 decimal digits; wrap is 996.
    WIDE_TWENTY_SEVENTH=bi_mul(WIDE_TWENTY_SIXTH,M)
    STREAM_FIRST=bi_sub(M,"27"); STREAM_STEP=1
    choose_rank_wide(WIDE_TWENTY_SEVENTH)
    EXPECTED_TWENTY_SEVENTH=WIDE_TWENTY_SEVENTH
    QA_POWER="1"
    for (QA_I=0;QA_I<27;QA_I++) {
        EXPECTED_TWENTY_SEVENTH=bi_sub(EXPECTED_TWENTY_SEVENTH,bi_mul_small(QA_POWER,27-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-seventh twenty-seven-digit boundary", CHOSEN_RANK, EXPECTED_TWENTY_SEVENTH)

    WIDE_N=bi_add(WIDE_TWENTY_SEVENTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original twenty-seventh+1 twenty-eight-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_TWENTY_SEVENTH
    QA_POWER=M
    for (QA_I=1;QA_I<27;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"28")
    expect_exact("wide original twenty-seventh+1 twenty-eight-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"26")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<27;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-seventh+1 twenty-eight-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)

    # Twenty-eight-digit to twenty-nine-digit transition, M = 2^127 - 1.
    # Independently checked direct positional BigInt witnesses (4/4):
    # boundary/backward acceptance 1071 decimal digits; wrap 1034.
    WIDE_TWENTY_EIGHTH=bi_mul(WIDE_TWENTY_SEVENTH,M)
    STREAM_FIRST=bi_sub(M,"28"); STREAM_STEP=1
    choose_rank_wide(WIDE_TWENTY_EIGHTH)
    EXPECTED_TWENTY_EIGHTH=WIDE_TWENTY_EIGHTH
    QA_POWER="1"
    for (QA_I=0;QA_I<28;QA_I++) {
        EXPECTED_TWENTY_EIGHTH=bi_sub(EXPECTED_TWENTY_EIGHTH,bi_mul_small(QA_POWER,28-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-eighth twenty-eight-digit boundary", CHOSEN_RANK, EXPECTED_TWENTY_EIGHTH)

    WIDE_N=bi_add(WIDE_TWENTY_EIGHTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original twenty-eighth+1 twenty-nine-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_TWENTY_EIGHTH
    QA_POWER=M
    for (QA_I=1;QA_I<28;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"29")
    expect_exact("wide original twenty-eighth+1 twenty-nine-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"27")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<28;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-eighth+1 twenty-nine-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Twenty-nine-digit to thirty-digit transition, M = 2^127 - 1.
    # Four independently checked direct positional BigInt witnesses (4/4):
    # boundary/backward acceptance 1109 decimal digits; forward wrap 1072.
    WIDE_TWENTY_NINTH=bi_mul(WIDE_TWENTY_EIGHTH,M)
    STREAM_FIRST=bi_sub(M,"29"); STREAM_STEP=1
    choose_rank_wide(WIDE_TWENTY_NINTH)
    EXPECTED_TWENTY_NINTH=WIDE_TWENTY_NINTH
    QA_POWER="1"
    for (QA_I=0;QA_I<29;QA_I++) {
        EXPECTED_TWENTY_NINTH=bi_sub(EXPECTED_TWENTY_NINTH,bi_mul_small(QA_POWER,29-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-ninth twenty-nine-digit boundary", CHOSEN_RANK, EXPECTED_TWENTY_NINTH)

    WIDE_N=bi_add(WIDE_TWENTY_NINTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original twenty-ninth+1 thirty-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_TWENTY_NINTH
    QA_POWER=M
    for (QA_I=1;QA_I<29;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"30")
    expect_exact("wide original twenty-ninth+1 thirty-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"28")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<29;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original twenty-ninth+1 thirty-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)



    # Thirty-digit to thirty-one-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt oracle checked 4/4:
    # boundary/backward acceptance 1147 decimal digits; forward wrap 1111.
    WIDE_THIRTIETH=bi_mul(WIDE_TWENTY_NINTH,M)
    STREAM_FIRST=bi_sub(M,"30"); STREAM_STEP=1
    choose_rank_wide(WIDE_THIRTIETH)
    EXPECTED_THIRTIETH=WIDE_THIRTIETH
    QA_POWER="1"
    for (QA_I=0;QA_I<30;QA_I++) {
        EXPECTED_THIRTIETH=bi_sub(EXPECTED_THIRTIETH,bi_mul_small(QA_POWER,30-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirtieth thirty-digit boundary", CHOSEN_RANK, EXPECTED_THIRTIETH)

    WIDE_N=bi_add(WIDE_THIRTIETH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original thirtieth+1 thirty-one-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_THIRTIETH
    QA_POWER=M
    for (QA_I=1;QA_I<30;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"31")
    expect_exact("wide original thirtieth+1 thirty-one-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"29")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<30;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirtieth+1 thirty-one-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)

    # Thirty-one-digit to thirty-two-digit transition, M = 2^127 - 1.
    # Independently checked direct-positional BigInt witnesses (4/4):
    # boundary and backward acceptance 1186 digits; forward wrap 1149.
    WIDE_THIRTY_FIRST=bi_mul(WIDE_THIRTIETH,M)
    STREAM_FIRST=bi_sub(M,"31"); STREAM_STEP=1
    choose_rank_wide(WIDE_THIRTY_FIRST)
    EXPECTED_THIRTY_FIRST=WIDE_THIRTY_FIRST
    QA_POWER="1"
    for (QA_I=0;QA_I<31;QA_I++) {
        EXPECTED_THIRTY_FIRST=bi_sub(EXPECTED_THIRTY_FIRST,bi_mul_small(QA_POWER,31-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-first thirty-one-digit boundary", CHOSEN_RANK, EXPECTED_THIRTY_FIRST)

    WIDE_N=bi_add(WIDE_THIRTY_FIRST,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original thirty-first+1 thirty-two-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_THIRTY_FIRST
    QA_POWER=M
    for (QA_I=1;QA_I<31;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"32")
    expect_exact("wide original thirty-first+1 thirty-two-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"30")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<31;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-first+1 thirty-two-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Thirty-two-digit to thirty-three-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt witnesses (4/4):
    # boundary/backward acceptance 1224 decimal digits; wrap 1187.
    WIDE_THIRTY_SECOND=bi_mul(WIDE_THIRTY_FIRST,M)
    STREAM_FIRST=bi_sub(M,"32"); STREAM_STEP=1
    choose_rank_wide(WIDE_THIRTY_SECOND)
    EXPECTED_THIRTY_SECOND=WIDE_THIRTY_SECOND
    QA_POWER="1"
    for (QA_I=0;QA_I<32;QA_I++) {
        EXPECTED_THIRTY_SECOND=bi_sub(EXPECTED_THIRTY_SECOND,bi_mul_small(QA_POWER,32-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-second thirty-two-digit boundary", CHOSEN_RANK, EXPECTED_THIRTY_SECOND)

    WIDE_N=bi_add(WIDE_THIRTY_SECOND,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original thirty-second+1 thirty-three-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_THIRTY_SECOND
    QA_POWER=M
    for (QA_I=1;QA_I<32;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"33")
    expect_exact("wide original thirty-second+1 thirty-three-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"31")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<32;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-second+1 thirty-three-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Thirty-three-digit to thirty-four-digit transition, M = 2^127 - 1.
    # Direct positional BigInt oracle independently verified 4/4:
    # boundary/backward acceptance 1262 decimal digits; forward wrap 1225.
    WIDE_THIRTY_THIRD=bi_mul(WIDE_THIRTY_SECOND,M)
    STREAM_FIRST=bi_sub(M,"33"); STREAM_STEP=1
    choose_rank_wide(WIDE_THIRTY_THIRD)
    EXPECTED_THIRTY_THIRD=WIDE_THIRTY_THIRD
    QA_POWER="1"
    for (QA_I=0;QA_I<33;QA_I++) {
        EXPECTED_THIRTY_THIRD=bi_sub(EXPECTED_THIRTY_THIRD,bi_mul_small(QA_POWER,33-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-third thirty-three-digit boundary", CHOSEN_RANK, EXPECTED_THIRTY_THIRD)

    WIDE_N=bi_add(WIDE_THIRTY_THIRD,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original thirty-third+1 thirty-four-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_THIRTY_THIRD
    QA_POWER=M
    for (QA_I=1;QA_I<33;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"34")
    expect_exact("wide original thirty-third+1 thirty-four-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"32")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<33;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-third+1 thirty-four-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Thirty-four-digit to thirty-five-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt witnesses checked 4/4:
    # boundary/backward acceptance 1300 decimal digits; forward wrap 1264.
    WIDE_THIRTY_FOURTH=bi_mul(WIDE_THIRTY_THIRD,M)
    STREAM_FIRST=bi_sub(M,"34"); STREAM_STEP=1
    choose_rank_wide(WIDE_THIRTY_FOURTH)
    EXPECTED_THIRTY_FOURTH=WIDE_THIRTY_FOURTH
    QA_POWER="1"
    for (QA_I=0;QA_I<34;QA_I++) {
        EXPECTED_THIRTY_FOURTH=bi_sub(EXPECTED_THIRTY_FOURTH,bi_mul_small(QA_POWER,34-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-fourth thirty-four-digit boundary", CHOSEN_RANK, EXPECTED_THIRTY_FOURTH)

    WIDE_N=bi_add(WIDE_THIRTY_FOURTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original thirty-fourth+1 thirty-five-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_THIRTY_FOURTH
    QA_POWER=M
    for (QA_I=1;QA_I<34;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"35")
    expect_exact("wide original thirty-fourth+1 thirty-five-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"33")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<34;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-fourth+1 thirty-five-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Thirty-five-digit to thirty-six-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt witnesses checked 4/4:
    # boundary/backward acceptance 1339 decimal digits; forward wrap 1302.
    WIDE_THIRTY_FIFTH=bi_mul(WIDE_THIRTY_FOURTH,M)
    STREAM_FIRST=bi_sub(M,"35"); STREAM_STEP=1
    choose_rank_wide(WIDE_THIRTY_FIFTH)
    EXPECTED_THIRTY_FIFTH=WIDE_THIRTY_FIFTH
    QA_POWER="1"
    for (QA_I=0;QA_I<35;QA_I++) {
        EXPECTED_THIRTY_FIFTH=bi_sub(EXPECTED_THIRTY_FIFTH,bi_mul_small(QA_POWER,35-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-fifth thirty-five-digit boundary", CHOSEN_RANK, EXPECTED_THIRTY_FIFTH)

    WIDE_N=bi_add(WIDE_THIRTY_FIFTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original thirty-fifth+1 thirty-six-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_THIRTY_FIFTH
    QA_POWER=M
    for (QA_I=1;QA_I<35;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"36")
    expect_exact("wide original thirty-fifth+1 thirty-six-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"34")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<35;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-fifth+1 thirty-six-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Thirty-six-digit to thirty-seven-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt witnesses checked 4/4:
    # boundary/backward acceptance 1377 decimal digits; forward wrap 1340.
    WIDE_THIRTY_SIXTH=bi_mul(WIDE_THIRTY_FIFTH,M)
    STREAM_FIRST=bi_sub(M,"36"); STREAM_STEP=1
    choose_rank_wide(WIDE_THIRTY_SIXTH)
    EXPECTED_THIRTY_SIXTH=WIDE_THIRTY_SIXTH
    QA_POWER="1"
    for (QA_I=0;QA_I<36;QA_I++) {
        EXPECTED_THIRTY_SIXTH=bi_sub(EXPECTED_THIRTY_SIXTH,bi_mul_small(QA_POWER,36-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-sixth thirty-six-digit boundary", CHOSEN_RANK, EXPECTED_THIRTY_SIXTH)

    WIDE_N=bi_add(WIDE_THIRTY_SIXTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original thirty-sixth+1 thirty-seven-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_THIRTY_SIXTH
    QA_POWER=M
    for (QA_I=1;QA_I<36;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"37")
    expect_exact("wide original thirty-sixth+1 thirty-seven-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"35")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<36;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-sixth+1 thirty-seven-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Thirty-seven-digit to thirty-eight-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt witnesses checked 4/4:
    # boundary/backward acceptance 1415 decimal digits; forward wrap 1378.
    WIDE_THIRTY_SEVENTH=bi_mul(WIDE_THIRTY_SIXTH,M)
    STREAM_FIRST=bi_sub(M,"37"); STREAM_STEP=1
    choose_rank_wide(WIDE_THIRTY_SEVENTH)
    EXPECTED_THIRTY_SEVENTH=WIDE_THIRTY_SEVENTH
    QA_POWER="1"
    for (QA_I=0;QA_I<37;QA_I++) {
        EXPECTED_THIRTY_SEVENTH=bi_sub(EXPECTED_THIRTY_SEVENTH,bi_mul_small(QA_POWER,37-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-seventh thirty-seven-digit boundary", CHOSEN_RANK, EXPECTED_THIRTY_SEVENTH)

    WIDE_N=bi_add(WIDE_THIRTY_SEVENTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original thirty-seventh+1 thirty-eight-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_THIRTY_SEVENTH
    QA_POWER=M
    for (QA_I=1;QA_I<37;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"38")
    expect_exact("wide original thirty-seventh+1 thirty-eight-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"36")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<37;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-seventh+1 thirty-eight-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Thirty-eight-digit to thirty-nine-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt witnesses checked 4/4:
    # boundary/backward acceptance 1453 decimal digits; forward wrap 1417.
    WIDE_THIRTY_EIGHTH=bi_mul(WIDE_THIRTY_SEVENTH,M)
    STREAM_FIRST=bi_sub(M,"38"); STREAM_STEP=1
    choose_rank_wide(WIDE_THIRTY_EIGHTH)
    EXPECTED_THIRTY_EIGHTH=WIDE_THIRTY_EIGHTH
    QA_POWER="1"
    for (QA_I=0;QA_I<38;QA_I++) {
        EXPECTED_THIRTY_EIGHTH=bi_sub(EXPECTED_THIRTY_EIGHTH,bi_mul_small(QA_POWER,38-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-eighth thirty-eight-digit boundary", CHOSEN_RANK, EXPECTED_THIRTY_EIGHTH)

    WIDE_N=bi_add(WIDE_THIRTY_EIGHTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original thirty-eighth+1 thirty-nine-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_THIRTY_EIGHTH
    QA_POWER=M
    for (QA_I=1;QA_I<38;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"39")
    expect_exact("wide original thirty-eighth+1 thirty-nine-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"37")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<38;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-eighth+1 thirty-nine-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)

    # Thirty-nine-digit to forty-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt witnesses checked 4/4:
    # boundary/backward acceptance 1492 decimal digits; forward wrap 1455.
    WIDE_THIRTY_NINTH=bi_mul(WIDE_THIRTY_EIGHTH,M)
    STREAM_FIRST=bi_sub(M,"39"); STREAM_STEP=1
    choose_rank_wide(WIDE_THIRTY_NINTH)
    EXPECTED_THIRTY_NINTH=WIDE_THIRTY_NINTH
    QA_POWER="1"
    for (QA_I=0;QA_I<39;QA_I++) {
        EXPECTED_THIRTY_NINTH=bi_sub(EXPECTED_THIRTY_NINTH,bi_mul_small(QA_POWER,39-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-ninth thirty-nine-digit boundary", CHOSEN_RANK, EXPECTED_THIRTY_NINTH)

    WIDE_N=bi_add(WIDE_THIRTY_NINTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original thirty-ninth+1 forty-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_THIRTY_NINTH
    QA_POWER=M
    for (QA_I=1;QA_I<39;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"40")
    expect_exact("wide original thirty-ninth+1 forty-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"38")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<39;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original thirty-ninth+1 forty-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Forty-digit to forty-one-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt witnesses checked 4/4:
    # boundary/backward acceptance 1530 decimal digits; forward wrap 1493.
    WIDE_FORTIETH=bi_mul(WIDE_THIRTY_NINTH,M)
    STREAM_FIRST=bi_sub(M,"40"); STREAM_STEP=1
    choose_rank_wide(WIDE_FORTIETH)
    EXPECTED_FORTIETH=WIDE_FORTIETH
    QA_POWER="1"
    for (QA_I=0;QA_I<40;QA_I++) {
        EXPECTED_FORTIETH=bi_sub(EXPECTED_FORTIETH,bi_mul_small(QA_POWER,40-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original fortieth forty-digit boundary", CHOSEN_RANK, EXPECTED_FORTIETH)

    WIDE_N=bi_add(WIDE_FORTIETH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original fortieth+1 forty-one-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_FORTIETH
    QA_POWER=M
    for (QA_I=1;QA_I<40;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"41")
    expect_exact("wide original fortieth+1 forty-one-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"39")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<40;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original fortieth+1 forty-one-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Forty-one-digit to forty-two-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt witnesses checked 4/4:
    # boundary/backward acceptance 1568 decimal digits; forward wrap 1531.
    WIDE_FORTY_FIRST=bi_mul(WIDE_FORTIETH,M)
    STREAM_FIRST=bi_sub(M,"41"); STREAM_STEP=1
    choose_rank_wide(WIDE_FORTY_FIRST)
    EXPECTED_FORTY_FIRST=WIDE_FORTY_FIRST
    QA_POWER="1"
    for (QA_I=0;QA_I<41;QA_I++) {
        EXPECTED_FORTY_FIRST=bi_sub(EXPECTED_FORTY_FIRST,bi_mul_small(QA_POWER,41-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original forty-first forty-one-digit boundary", CHOSEN_RANK, EXPECTED_FORTY_FIRST)

    WIDE_N=bi_add(WIDE_FORTY_FIRST,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original forty-first+1 forty-two-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_FORTY_FIRST
    QA_POWER=M
    for (QA_I=1;QA_I<41;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"42")
    expect_exact("wide original forty-first+1 forty-two-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"40")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<41;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original forty-first+1 forty-two-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Forty-two-digit to forty-three-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt witnesses checked 4/4:
    # boundary/backward acceptance 1606 decimal digits; forward wrap 1570.
    WIDE_FORTY_SECOND=bi_mul(WIDE_FORTY_FIRST,M)
    STREAM_FIRST=bi_sub(M,"42"); STREAM_STEP=1
    choose_rank_wide(WIDE_FORTY_SECOND)
    EXPECTED_FORTY_SECOND=WIDE_FORTY_SECOND
    QA_POWER="1"
    for (QA_I=0;QA_I<42;QA_I++) {
        EXPECTED_FORTY_SECOND=bi_sub(EXPECTED_FORTY_SECOND,bi_mul_small(QA_POWER,42-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original forty-second forty-two-digit boundary", CHOSEN_RANK, EXPECTED_FORTY_SECOND)

    WIDE_N=bi_add(WIDE_FORTY_SECOND,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original forty-second+1 forty-three-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_FORTY_SECOND
    QA_POWER=M
    for (QA_I=1;QA_I<42;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"43")
    expect_exact("wide original forty-second+1 forty-three-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"41")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<42;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original forty-second+1 forty-three-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Forty-three-digit to forty-four-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt witnesses checked 4/4:
    # boundary/backward acceptance 1644 decimal digits; forward wrap 1608.
    WIDE_FORTY_THIRD=bi_mul(WIDE_FORTY_SECOND,M)
    STREAM_FIRST=bi_sub(M,"43"); STREAM_STEP=1
    choose_rank_wide(WIDE_FORTY_THIRD)
    EXPECTED_FORTY_THIRD=WIDE_FORTY_THIRD
    QA_POWER="1"
    for (QA_I=0;QA_I<43;QA_I++) {
        EXPECTED_FORTY_THIRD=bi_sub(EXPECTED_FORTY_THIRD,bi_mul_small(QA_POWER,43-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original forty-third forty-three-digit boundary", CHOSEN_RANK, EXPECTED_FORTY_THIRD)

    WIDE_N=bi_add(WIDE_FORTY_THIRD,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original forty-third+1 forty-four-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_FORTY_THIRD
    QA_POWER=M
    for (QA_I=1;QA_I<43;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"44")
    expect_exact("wide original forty-third+1 forty-four-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"42")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<43;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original forty-third+1 forty-four-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)


    # Forty-four-digit to forty-five-digit transition, M = 2^127 - 1.
    # Independent direct-positional BigInt witnesses checked 4/4:
    # boundary/backward acceptance 1683 decimal digits; forward wrap 1646.
    WIDE_FORTY_FOURTH=bi_mul(WIDE_FORTY_THIRD,M)
    STREAM_FIRST=bi_sub(M,"44"); STREAM_STEP=1
    choose_rank_wide(WIDE_FORTY_FOURTH)
    EXPECTED_FORTY_FOURTH=WIDE_FORTY_FOURTH
    QA_POWER="1"
    for (QA_I=0;QA_I<44;QA_I++) {
        EXPECTED_FORTY_FOURTH=bi_sub(EXPECTED_FORTY_FOURTH,bi_mul_small(QA_POWER,44-QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original forty-fourth forty-four-digit boundary", CHOSEN_RANK, EXPECTED_FORTY_FOURTH)

    WIDE_N=bi_add(WIDE_FORTY_FOURTH,"1")
    choose_rank_wide(WIDE_N)
    expect_exact("wide original forty-fourth+1 forty-five-digit forward rejection", CHOSEN_RANK, "1")
    STREAM_FIRST=M; STREAM_STEP=-1
    choose_rank_wide(WIDE_N)
    EXPECTED_BACK=WIDE_FORTY_FOURTH
    QA_POWER=M
    for (QA_I=1;QA_I<44;QA_I++) {
        EXPECTED_BACK=bi_sub(EXPECTED_BACK,bi_mul_small(QA_POWER,QA_I))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    EXPECTED_BACK=bi_sub(EXPECTED_BACK,M)
    EXPECTED_BACK=bi_add(EXPECTED_BACK,"45")
    expect_exact("wide original forty-fourth+1 forty-five-digit backward acceptance", CHOSEN_RANK, EXPECTED_BACK)
    STREAM_STEP=1
    choose_rank_wide(WIDE_N)
    EXPECTED_WRAP=bi_sub(M,"43")
    QA_POWER=bi_square(M)
    for (QA_I=2;QA_I<44;QA_I++) {
        EXPECTED_WRAP=bi_add(EXPECTED_WRAP,bi_mul_small(QA_POWER,QA_I-1))
        QA_POWER=bi_mul(QA_POWER,M)
    }
    expect_exact("wide original forty-fourth+1 forty-five-digit forward wrap", CHOSEN_RANK, EXPECTED_WRAP)

    if (FAILURES) {
        printf "FAIL: %d of %d AWK native boundary assertions\n", FAILURES, CASES
        exit 1
    }
    printf "PASS: %d AWK native boundary assertions\n", CASES
}
