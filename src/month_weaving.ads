with Ada.Numerics.Big_Numbers.Big_Integers;

package Month_Weaving is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   type Natural_Array is array (Positive range <>) of Natural;

   -- Exact size of the canonical two-rail family for the supplied lengths.
   function Canonical_Weave_Count (Lengths : Natural_Array) return Big_Integer;

   -- One-based lexicographic unranking of the canonical two-rail family.
   function Unrank_Canonical_Weave
     (Lengths : Natural_Array; Rank : Big_Integer) return Natural_Array;
end Month_Weaving;
