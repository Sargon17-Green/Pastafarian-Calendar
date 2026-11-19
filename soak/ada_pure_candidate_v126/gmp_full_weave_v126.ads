-- Research-only exact month weaving count. No F(c,t), no calendar conversion.
-- Month labels must first and last appear in increasing order.
-- The calculation is Ada; arbitrary-precision arithmetic uses GMP via a C ABI.
package GMP_Full_Weave_V126 is
   type Natural_Array is array (Positive range <>) of Natural;

   -- Returns an exact nonnegative decimal integer, not a bounded Ada Integer.
   function Count_Decimal (Lengths : Natural_Array) return String;
end GMP_Full_Weave_V126;
