with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;
with Canonical_Wide_Rank_GMP_V164;

--  One REAL captured foundation-day witness, only GMP COMPONENT replay.
--  No Normative_Oracle, Calendar_Date, original F(c,t), or original Sauce.
procedure Issue29_V189_Foundation_GMP_Tests is
   package Std renames Ada.Numerics.Big_Numbers.Big_Integers;
   package G renames GNATCOLL.GMP.Integers;
   package Full renames Canonical_Full_Weave_GMP_V164;
   package Wide renames Canonical_Wide_Rank_GMP_V164;
   use Ada.Text_IO;
   use type G.Big_Integer;
   use type Std.Big_Integer;
   Ref : File_Type;
   Assertions : Natural := 0;
   Tokens : Natural := 0;
   M : constant Std.Big_Integer :=
     (Std.To_Big_Integer (2) ** 127) - Std.To_Big_Integer (1);

   procedure Require (Ok : Boolean; Name : String) is
   begin
      Assertions := Assertions + 1;
      if not Ok then
         Put_Line ("V189_FAILED=" & Name);
         raise Program_Error with "frozen original foundation GMP replay mismatch";
      end if;
   end Require;

   function Read_Natural return Natural is
   begin
      return Natural'Value
        (Ada.Strings.Fixed.Trim (Get_Line (Ref), Ada.Strings.Both));
   end Read_Natural;

   function Read_Std_Big return Std.Big_Integer is
      S : constant String := Get_Line (Ref);
      V : Std.Big_Integer := Std.To_Big_Integer (0);
   begin
      Require (S'Length > 0, "nonempty first answer");
      for C of S loop
         Require (C in '0' .. '9', "decimal-only original first answer");
         V := V * Std.To_Big_Integer (10) +
           Std.To_Big_Integer (Character'Pos (C) - Character'Pos ('0'));
      end loop;
      return V;
   end Read_Std_Big;

   procedure Replay_Original_Foundation is
      Month_Count : constant Positive := Read_Natural;
      Lengths : Full.Natural_Array (1 .. Month_Count);
      Family : Full.Family (Month_Count);
      First : Std.Big_Integer := Std.To_Big_Integer (0);
      Step : Integer;
      Expected_Count : G.Big_Integer;
      Actual_Count : G.Big_Integer;
      Expected_Rank : G.Big_Integer;
      Actual_Rank : G.Big_Integer;
      Days : Natural := 0;
      Read_Days : Natural;
      Month_Names : constant Full.Natural_Array (1 .. 45) :=
        (18,14,37,28,24,42,6,20,19,41,16,39,25,1,9,38,
         3,46,27,40,12,43,35,32,29,10,44,36,23,17,
         33,5,30,15,11,45,8,4,7,31,34,22,13,2,26);
   begin
      Require (Month_Count = 45, "45 frozen real witness months");
      for J in Lengths'Range loop
         Lengths (J) := Read_Natural;
         Require (Lengths (J) in 4 .. 123, "legal original month length");
         Days := Days + Lengths (J);
      end loop;
      Require (Days = 4_244, "true original year length");
      First := Read_Std_Big;
      Step := Integer'Value (Get_Line (Ref));
      Require (First >= Std.To_Big_Integer (1) and then First <= M,
               "real recorded bowl first answer");
      Require (Step = -1, "real recorded bowl direction");
      G.Set (Expected_Count, G.Make (Get_Line (Ref)));
      G.Set (Expected_Rank, G.Make (Get_Line (Ref)));
      Read_Days := Read_Natural;
      Require (Read_Days = Days, "exact fixture year tokens");
      Full.Build (Family, Lengths);
      Full.Count (Family, Actual_Count);
      Require (Actual_Count = Expected_Count, "real 22470-bit full family count");
      Wide.Choose_Rank (First, Step, Actual_Count, Actual_Rank);
      Require (Actual_Rank = Expected_Rank, "real 177-radix-place wide rank");
      Require (Actual_Rank >= G.Make ("1") and then
               Actual_Rank <= Actual_Count, "legal original global rank");
      declare
         Sequence : constant Full.Natural_Array :=
           Full.Unrank (Family, Actual_Rank);
         Occurrences : Full.Natural_Array (1 .. Month_Count) :=
           (others => 0);
         First_Pos : Full.Natural_Array (1 .. Month_Count) :=
           (others => 0);
         Last_Pos : Full.Natural_Array (1 .. Month_Count) :=
           (others => 0);
         Target_Id : Natural := 0;
         Target_Day : Natural := 0;
      begin
         Require (Sequence'Length = Read_Days, "complete 4244-token sequence");
         for P in Sequence'Range loop
            declare
               Expected : constant Natural := Read_Natural;
               Label_Id : constant Natural := Sequence (P);
            begin
               Require (Expected in 1 .. Month_Count, "reference label range");
               Require (Label_Id = Expected, "exact original Python month token");
               Require (Label_Id in 1 .. Month_Count, "native month label range");
               Occurrences (Label_Id) := Occurrences (Label_Id) + 1;
               if First_Pos (Label_Id) = 0 then
                  First_Pos (Label_Id) := P;
               end if;
               Last_Pos (Label_Id) := P;
               Tokens := Tokens + 1;
               if P = 8 then
                  Require (Label_Id = 4, "actual first divergence day8 Python month4");
               end if;
               if P = 2_032 then
                  Target_Id := Label_Id;
                  Target_Day := Occurrences (Label_Id);
               end if;
            end;
         end loop;
         Require (Target_Id = 8 and then Target_Day = 56,
                  "actual foundation target chronological month/day");
         Require (Month_Names (Target_Id) = 20,
                  "actual canonical month-name index");
         for J in 1 .. Month_Count loop
            Require (Occurrences (J) = Lengths (J),
                     "all exact original month multiplicities");
            Require (First_Pos (J) > 0 and then
                     Last_Pos (J) >= First_Pos (J),
                     "legal opening and closing");
            if J > 1 then
               Require (First_Pos (J - 1) < First_Pos (J),
                        "first appearance order");
               Require (Last_Pos (J - 1) < Last_Pos (J),
                        "last appearance order");
            end if;
         end loop;
      end;
   end Replay_Original_Foundation;
begin
   Open (Ref, In_File, "evidence/v189-frozen-original-foundation-reference.dat");
   Replay_Original_Foundation;
   Require (End_Of_File (Ref), "reference completely consumed");
   Close (Ref);
   Require (Tokens = 4_244, "all 4244 exact labels compared");
   Require (Assertions > 12_700, "nontrivial per-token validation executed");
   Put_Line ("V189_TOKENS=" & Natural'Image (Tokens));
   Put_Line ("V189_ASSERTIONS=" & Natural'Image (Assertions));
   Put_Line ("V189_ORIGINAL_FOUNDATION_GMP_4244_EXACT_PASS_ZERO_F");
end Issue29_V189_Foundation_GMP_Tests;
