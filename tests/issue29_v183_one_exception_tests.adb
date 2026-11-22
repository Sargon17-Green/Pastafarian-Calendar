with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

--  Isolated GMP-only synthetic witness. Never import or call Calendar_Date/F.
--  Exact expected sequences are computed by independent three-scalar DP states.
procedure Issue29_V183_One_Exception_Tests is
   package G renames GNATCOLL.GMP.Integers;
   package Full renames Canonical_Full_Weave_GMP_V164;
   use Ada.Text_IO;
   use type G.Big_Integer;

   Ref : File_Type;
   Families : Natural := 0;
   Samples : Natural := 0;
   Tokens : Natural := 0;
   Assertions : Natural := 0;

   procedure Require (OK : Boolean; Label : String) is
   begin
      Assertions := Assertions + 1;
      if not OK then
         Put_Line ("V183_FAILED_CHECK=" & Label);
         raise Program_Error with "v183 independent 47-month DP/GMP discrepancy";
      end if;
   end Require;

   function Next_Natural return Natural is
   begin
      return Natural'Value
        (Ada.Strings.Fixed.Trim (Get_Line (Ref), Ada.Strings.Both));
   end Next_Natural;

   procedure Verify_Family is
      M : constant Positive := Next_Natural;
      Exception_Index : constant Positive := Next_Natural;
      Exception_Length : constant Natural := Next_Natural;
      Lengths : Full.Natural_Array (1 .. M) := (others => 2);
      Family : Full.Family (M);
      Expected_Count : G.Big_Integer;
      Actual_Count : G.Big_Integer;
      Last_Rank : G.Big_Integer;
      Samples_For_Case : Natural;
   begin
      Require (M = 47, "47 actual synthetic months");
      Require (Exception_Index in 1 .. M, "one exceptional month index");
      Require (Exception_Length in 3 .. 123, "exceptional month length");
      Lengths (Exception_Index) := Exception_Length;
      G.Set (Expected_Count, G.Make (Get_Line (Ref)));
      Samples_For_Case := Next_Natural;
      Require (Samples_For_Case = 7, "seven independent ranks per family");
      Full.Build (Family, Lengths);
      Full.Count (Family, Actual_Count);
      Require (Actual_Count = Expected_Count, "exact compact-state total count");
      G.Set (Last_Rank, G.Make ("0"));
      for Sample_Number in 1 .. Samples_For_Case loop
         declare
            Rank : G.Big_Integer;
         begin
            G.Set (Rank, G.Make (Get_Line (Ref)));
            Require (Rank > Last_Rank and then Rank <= Actual_Count,
                     "strict rank ordering and rank bounds");
            declare
               Weave : constant Full.Natural_Array := Full.Unrank (Family, Rank);
               Counts : Full.Natural_Array (1 .. M) := (others => 0);
               First_At : Full.Natural_Array (1 .. M) := (others => 0);
               Last_At : Full.Natural_Array (1 .. M) := (others => 0);
            begin
               Require (Weave'Length = 2 * M + Exception_Length - 2,
                        "full sequence returned length");
               Require (Weave (Weave'First) = 1 and then
                        Weave (Weave'Last) = M, "canonical boundary symbols");
               for P in Weave'Range loop
                  declare
                     Token : constant Natural := Next_Natural;
                  begin
                     Require (Token in 1 .. M, "independent oracle symbol in bounds");
                     Require (Weave (P) = Token, "exact independent lexicographic symbol");
                     Counts (Weave (P)) := Counts (Weave (P)) + 1;
                     if First_At (Weave (P)) = 0 then
                        First_At (Weave (P)) := P;
                     end if;
                     Last_At (Weave (P)) := P;
                     Tokens := Tokens + 1;
                  end;
               end loop;
               for J in 1 .. M loop
                  Require (Counts (J) = Lengths (J), "correct full multiplicity");
                  Require (First_At (J) > 0 and then Last_At (J) >= First_At (J),
                           "first and last occurrence exist");
                  if J > 1 then
                     Require (First_At (J - 1) < First_At (J),
                              "first occurrence order");
                     Require (Last_At (J - 1) < Last_At (J),
                              "last occurrence order");
                  end if;
               end loop;
            end;
            G.Set (Last_Rank, Rank);
            Samples := Samples + 1;
         end;
      end loop;
      Families := Families + 1;
   end Verify_Family;
begin
   Open (Ref, In_File, "evidence/v183-one-exception-reference.dat");
   Require (Next_Natural = 5, "five independent heterogeneous 47-month families");
   for K in 1 .. 5 loop
      Verify_Family;
   end loop;
   Require (End_Of_File (Ref), "full reference fixture consumed");
   Close (Ref);
   Require (Families = 5 and then Samples = 35,
            "all five families times seven ranks verified");
   Require (Tokens = 5_873, "all 5,873 exact symbols compared");
   Require (Assertions > 12_000, "complete reference checks not bypassed");
   Put_Line ("V183_FAMILIES=" & Natural'Image (Families));
   Put_Line ("V183_SAMPLES=" & Natural'Image (Samples));
   Put_Line ("V183_TOKENS=" & Natural'Image (Tokens));
   Put_Line ("V183_ASSERTIONS=" & Natural'Image (Assertions));
   Put_Line ("V183_ONE_EXCEPTION_DP_GMP_PASS_ZERO_F");
end Issue29_V183_One_Exception_Tests;
