# INT-02 unsigned exact wide expression primitive
PROJECT_ID=PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Parent=e22734931a9bbf09a7c92ba4fa5d0dec7b7ce483; forward source SHA256=0add0726ef80f160f73594eba50c246c0bdeb0a5f613e14b6baa23e2f5321aae.
CALENDAR-WIDE USING operation PIC X, left/right/output PIC X(96), status BINARY-SHORT UNSIGNED. Nonoverlapping buffers; two unsigned zero-padded ASCII operands; + or *. Status 0 exact result, 22 invalid operation/digit, 24 result >=10^96. Errors return 96 zero digits; inputs unchanged. No allocation or external oracle calls. Negative values intentionally excluded: source sauce expression operands are nonnegative; signed day offsets must be mapped to positive counts before entry.
Base 10^4, 24 limbs per operand, 48 accumulator limbs, full convolution before normalization. At most 576 products per multiply, 47 carry steps, each raw accumulator <=24*9999^2=2399520024, carry <240000; 12-digit packed accumulators fit. Overflow never silently truncates. Actual nonnegative sauce expressions have bounded operands near M=2^127-1; even z<=10M+1000 yields square <10^81, within 96 digits. This is a primitive, not complete sauce.
Independent direct BigInt oracle vs separate Number limb model: 1051/1051 MATCH, statuses {"0":702,"22":3,"24":346}. Native NOT_RUN. Source test harness supports identical corpus against actual COBOL driver and verifies input immutability, error reset, exit and stderr.
Compile/run only new scope:
```sh
cobc -x -free -Wall -Wstrict-typing -Wcall-params -Wlinkage -Wtruncate -Werror -o /tmp/int02-wide test/int02_wide_driver.cob src/calendar_wide.cob
timeout 300s node test/int02_wide_diff.mjs /tmp/int02-wide
```
Dedicated SAVE and candidate Native still outstanding. Canonical workflow unconditionally triggers on pushes and would repeat accepted stages; skip ci for this commit, no claim of Native. Next isolate dedicated execution, then source-locked sauce/gaps, seal-10 and integration. No Stage56/main/merge/release.
