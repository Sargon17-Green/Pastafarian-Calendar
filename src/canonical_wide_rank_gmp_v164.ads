with Ada.Numerics.Big_Numbers.Big_Integers;
with GNATCOLL.GMP.Integers;

--  QA ONLY: arbitrary-precision canonical rank chooser for month weaving.
--  No calendar date, Sauce or source-native converter is executed.
package Canonical_Wide_Rank_GMP_V164 is
   package Std renames Ada.Numerics.Big_Numbers.Big_Integers;
   package G renames GNATCOLL.GMP.Integers;

   --  First is the exact 1..(2**127-1) bowl answer, Step is -1 or +1.
   --  N may exceed the built-in GNAT big-integer cap.
   --  Result is the exact 1-based global rank in 1..N.
   procedure Choose_Rank
     (First : Std.Big_Integer; Step : Integer;
      N : G.Big_Integer; Result : out G.Big_Integer);
end Canonical_Wide_Rank_GMP_V164;
