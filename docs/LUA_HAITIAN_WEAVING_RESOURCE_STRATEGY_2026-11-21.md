# Lua Haitian — 44–47 month weaving resource strategy

PROJECT_ID: **PC-BRANCH-LUA-HAITIAN**  
Authorized branch: **Lua+Kreyòl-ayisyen**  
Scope: QA and algorithm research only. No Stage56, production change, merge, main update, or release.

## 1. Frozen Native witness and current evidence

The completed exact-SHA run **44937649303** on **6be926b109073a3161c41446026b8dbc739a5364** produced this selected-year receipt in job **136947728718**:

- target day: **-15017676**
- year: **5000**
- candidate count/rank: **69 / 56**
- gate indices: **71..82**
- open/close gate days: **-15018117 / -15012823**
- year length: **5294** days

The same job passed the independent exact month-composition tests **486/486**. The normative month-count interval is **44..47**; the QA execution cap **16** is not a normative calendar rule. Artifact **14722360694** was downloaded and independently checked: ZIP SHA-256 matched the Actions log, ZIP CRC passed, 13 files were present, both Lua exit files were **0**, and both Lua stderr files were empty.

The new Native strategy probe reuses the frozen year receipt instead of repeating the expensive year-selection scan. It reproduces the month-count stream from O.sauce and the normative seals, then uses the independently verified inclusion-exclusion count and lexicographic unrank to recover the exact selected month-length vector. The normative recursive composition routine is differentially checked on bounded fixtures, but is deliberately not run for the 5294-day witness. The Python verifier independently recomputes the real vector from the rank and exact formula.

## 2. Proven lower bound for the existing memoized weaving DP

For month lengths \(n_1,\ldots,n_m\), the current O.makeWeavingCounter memo key contains (remaining, a, b), where a is the last opened month and b is the last closed month.

Consider the reachable slice after opening all months in order and before closing any month: a=m, b=0. For each month \(i\), emit any number \(k_i\) of additional interior occurrences with

\[
0\le k_i\le n_i-2.
\]

No month closes, because at least one occurrence remains. The resulting remaining count is

\[
r_i=n_i-1-k_i\in\{1,\ldots,n_i-1\}.
\]

Every vector \((r_1,\ldots,r_m)\) in that Cartesian product is reachable, and each gives a distinct memo key. Therefore the existing exhaustive recursive memoized counter must visit at least

\[
\boxed{\prod_{i=1}^{m}(n_i-1)}
\]

states, even before considering any other a,b slices. Since every normative month has at least 4 days,

\[
\prod_i(n_i-1)\ge 3^m\ge 3^{44}
=984770902183611232881.
\]

This is a lower bound on the current memoized algorithm, not a proof that every conceivable exact algorithm is impossible. It is sufficient to classify the current full-vector memo DP as resource-unsupported for this 44–47-month witness; it is not evidence that the year or date is invalid. The new probe computes the exact product for the actual selected vector without attempting to allocate or enumerate those states.

## 3. A second exact formulation for future algorithm work

Mark the first and last occurrence of every month. The first endpoints are necessarily O1,...,Om; the last endpoints are C1,...,Cm. Their interleaving is a ballot/Dyck path: every prefix has at least as many opens as closes. After each endpoint event, the active months form a contiguous interval \(A_g=[b+1,a]\).

For a fixed endpoint path, the gap between consecutive endpoints may contain any word over its active months. Its multivariate generating function is

\[
\frac{1}{1-\sum_{i\in A_g}x_i}.
\]

Thus the exact number of valid weavings has the representation

\[
W(n_1,\ldots,n_m)=
[x_1^{n_1-2}\cdots x_m^{n_m-2}]
\sum_{P\in\mathrm{Dyck}_m}
\prod_{g\in G(P)}
\frac{1}{1-\sum_{i\in A_g}x_i}.
\]

The new independent Python verifier evaluates this coefficient formulation on small domains and compares it with exhaustive multiset-word enumeration: **55/55 cases**. This validates the identity and supplies a separate mathematical route; it does **not** make the high-dimensional coefficient extraction efficient for 44–47 months. No real-witness weaving count or unrank is claimed.

## 4. Rank width

There are at least \(m!\) distinct valid weavings: open all months in order; place a fixed canonical sequence containing all but one interior occurrence from each month; permute one reserved interior occurrence per month; then close all months in order. Since \(n_i\ge4\), every month has at least two interior occurrences. For \(m\ge44\),

\[
m!>2^{127}-1=M.
\]

Therefore the normative chooseRank path must use chooseRankWide; the short-rank path is insufficient. This lower bound does not replace the exact total weaving count needed for uniform rank selection.

## 5. Measurable contract and acceptance boundaries

**Inputs**
- exact workflow SHA and the frozen year-selection receipt above;
- locked Git blobs for test/normative_oracle.lua, src/bigint.lua, src/source_language_catalog.lua, and the independent month-composition QA module;
- the exact month-count and month-length selection streams.

**Outputs**
- selected month count and exact month-length vector;
- exact composition count/rank and independent recomputation;
- exact memo-state lower bound \(\prod(n_i-1)\), minimum \(3^m\), and \(m!\) rank-width lower bound;
- explicit classification **NORMATIVE_FEASIBILITY=VALID** and **CURRENT_MEMO_DP=RESOURCE_UNSUPPORTED_FOR_WITNESS**.

**Independent oracles**
- Python math.comb inclusion-exclusion and lexicographic unrank for the real vector;
- endpoint-path coefficient extraction versus exhaustive multiset words on 55 small fixtures;
- exhaustive small-vector enumeration of the no-close state slice.

**Hard non-claims**
- The probe does not call buildYearStructure, makeWeavingCounter, chooseMonthWeaving, calendarDateIds, or calendarDate.
- It does not perform real-witness weaving, full-date conversion, or Stage56.
- It does not change the normative 47-month maximum or turn QA cap 16 into a validity condition.
- It does not replace the normative algorithm with an unproven approximation.

## 6. Next engineering target

Develop and prove a sparse/low-rank coefficient extraction and lexicographic unranking method for the endpoint-path generating function. It must reproduce the 55 small-domain oracle cases and mutation negatives before any real-witness execution. Until then, exact 44–47-month weaving remains resource-unsupported by the current memo DP, while the 5294-day year remains normatively feasible.
