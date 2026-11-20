with Ada.Numerics.Big_Numbers.Big_Integers;

--  QA-only isolated finite combinatorial month weave; NOT a calendar converter.
--  This package deliberately has no dependency on Normative_Oracle or other
--  original engine units. This is a bounded wide-rank synthetic correctness prototype.
package Legal_Month_Weave_DP is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   type Month_Lengths is array (Positive range <>) of Positive;
   type Month_Sequence is array (Positive range <>) of Positive;

   --  Original legal family: first and last occurrences of month labels
   --  each respect ascending label order. The two rails need not be fixed.
   --
   --  QA ONLY: 1..12 months, total days <= 256. These are safety limits of
   --  this standalone prototype and NOT the original calendar domain.
   function Count (Lengths : Month_Lengths) return Big_Integer;

   --  One-based global rank over the whole family. No per-day tickets.
   function Unrank
     (Lengths : Month_Lengths; Position : Big_Integer)
      return Month_Sequence;

   --  Exact inverse rank; rejects an illegal label sequence.
   function Rank
     (Lengths : Month_Lengths; Sequence : Month_Sequence)
      return Big_Integer;
end Legal_Month_Weave_DP;
