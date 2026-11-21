with Ada.Finalization;
with Ada.Numerics.Big_Numbers.Big_Integers;

--  Issue #29 QA CANDIDATE: all legal month interleavings, not two fixed rails.
--  Never invokes Normative_Oracle.Calendar_Date or foundation F(c,t).
package Canonical_Full_Weave_V163 is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   type Natural_Array is array (Positive range <>) of Natural;

   --  A family caches its exact dynamic-programming table for count AND unrank.
   --  The resource cost can be substantial at the production maximum.
   type Family (Month_Count : Positive) is limited private;

   --  Exactly one build is permitted for an instance. Accepts small synthetic
   --  month lengths >= 2 for independent finite tests; production lengths >= 4.
   procedure Build (F : in out Family; Lengths : Natural_Array);

   --  All legal interleavings respecting BOTH first and last occurrence order.
   --  Count is arbitrary precision, not a bounded-machine integer.
   function Count (F : Family) return Big_Integer;

   --  1-based lexicographic unranking over the COMPLETE legal family.
   function Unrank (F : Family; Rank : Big_Integer) return Natural_Array;

private
   type Prefix_Array is array (Natural range <>) of Natural;
   type Big_Row is array (Natural range <>) of Big_Integer;
   type Big_Row_Access is access Big_Row;
   type Row_Table is array (Natural range <>) of Big_Row_Access;

   type Family (Month_Count : Positive) is
     new Ada.Finalization.Limited_Controlled with
   record
      Lengths : Natural_Array (1 .. Month_Count) := (others => 0);
      Prefix  : Prefix_Array (0 .. Month_Count) := (others => 0);
      H       : Row_Table (0 .. Month_Count) := (others => null);
      Ready   : Boolean := False;
   end record;

   overriding procedure Finalize (F : in out Family);
end Canonical_Full_Weave_V163;
