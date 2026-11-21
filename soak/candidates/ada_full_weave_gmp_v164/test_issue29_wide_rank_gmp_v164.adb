with Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers;
with GNATCOLL.GMP.Integers;
with Canonical_Wide_Rank_GMP_V164;

--  Source-free exact rank vectors independently computed in Python integers.
--  No Sauce, no Calendar_Date, no F(c,t).
procedure Test_Issue29_Wide_Rank_GMP_V164 is
   package Std renames Ada.Numerics.Big_Numbers.Big_Integers;
   package G renames GNATCOLL.GMP.Integers;
   use G;

   M : constant Std.Big_Integer :=
     (Std.To_Big_Integer (2) ** 127) - Std.To_Big_Integer (1);
   One : constant Std.Big_Integer := Std.To_Big_Integer (1);
   Forty_Two : constant Std.Big_Integer := Std.To_Big_Integer (42);
   M_Text : constant String := "170141183460469231731687303715884105727";
   M_Plus_1 : constant String := "170141183460469231731687303715884105728";
   M_Square_Plus_17 : constant String :=
     "28948022309329048855892746252171976962977213799489202546401021394546514198546";

   procedure Check
     (First : Std.Big_Integer; Step : Integer;
      N_Text : String; Expected_Text : String)
   is
      N : constant G.Big_Integer := G.Make (N_Text);
      Expected : constant G.Big_Integer := G.Make (Expected_Text);
      Result : G.Big_Integer;
   begin
      Canonical_Wide_Rank_GMP_V164.Choose_Rank
        (First, Step, N, Result);
      if Result /= Expected then
         raise Program_Error with
           "GMP rank expected" & Expected_Text
           & " but was " & G.Image (Result);
      end if;
      Ada.Text_IO.Put_Line ("V164_GMP_WIDE_RANK_VECTOR_PASS");
   end Check;

begin
   --  Both short and wide pathways; both directions, boundary residues.
   Check (One, 1, "1", "1");
   Check (M, -1, "2", "2");
   Check (M, 1, "2", "1");
   Check (Forty_Two, -1, "13", "3");
   Check (Forty_Two, -1, M_Text, "42");
   Check (One, 1, M_Plus_1, M_Plus_1);
   Check (M, -1, M_Plus_1, "2");
   Check (M, 1, M_Plus_1, M_Text);
   Check (Forty_Two, -1, M_Plus_1, "2");
   Check (One, 1, M_Square_Plus_17,
          "170141183460469231731687303715884105694");
   Check (M, -1, M_Square_Plus_17,
          "28948022309329048855892746252171976959914672497200756375230649927660600295494");
   Check (M, 1, M_Square_Plus_17,
          "170141183460469231731687303715884105710");
   Check (Forty_Two, -1, M_Square_Plus_17,
          "6805647338418769269267492148635364228459");
   Ada.Text_IO.Put_Line ("V164_ALL_13_GMP_EXACT_RANK_VECTORS_PASS_NO_CALENDAR_F");
end Test_Issue29_Wide_Rank_GMP_V164;
