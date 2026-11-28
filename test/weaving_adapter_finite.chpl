// Research-only, checked, source-fresh finite differential driver.
use BigInteger;
use List;
use NormativeOracle;
config const casesInput = "";
proc csv(const ref values: list(int)): string {
  var s = "";
  for x in values {
    if s != "" then s += ",";
    s += x:string;
  }
  return s;
}
proc main() {
  if casesInput == "" then halt("Missing finite cases");
  var families = 0, checks = 0;
  for family in casesInput.split(";") {
    var counter: SparseWeavingCounter;
    for tok in family.split(",") do counter.lengths.pushBack(tok:int);
    const root = counter.countAll();
    writeln("ROOT=",family,";",root);
    for rank in 1..(root:int) {
      const r = new bigint(rank);
      const word = counter.unrank1(r);
      const inverse = counter.rank1(word);
      if inverse != r then halt("Finite inverse mismatch");
      writeln("WORD=",family,";",rank,";",csv(word),";",inverse);
      checks += 2;
    }
    families += 1;
  }
  if families != 137 || checks != 1982 then halt("Finite cardinality mismatch");
  writeln("FINITE_CHECKS=",checks);
}
