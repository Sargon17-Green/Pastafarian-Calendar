with Ada.Numerics.Big_Numbers.Big_Integers;

-- Research-only, exact combinatorial model. It does NOT call F(c,t),
-- change the original Ada implementation, or claim canonical certification.
package Pure_Full_Weave_V122 is
   subtype Big_Integer is Ada.Numerics.Big_Numbers.Big_Integers.Big_Integer;
   type Natural_Array is array (Positive range <>) of Natural;

   -- Exact size of month-label words having ascending first and last
   -- occurrence order. The result is not restricted by the source Sauce M.
   function Count (Lengths : Natural_Array) return Big_Integer;
end Pure_Full_Weave_V122;
