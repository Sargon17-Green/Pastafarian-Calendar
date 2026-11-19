with Ada.Text_IO;
with GMP_Full_Weave_V126;

procedure Test_GMP_Full_Weave_V126 is
   use GMP_Full_Weave_V126;

   procedure Expect (Lengths : Natural_Array; Expected : String) is
      Got : constant String := Count_Decimal (Lengths);
   begin
      if Got /= Expected then
         raise Program_Error with
           "pure GMP Ada weave count mismatch: observed " & Got
           & ", expected " & Expected;
      end if;
   end Expect;

   Lengths : Natural_Array (1 .. 47) := (others => 123);
begin
   Expect ((1 => 2, 2 => 2), "2");
   Expect ((1 => 4, 2 => 4), "20");
   Expect ((1 => 2, 2 => 3, 3 => 4), "50");
   Expect ((1 => 4, 2 => 4, 3 => 4), "1301");
   Expect ((1 => 3, 2 => 3, 3 => 3, 4 => 3), "1266");
   Expect ((1 => 1, 2 => 2, 3 => 3), "3");
   Ada.Text_IO.Put_Line ("V126_SIX_SMALL_EXACT_ADA_GMP_MATH_COUNTS_PASS");

   Lengths (47) := 120;
   Ada.Text_IO.Put_Line
     ("V126_MAX_47_MONTH_5778_DAY_EXACT_INTEGER " &
      Count_Decimal (Lengths));
   Ada.Text_IO.Put_Line
     ("V126_PURE_ADA_GMP_MONTH_WEAVING_COUNT_ONLY_NO_FCT");
end Test_GMP_Full_Weave_V126;
