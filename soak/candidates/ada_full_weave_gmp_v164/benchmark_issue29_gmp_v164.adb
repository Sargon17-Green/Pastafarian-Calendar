with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

--  NO Calendar_Date, Sauce, Foundation_Day, native Soak or date conversion.
--  Synthetic 45-month 4244-day shape tests only the exact GMP combinatorics.
procedure Benchmark_Issue29_GMP_V164 is
   package CW renames Canonical_Full_Weave_GMP_V164;
   package G renames GNATCOLL.GMP.Integers;
   subtype Natural_Array is CW.Natural_Array;
   use G;

   Lengths : constant Natural_Array (1 .. 45) :=
     (1 .. 44 => 94, 45 => 108);
   F : CW.Family (45);
   Options : G.Big_Integer;
begin
   CW.Build (F, Lengths);
   CW.Count (F, Options);
   if Options <= G.Make ("1") then
      raise Program_Error with "synthetic full-size GMP family count <= 1";
   end if;
   declare
      Chosen : constant Natural_Array := CW.Unrank (F, G.Make ("1"));
      Counts : Natural_Array (1 .. 45) := (others => 0);
      First_Pos : Natural_Array (1 .. 45) := (others => 0);
      Last_Pos : Natural_Array (1 .. 45) := (others => 0);
   begin
      if Chosen'Length /= 4_244 then
         raise Program_Error with "GMP synthetic weave length mismatch";
      end if;
      for P in Chosen'Range loop
         declare
            J : constant Natural := Chosen (P);
         begin
            if J not in 1 .. 45 then
               raise Program_Error with "GMP synthetic weave invalid month id";
            end if;
            Counts (J) := Counts (J) + 1;
            if First_Pos (J) = 0 then
               First_Pos (J) := P;
            end if;
            Last_Pos (J) := P;
            if J /= (if P <= 44 * 94 then 1 + (P - 1) / 94 else 45) then
               raise Program_Error with "GMP rank one is not lexicographic minimum";
            end if;
         end;
      end loop;
      for J in 1 .. 45 loop
         if Counts (J) /= Lengths (J) then
            raise Program_Error with "GMP synthetic weave frequency mismatch";
         end if;
      end loop;
      for J in 1 .. 44 loop
         if First_Pos (J) >= First_Pos (J + 1)
           or else Last_Pos (J) >= Last_Pos (J + 1)
         then
            raise Program_Error with "GMP synthetic weave order mismatch";
         end if;
      end loop;
   end;
   Ada.Text_IO.Put_Line ("V164_GMP_45_MONTH_4244_DAY_SYNTHETIC_RANK1_PASS_NO_F");
   Ada.Text_IO.Put_Line
     ("V164_GMP_EXACT_COUNT_DECIMAL_DIGITS=" & Natural'Image (G.Image (Options)'Length));
   Ada.Text_IO.Put_Line
     ("V164_GMP_EXACT_COUNT_HEX=" & G.Image (Options, Base => 16));
end Benchmark_Issue29_GMP_V164;
