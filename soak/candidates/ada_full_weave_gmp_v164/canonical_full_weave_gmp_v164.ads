with Ada.Finalization;
with GNATCOLL.GMP.Integers;

--  Issue #29 v164: QA-only arbitrary precision using GNATCOLL GMP.
--  Purely a full-legal-family count/unrank engine; never executes F(c,t).
package Canonical_Full_Weave_GMP_V164 is
   package G renames GNATCOLL.GMP.Integers;

   type Natural_Array is array (Positive range <>) of Natural;

   type Family (Month_Count : Positive) is limited private;

   procedure Build (F : in out Family; Lengths : Natural_Array);

   --  GMP Big_Integer is limited; return the exact number via output parameter.
   procedure Count (F : Family; Result : out G.Big_Integer);

   --  One-based lexicographic unranking across all legally interleaved months.
   function Unrank (F : Family; Rank : G.Big_Integer) return Natural_Array;

private
   type Prefix_Array is array (Natural range <>) of Natural;
   type Big_Row is array (Natural range <>) of G.Big_Integer;
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
end Canonical_Full_Weave_GMP_V164;
