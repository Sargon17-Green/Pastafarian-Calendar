with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Wide_Rank_GMP_V164;

--  Issue #29 v182: global rank spans 248 radix-M places; ZERO calendar F.
procedure Issue29_V182_Rank_P248_Tests is
   package Std renames Ada.Numerics.Big_Numbers.Big_Integers;
   package G renames GNATCOLL.GMP.Integers;
   package Wide renames Canonical_Wide_Rank_GMP_V164;
   use Ada.Text_IO;
   use type Std.Big_Integer;
   use type G.Big_Integer;
   One_Std : constant Std.Big_Integer := Std.To_Big_Integer (1);
   M_Std : constant Std.Big_Integer :=
     (Std.To_Big_Integer (2) ** 127) - One_Std;
   One_GMP : constant G.Big_Integer := G.Make ("1");
   Ref : File_Type;
   Cases : Natural := 0;
   Assertions : Natural := 0;

   procedure Require (OK : Boolean; Label : String) is
   begin
      Assertions := Assertions + 1;
      if not OK then
         Put_Line ("V182_FAILED_CHECK=" & Label);
         raise Program_Error with "248-place GMP global rank mismatch";
      end if;
   end Require;

   function Number return Natural is
   begin
      return Natural'Value
        (Ada.Strings.Fixed.Trim (Get_Line (Ref), Ada.Strings.Both));
   end Number;
begin
   Open (Ref, In_File, "evidence/v182-rank-p248-reference.dat");
   Require (Number = 6, "six wide-rank oracle vectors");
   declare
      N : G.Big_Integer;
   begin
      G.Set (N, G.Make (Get_Line (Ref)));
      Require (N > One_GMP, "nontrivial exact rank domain");
      for K in 1 .. 6 loop
         declare
            Code : constant Natural := Number;
            Step : constant Integer := Integer'Value (Get_Line (Ref));
            Expected : G.Big_Integer;
            Actual : G.Big_Integer;
         begin
            Require (Code in 1 .. 3, "legal First source");
            Require (Step = -1 or else Step = 1, "legal direction");
            G.Set (Expected, G.Make (Get_Line (Ref)));
            declare
               First : constant Std.Big_Integer :=
                 (if Code = 1 then One_Std
                  elsif Code = 2 then M_Std / Std.To_Big_Integer (2)
                  else M_Std);
            begin
               Wide.Choose_Rank (First, Step, N, Actual);
            end;
            Require (Actual = Expected, "exact closed-form 248-place GMP rank");
            Require (Actual >= One_GMP and then Actual <= N, "rank in global family");
            if Step = -1 and then (Code = 1 or else Code = 3) then
               Require (Actual = N, "descending reject endpoint is N");
            end if;
            Cases := Cases + 1;
         end;
      end loop;
      Require (End_Of_File (Ref), "no unconsumed rank oracle entries");
      Require (Cases = 6, "all six streams checked");
      Require (Assertions >= 28, "substantive exact comparisons performed");
   end;
   Close (Ref);
   Put_Line ("V182_GMP_WIDE_RANK_PLACES= 248");
   Put_Line ("V182_GMP_WIDE_RANK_CASES=" & Natural'Image (Cases));
   Put_Line ("V182_GMP_WIDE_RANK_ASSERTIONS=" & Natural'Image (Assertions));
   Put_Line ("V182_GMP_WIDE_RANK_P248_CLOSED_FORM_PASS_ZERO_F");
end Issue29_V182_Rank_P248_Tests;
