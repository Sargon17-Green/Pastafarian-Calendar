with Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;
with Canonical_Wide_Rank_GMP_V164;

--  Synthetic, no calendar F: use all-legal 45x4244 family and a synthetic
--  GMP stream (First=42, Direction=-1). The complete huge rank and all
--  4244 integer month IDs are exported for independent Python re-derivation.
procedure Benchmark_Issue29_GMP_Global_Rank_V164 is
   package CW renames Canonical_Full_Weave_GMP_V164;
   package GS renames Canonical_Wide_Rank_GMP_V164;
   package G renames GNATCOLL.GMP.Integers;
   package Std renames Ada.Numerics.Big_Numbers.Big_Integers;
   use G;

   Lengths : constant CW.Natural_Array (1 .. 45) :=
     (1 .. 44 => 94, 45 => 108);
   F : CW.Family (45);
   Options : G.Big_Integer;
   Rank : G.Big_Integer;
begin
   CW.Build (F, Lengths);
   CW.Count (F, Options);
   GS.Choose_Rank (Std.To_Big_Integer (42), -1, Options, Rank);

   if Rank < G.Make ("1") or else Rank > Options then
      raise Program_Error with "synthetic GMP global rank outside full family";
   end if;

   declare
      Word : constant CW.Natural_Array := CW.Unrank (F, Rank);
      Frequencies : CW.Natural_Array (1 .. 45) := (others => 0);
      First_Pos : CW.Natural_Array (1 .. 45) := (others => 0);
      Last_Pos : CW.Natural_Array (1 .. 45) := (others => 0);
   begin
      if Word'Length /= 4_244 then
         raise Program_Error with "synthetic full global-rank weave length is wrong";
      end if;

      for P in Word'Range loop
         declare
            J : constant Natural := Word (P);
         begin
            if J not in 1 .. 45 then
               raise Program_Error with "synthetic global-rank month id is invalid";
            end if;
            Frequencies (J) := Frequencies (J) + 1;
            if First_Pos (J) = 0 then
               First_Pos (J) := P;
            end if;
            Last_Pos (J) := P;
         end;
      end loop;
      for J in 1 .. 45 loop
         if Frequencies (J) /= Lengths (J) then
            raise Program_Error with "global-rank month frequency is invalid";
         end if;
      end loop;
      for J in 1 .. 44 loop
         if First_Pos (J) >= First_Pos (J + 1)
           or else Last_Pos (J) >= Last_Pos (J + 1)
         then
            raise Program_Error with "global-rank first/last order invalid";
         end if;
      end loop;

      Ada.Text_IO.Put_Line
        ("V164_SYNTHETIC_GLOBAL_RANK_HEX=" & G.Image (Rank, Base => 16));
      Ada.Text_IO.Put ("V164_SYNTHETIC_GLOBAL_WEAVE_CSV=");
      for P in Word'Range loop
         if P /= Word'First then
            Ada.Text_IO.Put (",");
         end if;
         Ada.Text_IO.Put
           (Natural'Image (Word (P)) (2 .. Natural'Image (Word (P))'Last));
      end loop;
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line
        ("V164_SYNTHETIC_GLOBAL_RANK_FULL_4244_WEAVE_PASS_NO_F");
   end;
end Benchmark_Issue29_GMP_Global_Rank_V164;
