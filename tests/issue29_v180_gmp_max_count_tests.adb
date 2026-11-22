with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

--  Issue #29 v180: Count-only maximum legal month/year envelope.
--  This is synthetic GMP-only QA. DO NOT import Normative_Oracle/F.
procedure Issue29_V180_GMP_Max_Count_Tests is
   package G renames GNATCOLL.GMP.Integers;
   package Full renames Canonical_Full_Weave_GMP_V164;
   use Ada.Text_IO;
   use type G.Big_Integer;
   Ref : File_Type;
   Cases : Natural := 0;
   Assertions : Natural := 0;
   procedure Require (OK : Boolean; Label : String) is
   begin
      Assertions := Assertions + 1;
      if not OK then
         Put_Line ("V180_FAILED_CHECK=" & Label);
         raise Program_Error with "GMP Count does not match independent exact reference";
      end if;
   end Require;
   function Number return Natural is
   begin
      return Natural'Value
        (Ada.Strings.Fixed.Trim (Get_Line (Ref), Ada.Strings.Both));
   end Number;
begin
   Open (Ref, In_File, "evidence/v180-max-count-reference.dat");
   Require (Number = 5, "exact five max-domain count cases");
   for K in 1 .. 5 loop
      declare
         M : constant Positive := Number;
         Lengths : Full.Natural_Array (1 .. M);
         F : Full.Family (M);
         Expected : G.Big_Integer;
         Actual : G.Big_Integer;
         Total : Natural := 0;
      begin
         Require (M in 46 .. 47, "month count within tested envelope");
         for J in Lengths'Range loop
            Lengths (J) := Number;
            Require (Lengths (J) in 2 .. 123, "allowed individual month length");
            Total := Total + Lengths (J);
         end loop;
         Require (Total <= 5_778, "maximum legal year length");
         G.Set (Expected, G.Make (Get_Line (Ref)));
         Full.Build (F, Lengths);
         Full.Count (F, Actual);
         Require (Actual = Expected, "exact large GMP Count match");
         Cases := Cases + 1;
      end;
   end loop;
   Require (End_Of_File (Ref), "no trailing fixture tokens");
   --  47 x 123 is precisely 5,781 days and must fail closed.
   declare
      Bad : Full.Family (47);
      Too_Long : constant Full.Natural_Array (1 .. 47) :=
        (others => 123);
   begin
      begin
         Full.Build (Bad, Too_Long);
         Require (False, "overlength family unexpectedly accepted");
      exception
         when Constraint_Error =>
            Require (True, "overlength family rejected");
      end;
   end;
   Close (Ref);
   Require (Cases = 5, "five exact boundary Count cases");
   Require (Assertions >= 240, "lengths and counts actually verified");
   Put_Line ("V180_GMP_COUNT_CASES=" & Natural'Image (Cases));
   Put_Line ("V180_GMP_COUNT_ASSERTIONS=" & Natural'Image (Assertions));
   Put_Line ("V180_GMP_MAX_DOMAIN_EXACT_PASS_ZERO_F");
end Issue29_V180_GMP_Max_Count_Tests;
