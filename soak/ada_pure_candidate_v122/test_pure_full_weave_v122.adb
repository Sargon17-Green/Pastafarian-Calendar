with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Pure_Full_Weave_V122;

procedure Test_Pure_Full_Weave_V122 is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   procedure Expect (Lengths : Pure_Full_Weave_V122.Natural_Array; Expected : Natural) is
      Observed : constant Big_Integer := Pure_Full_Weave_V122.Count (Lengths);
   begin
      if Observed /= To_Big_Integer (Integer (Expected)) then
         raise Program_Error with
           "pure month weave count mismatch: " & To_String (Observed);
      end if;
   end Expect;

   Lengths : Pure_Full_Weave_V122.Natural_Array (1 .. 47) := (others => 123);
   Huge_Count : Big_Integer := To_Big_Integer (0);
begin
   Expect ((1 => 2, 2 => 2), 2);
   Expect ((1 => 4, 2 => 4), 20);
   Expect ((1 => 2, 2 => 3, 3 => 4), 50);
   Expect ((1 => 4, 2 => 4, 3 => 4), 1_301);
   Expect ((1 => 3, 2 => 3, 3 => 3, 4 => 3), 1_266);
   Expect ((1 => 1, 2 => 2, 3 => 3), 3);
   Ada.Text_IO.Put_Line ("V122_SIX_SMALL_EXACT_ADA_MATH_COUNTS_PASS");

   Lengths (47) := 120;
   Huge_Count := Pure_Full_Weave_V122.Count (Lengths);
   -- No normal integer or 128-bit modulus can store this exact value.
   Ada.Text_IO.Put_Line
     ("V122_MAX_47_MONTH_5778_DAY_EXACT_INTEGER "
      & To_String (Huge_Count));
   Ada.Text_IO.Put_Line
     ("V122_PURE_ADA_MONTH_WEAVING_COUNT_ONLY_NO_FCT");
end Test_Pure_Full_Weave_V122;
