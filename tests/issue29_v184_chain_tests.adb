with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;
with Canonical_Wide_Rank_GMP_V164;

--  QA v184: exact Count -> Choose_Rank -> Unrank with legal 4..123 lengths.
--  NEVER imports Normative_Oracle, Calendar_Date, Sauce, or full F(c,t).
procedure Issue29_V184_Chain_Tests is
   package Std renames Ada.Numerics.Big_Numbers.Big_Integers;
   package G renames GNATCOLL.GMP.Integers;
   package Full renames Canonical_Full_Weave_GMP_V164;
   package Wide renames Canonical_Wide_Rank_GMP_V164;
   use Ada.Text_IO;
   use type Std.Big_Integer;
   use type G.Big_Integer;

   M : constant Std.Big_Integer :=
     (Std.To_Big_Integer (2) ** 127) - Std.To_Big_Integer (1);
   Ref : File_Type;
   Families : Natural := 0;
   Streams : Natural := 0;
   Tokens : Natural := 0;
   Assertions : Natural := 0;
   Narrow : Natural := 0;
   Wide_Cases : Natural := 0;

   procedure Require (OK : Boolean; Label : String) is
   begin
      Assertions := Assertions + 1;
      if not OK then
         Put_Line ("V184_FAILED=" & Label);
         raise Program_Error with "v184 independent integrated GMP chain mismatch";
      end if;
   end Require;

   function Next_Natural return Natural is
   begin
      return Natural'Value
        (Ada.Strings.Fixed.Trim (Get_Line (Ref), Ada.Strings.Both));
   end Next_Natural;

   procedure Check_Family is
      Month_Count : constant Positive := Next_Natural;
      Lengths : Full.Natural_Array (1 .. Month_Count);
      Family : Full.Family (Month_Count);
      Expected_Count : G.Big_Integer;
      Actual_Count : G.Big_Integer;
      Samples : Natural;
      Total_Days : Natural := 0;
   begin
      Require (Month_Count in 2 .. 47, "family month count");
      for J in Lengths'Range loop
         Lengths (J) := Next_Natural;
         Require (Lengths (J) in 4 .. 123, "canonical month length 4..123");
         Total_Days := Total_Days + Lengths (J);
      end loop;
      Require (Total_Days <= 5_778, "canonical maximum year length");
      G.Set (Expected_Count, G.Make (Get_Line (Ref)));
      Samples := Next_Natural;
      Require (Samples = 6, "all six direction/first-value streams");
      Full.Build (Family, Lengths);
      Full.Count (Family, Actual_Count);
      Require (Actual_Count = Expected_Count, "independent full Count");
      if Actual_Count > G.Make ("170141183460469231731687303715884105727") then
         Wide_Cases := Wide_Cases + 1;
      else
         Narrow := Narrow + 1;
      end if;
      for S in 1 .. Samples loop
         declare
            First_Code : constant Natural := Next_Natural;
            Step : constant Integer := Integer'Value (Get_Line (Ref));
            Expected_Rank : G.Big_Integer;
            Actual_Rank : G.Big_Integer;
            First : Std.Big_Integer;
         begin
            Require (First_Code in 1 .. 3, "first answer code");
            Require (Step = -1 or else Step = 1, "step sign");
            if First_Code = 1 then
               First := Std.To_Big_Integer (1);
            elsif First_Code = 2 then
               First := M / Std.To_Big_Integer (2);
            else
               First := M;
            end if;
            G.Set (Expected_Rank, G.Make (Get_Line (Ref)));
            Wide.Choose_Rank (First, Step, Actual_Count, Actual_Rank);
            Require (Actual_Rank = Expected_Rank,
                     "complete independent stream-to-GMP rank");
            Require (Actual_Rank >= G.Make ("1") and then
                     Actual_Rank <= Actual_Count, "legal one-based rank");
            declare
               Sequence : constant Full.Natural_Array :=
                 Full.Unrank (Family, Actual_Rank);
               Occurrences : Full.Natural_Array (1 .. Month_Count) :=
                 (others => 0);
               First_At : Full.Natural_Array (1 .. Month_Count) :=
                 (others => 0);
               Last_At : Full.Natural_Array (1 .. Month_Count) :=
                 (others => 0);
            begin
               Require (Sequence'Length = Total_Days, "full sequence length");
               for P in Sequence'Range loop
                  declare
                     Expected : constant Natural := Next_Natural;
                     Label_Id : constant Natural := Sequence (P);
                  begin
                     Require (Expected in 1 .. Month_Count, "fixture label in bounds");
                     Require (Label_Id = Expected, "exact independent unrank label");
                     Require (Label_Id in 1 .. Month_Count, "native label in bounds");
                     Occurrences (Label_Id) := Occurrences (Label_Id) + 1;
                     if First_At (Label_Id) = 0 then
                        First_At (Label_Id) := P;
                     end if;
                     Last_At (Label_Id) := P;
                     Tokens := Tokens + 1;
                  end;
               end loop;
               for J in 1 .. Month_Count loop
                  Require (Occurrences (J) = Lengths (J), "month multiplicity");
                  Require (First_At (J) > 0 and then Last_At (J) >= First_At (J),
                           "month first and last occurrence");
                  if J > 1 then
                     Require (First_At (J - 1) < First_At (J),
                              "opening order");
                     Require (Last_At (J - 1) < Last_At (J),
                              "closing order");
                  end if;
               end loop;
            end;
            Streams := Streams + 1;
         end;
      end loop;
      Families := Families + 1;
   end Check_Family;
begin
   Open (Ref, In_File, "evidence/v184-exact-chain-reference.dat");
   Require (Next_Natural = 13, "thirteen distinct legal families");
   for I in 1 .. 13 loop
      Check_Family;
   end loop;
   Require (End_Of_File (Ref), "reference completely consumed");
   Close (Ref);
   Require (Families = 13 and then Streams = 78, "all exact GMP chain cases");
   Require (Tokens = 6_174, "all sample symbols compared");
   Require (Wide_Cases >= 4 and then Narrow >= 4,
            "both GMP narrow and wide rank paths exercised");
   Require (Assertions > 18_000, "full-token witness not skipped");
   Put_Line ("V184_FAMILIES=" & Natural'Image (Families));
   Put_Line ("V184_STREAMS=" & Natural'Image (Streams));
   Put_Line ("V184_TOKENS=" & Natural'Image (Tokens));
   Put_Line ("V184_WIDE_COUNT_FAMILIES=" & Natural'Image (Wide_Cases));
   Put_Line ("V184_ASSERTIONS=" & Natural'Image (Assertions));
   Put_Line ("V184_EXACT_COUNT_CHOOSE_RANK_UNRANK_LEGAL_LENGTHS_PASS_ZERO_F");
end Issue29_V184_Chain_Tests;
