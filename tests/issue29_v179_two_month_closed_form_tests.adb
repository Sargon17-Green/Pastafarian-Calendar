with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

-- v179: exact two-month binomial formula independent of production H-table.
-- Executable imports GMP weaving ONLY, no calendar or original F(c,t).
procedure Issue29_V179_Two_Month_Closed_Form_Tests is
   package G renames GNATCOLL.GMP.Integers;
   package Full renames Canonical_Full_Weave_GMP_V164;
   use type G.Big_Integer;
   use Ada.Text_IO;

   Ref : File_Type;
   Assertions : Natural := 0;
   Pairs : Natural := 0;
   Samples : Natural := 0;

   procedure Require (B : Boolean; Label : String) is
   begin
      Assertions := Assertions + 1;
      if not B then
         Put_Line ("FAILED_CHECK=" & Label);
         raise Program_Error with "v179 GMP/binomial discrepancy";
      end if;
   end Require;

   function Next_Natural return Natural is
   begin
      return Natural'Value
        (Ada.Strings.Fixed.Trim (Get_Line (Ref), Ada.Strings.Both));
   end Next_Natural;

   procedure Check_Pair (A, B : Positive) is
      F : Full.Family (2);
      Lengths : constant Full.Natural_Array (1 .. 2) := (A, B);
      Count : G.Big_Integer;
      Expected : G.Big_Integer;
      Number_Of_Samples : Natural;
      Last_Rank : G.Big_Integer;
   begin
      Require (Next_Natural = A, "expected first month length");
      Require (Next_Natural = B, "expected second month length");
      G.Set (Expected, G.Make (Get_Line (Ref)));
      Number_Of_Samples := Next_Natural;
      Require (Number_Of_Samples in 0 .. 3, "bounded number of samples");
      Full.Build (F, Lengths);
      Full.Count (F, Count);
      Require (Count = Expected, "binomial exact count for two months");
      G.Set (Last_Rank, G.Make ("0"));
      for Sample in 1 .. Number_Of_Samples loop
         declare
            Rank : G.Big_Integer;
         begin
            G.Set (Rank, G.Make (Get_Line (Ref)));
            Require (Rank > Last_Rank and then Rank <= Count,
                     "strict ascending reference rank");
            declare
               Weave : constant Full.Natural_Array := Full.Unrank (F, Rank);
               Ones : Natural := 0;
               Twos : Natural := 0;
            begin
               Require (Weave'Length = A + B, "weave length");
               Require (Weave (Weave'First) = 1 and then
                        Weave (Weave'Last) = 2,
                        "mandatory first and last two-month symbols");
               for Position in Weave'Range loop
                  declare
                     Token : constant Natural := Next_Natural;
                  begin
                     Require (Token in 1 .. 2, "reference token in range");
                     Require (Weave (Position) = Token,
                              "independent exact binomial unrank token");
                     if Weave (Position) = 1 then
                        Ones := Ones + 1;
                     else
                        Twos := Twos + 1;
                     end if;
                  end;
               end loop;
               Require (Ones = A and then Twos = B, "month multiplicity");
            end;
            G.Set (Last_Rank, Rank);
            Samples := Samples + 1;
         end;
      end loop;
      Pairs := Pairs + 1;
   end Check_Pair;

   Number_Of_Pairs : Natural;
begin
   Open (Ref, In_File, "evidence/v179-two-month-reference.dat");
   Number_Of_Pairs := Next_Natural;
   Require (Number_Of_Pairs = 14_884, "full 122 by 122 legal grid");
   for A in 2 .. 123 loop
      for B in 2 .. 123 loop
         Check_Pair (A, B);
      end loop;
   end loop;
   Require (End_Of_File (Ref), "no remaining oracle tokens");
   Close (Ref);
   Require (Pairs = 14_884, "all legal two-month length pairs tested");
   Require (Samples > 1_000, "many independent unrank samples tested");
   Require (Assertions > 40_000, "substantive component verification");
   Put_Line ("V179_CLOSED_FORM_PAIRS=" & Natural'Image (Pairs));
   Put_Line ("V179_CLOSED_FORM_SAMPLES=" & Natural'Image (Samples));
   Put_Line ("V179_CLOSED_FORM_ASSERTIONS=" & Natural'Image (Assertions));
end Issue29_V179_Two_Month_Closed_Form_Tests;
