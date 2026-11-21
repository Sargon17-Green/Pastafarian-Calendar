with Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers;
with Canonical_Full_Weave_V163;

--  SYNTHETIC stress case only. This program never invokes Calendar_Date.
--  44*94 + 108 = 4244, 45 distinct months. No Sauce or foundation input.
procedure Benchmark_Issue29_Full_Weave_V163 is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   package CW renames Canonical_Full_Weave_V163;
   subtype Natural_Array is CW.Natural_Array;

   Lengths : constant Natural_Array (1 .. 45) :=
     (1 .. 44 => 94, 45 => 108);
   F : CW.Family (45);
begin
   CW.Build (F, Lengths);
   declare
      Options : constant Big_Integer := CW.Count (F);
      Chosen : constant Natural_Array := CW.Unrank (F, To_Big_Integer (1));
      Frequencies : Natural_Array (1 .. 45) := (others => 0);
      First_Pos : Natural_Array (1 .. 45) := (others => 0);
      Last_Pos : Natural_Array (1 .. 45) := (others => 0);
   begin
      if Chosen'Length /= 4_244 or else Options <= To_Big_Integer (1) then
         raise Program_Error with "wrong 45-by-4244 synthetic size";
      end if;
      for P in Chosen'Range loop
         declare
            K : constant Natural := Chosen (P);
         begin
            if K not in 1 .. 45 then
               raise Program_Error with "month id outside synthetic range";
            end if;
            Frequencies (K) := Frequencies (K) + 1;
            if First_Pos (K) = 0 then
               First_Pos (K) := P;
            end if;
            Last_Pos (K) := P;
         end;
      end loop;
      for J in 1 .. 45 loop
         if Frequencies (J) /= Lengths (J) then
            raise Program_Error with "synthetic month frequency mismatch";
         end if;
      end loop;
      for J in 1 .. 44 loop
         if First_Pos (J) >= First_Pos (J + 1)
           or else Last_Pos (J) >= Last_Pos (J + 1)
         then
            raise Program_Error with "illegal first/last occurrence order";
         end if;
      end loop;
      --  For a lexicographic first-ranked full weave, all month-1 items
      --  precede all month-2 items, then month-3, and so on.
      for P in Chosen'Range loop
         declare
            Wanted : constant Natural :=
              (if P <= 44 * 94 then 1 + (P - 1) / 94 else 45);
         begin
            if Chosen (P) /= Wanted then
               raise Program_Error with "synthetic rank-1 is not lexicographically first";
            end if;
         end;
      end loop;
      Ada.Text_IO.Put_Line
        ("V163_SYNTHETIC_FULL_LENGTH_45_MONTHS_4244_DAYS_RANK1_PASS_NO_F");
   end;
end Benchmark_Issue29_Full_Weave_V163;
