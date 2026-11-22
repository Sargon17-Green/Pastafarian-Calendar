with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

--  Issue29 v181: isolated max-domain exact unranking. ZERO Calendar_Date/F.
procedure Issue29_V181_Unrank_Extrema_Tests is
   package G renames GNATCOLL.GMP.Integers;
   package Full renames Canonical_Full_Weave_GMP_V164;
   use Ada.Text_IO;
   use type G.Big_Integer;
   Ref : File_Type;
   Assertions : Natural := 0;
   Cases : Natural := 0;
   Samples : Natural := 0;
   Tokens : Natural := 0;

   procedure Require (OK : Boolean; Label : String) is
   begin
      Assertions := Assertions + 1;
      if not OK then
         Put_Line ("V181_FAILED_CHECK=" & Label);
         raise Program_Error with "max-domain GMP Unrank extrema mismatch";
      end if;
   end Require;

   function Number return Natural is
   begin
      return Natural'Value
        (Ada.Strings.Fixed.Trim (Get_Line (Ref), Ada.Strings.Both));
   end Number;
begin
   Open (Ref, In_File, "evidence/v181-unrank-extrema-reference.dat");
   Require (Number = 3, "three maximum-domain families");
   for Case_Id in 1 .. 3 loop
      declare
         M : constant Positive := Number;
         Lengths : Full.Natural_Array (1 .. M);
         F : Full.Family (M);
         Expected_Count : G.Big_Integer;
         Count : G.Big_Integer;
         Total : Natural := 0;
      begin
         Require (M = 47, "maximal 47-month family");
         for J in Lengths'Range loop
            Lengths (J) := Number;
            Require (Lengths (J) in 2 .. 123, "individual month length");
            Total := Total + Lengths (J);
         end loop;
         Require (Total >= 5_734 and then Total <= 5_778,
                  "near-maximum year length");
         G.Set (Expected_Count, G.Make (Get_Line (Ref)));
         Full.Build (F, Lengths);
         Full.Count (F, Count);
         Require (Count = Expected_Count, "full exact Count");
         for Side in 1 .. 2 loop
            declare
               Rank : G.Big_Integer;
            begin
               if Side = 1 then
                  G.Set (Rank, G.Make ("1"));
               else
                  G.Set (Rank, Count);
               end if;
               declare
                  W : constant Full.Natural_Array := Full.Unrank (F, Rank);
                  Seen : Full.Natural_Array (1 .. M) := (others => 0);
               begin
                  Require (W'Length = Total, "entire returned length");
                  Require (W (W'First) = 1 and then W (W'Last) = M,
                           "first/last canonical labels");
                  for P in W'Range loop
                     declare
                        Expected_Token : constant Natural := Number;
                     begin
                        Require (Expected_Token in 1 .. M,
                                 "expected label range");
                        Require (W (P) = Expected_Token,
                                 "exact independently constructed lexicographic extreme");
                        Seen (W (P)) := Seen (W (P)) + 1;
                        Tokens := Tokens + 1;
                     end;
                  end loop;
                  for J in Seen'Range loop
                     Require (Seen (J) = Lengths (J), "all month multiplicities");
                  end loop;
               end;
               Samples := Samples + 1;
            end;
         end loop;
         Cases := Cases + 1;
      end;
   end loop;
   Require (End_Of_File (Ref), "all and only expected tokens consumed");
   Close (Ref);
   Require (Cases = 3 and then Samples = 6, "three families times two ranks");
   Require (Tokens = 2 * (5_778 + 5_778 + 5_734),
            "all 34,580 synthetic-day tokens checked");
   Require (Assertions > 69_000, "full-token assertions were exercised");
   Put_Line ("V181_GMP_EXTREMA_CASES=" & Natural'Image (Cases));
   Put_Line ("V181_GMP_EXTREMA_SAMPLES=" & Natural'Image (Samples));
   Put_Line ("V181_GMP_EXTREMA_TOKENS=" & Natural'Image (Tokens));
   Put_Line ("V181_GMP_EXTREMA_ASSERTIONS=" & Natural'Image (Assertions));
   Put_Line ("V181_GMP_EXTREMA_PASS_ZERO_CALENDAR_F");
end Issue29_V181_Unrank_Extrema_Tests;
