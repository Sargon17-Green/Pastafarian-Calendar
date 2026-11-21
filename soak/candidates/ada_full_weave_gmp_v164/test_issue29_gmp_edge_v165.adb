with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

--  No calendar model is linked, only canonical synthetic month families.
--  Validate 47 months with shortest 252-day and longest 5778-day year,
--  plus one-month boundary on standalone family.
procedure Test_Issue29_GMP_Edge_V165 is
   package CW renames Canonical_Full_Weave_GMP_V164;
   package G renames GNATCOLL.GMP.Integers;
   use G;

   procedure Validate
     (Lengths : CW.Natural_Array; Expected_Days : Positive;
      Label : String; Check_Last : Boolean := False)
   is
      F : CW.Family (Lengths'Length);
      N : G.Big_Integer;
   begin
      CW.Build (F, Lengths);
      CW.Count (F, N);
      if N < G.Make ("1") then
         raise Program_Error with "nonpositive full-family count";
      end if;
      for Pass in 1 .. (if Check_Last then 2 else 1) loop
         declare
            Rank : constant G.Big_Integer :=
              (if Pass = 1 then G.Make ("1") else N);
            Word : constant CW.Natural_Array := CW.Unrank (F, Rank);
            Frequencies : CW.Natural_Array (1 .. Lengths'Length) := (others => 0);
            First : CW.Natural_Array (1 .. Lengths'Length) := (others => 0);
            Last : CW.Natural_Array (1 .. Lengths'Length) := (others => 0);
         begin
            if Word'Length /= Expected_Days then
               raise Program_Error with "edge word length incorrect";
            end if;
            for P in Word'Range loop
               declare
                  J : constant Natural := Word (P);
               begin
                  if J < 1 or else J > Lengths'Length then
                     raise Program_Error with "edge month id out of range";
                  end if;
                  Frequencies (J) := Frequencies (J) + 1;
                  if First (J) = 0 then
                     First (J) := P;
                  end if;
                  Last (J) := P;
               end;
            end loop;
            for J in 1 .. Lengths'Length loop
               if Frequencies (J) /= Lengths (Lengths'First + J - 1) then
                  raise Program_Error with "edge frequency mismatch";
               end if;
            end loop;
            for J in 1 .. Lengths'Length - 1 loop
               if First (J) >= First (J + 1)
                 or else Last (J) >= Last (J + 1)
               then
                  raise Program_Error with "edge first/last order mismatch";
               end if;
            end loop;
            Ada.Text_IO.Put_Line
              ("V165_EDGE_PASS|" & Label & "|" & Natural'Image (Pass)
               & "|" & Natural'Image (Word'Length));
         end;
      end loop;
      Ada.Text_IO.Put_Line
        ("V165_EDGE_COUNT_HEX|" & Label & "|" & G.Image (N, Base => 16));
   end Validate;

begin
   Validate ((1 => 4), 4, "1x4", Check_Last => True);
   Validate ((1 .. 45 => 5, 46 => 13, 47 => 14),
             252, "47x252", Check_Last => True);
   Validate ((1 .. 44 => 123, 45 .. 47 => 122),
             5778, "47x5778", Check_Last => True);
   Ada.Text_IO.Put_Line ("V165_ALL_THREE_EDGE_FAMILIES_PASS_NO_F");
end Test_Issue29_GMP_Edge_V165;
