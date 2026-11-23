with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;
with Canonical_Wide_Rank_GMP_V164;

--  GMP component failure contracts. No Calendar_Date or F(c,t).
--  Every expected exception has an explicit flag OUTSIDE the exception
--  handler, so a locally raised test failure can never count as a PASS.
procedure Issue29_V185_Negative_Contract_Tests is
   package Std renames Ada.Numerics.Big_Numbers.Big_Integers;
   package G renames GNATCOLL.GMP.Integers;
   package Full renames Canonical_Full_Weave_GMP_V164;
   package Wide renames Canonical_Wide_Rank_GMP_V164;
   use Ada.Text_IO;
   use type G.Big_Integer;
   use type Std.Big_Integer;

   M : constant Std.Big_Integer :=
     (Std.To_Big_Integer (2) ** 127) - Std.To_Big_Integer (1);
   One_Std : constant Std.Big_Integer := Std.To_Big_Integer (1);
   N_Two : constant G.Big_Integer := G.Make ("2");
   Checks : Natural := 0;
   Fail_Closed_Cases : Natural := 0;
   Accepted_Cases : Natural := 0;

   procedure Require (OK : Boolean; Name : String) is
   begin
      Checks := Checks + 1;
      if not OK then
         Put_Line ("V185_FAILED_CHECK=" & Name);
         raise Program_Error with "v185 GMP validation contract failed";
      end if;
   end Require;

   procedure Check_Unbuilt_And_Rank is
      F : Full.Family (2);
      C : G.Big_Integer;
      Raised : Boolean;
   begin
      Raised := False;
      begin
         Full.Count (F, C);
      exception
         when Program_Error => Raised := True;
      end;
      Require (Raised, "Count rejects family before Build");
      Fail_Closed_Cases := Fail_Closed_Cases + 1;

      Raised := False;
      begin
         declare
            W : constant Full.Natural_Array :=
              Full.Unrank (F, G.Make ("1"));
         begin
            Require (W'Length = 0, "unbuilt Unrank must not return");
         end;
      exception
         when Program_Error => Raised := True;
      end;
      Require (Raised, "Unrank rejects family before Build");
      Fail_Closed_Cases := Fail_Closed_Cases + 1;

      Full.Build (F, (1 => 2, 2 => 2));
      Full.Count (F, C);
      Require (C = N_Two, "minimal legal two-month full family has exactly two weaves");
      declare
         A : constant Full.Natural_Array := Full.Unrank (F, G.Make ("1"));
         B : constant Full.Natural_Array := Full.Unrank (F, G.Make ("2"));
      begin
         Require (A = (1, 1, 2, 2), "first legal minimal weave");
         Require (B = (1, 2, 1, 2), "last legal minimal weave");
      end;
      Accepted_Cases := Accepted_Cases + 1;

      Raised := False;
      begin
         Full.Build (F, (1 => 2, 2 => 2));
      exception
         when Program_Error => Raised := True;
      end;
      Require (Raised, "Build rejects second build of same limited family");
      Fail_Closed_Cases := Fail_Closed_Cases + 1;

      Raised := False;
      begin
         declare
            W : constant Full.Natural_Array :=
              Full.Unrank (F, G.Make ("0"));
         begin
            Require (W'Length = 0, "rank-zero Unrank must not return");
         end;
      exception
         when Constraint_Error => Raised := True;
      end;
      Require (Raised, "Unrank rejects rank zero");
      Fail_Closed_Cases := Fail_Closed_Cases + 1;

      Raised := False;
      begin
         declare
            W : constant Full.Natural_Array :=
              Full.Unrank (F, G.Make ("3"));
         begin
            Require (W'Length = 0, "overmaximum Unrank must not return");
         end;
      exception
         when Constraint_Error => Raised := True;
      end;
      Require (Raised, "Unrank rejects rank Count+1");
      Fail_Closed_Cases := Fail_Closed_Cases + 1;
   end Check_Unbuilt_And_Rank;

   procedure Check_Invalid_Families is
      Raised : Boolean;
   begin
      declare
         F : Full.Family (2);
      begin
         Raised := False;
         begin
            Full.Build (F, (1 => 1, 2 => 2));
         exception
            when Constraint_Error => Raised := True;
         end;
         Require (Raised, "month length one rejected");
         Fail_Closed_Cases := Fail_Closed_Cases + 1;
      end;

      declare
         F : Full.Family (2);
      begin
         Raised := False;
         begin
            Full.Build (F, (1 => 2, 2 => 124));
         exception
            when Constraint_Error => Raised := True;
         end;
         Require (Raised, "month length 124 rejected");
         Fail_Closed_Cases := Fail_Closed_Cases + 1;
      end;

      declare
         F : Full.Family (2);
      begin
         Raised := False;
         begin
            Full.Build (F, (1 => 2, 2 => 2, 3 => 2));
         exception
            when Constraint_Error => Raised := True;
         end;
         Require (Raised, "Length array incompatible with discriminant rejected");
         Fail_Closed_Cases := Fail_Closed_Cases + 1;
      end;

      declare
         F : Full.Family (48);
         L : constant Full.Natural_Array (1 .. 48) := (others => 4);
      begin
         Raised := False;
         begin
            Full.Build (F, L);
         exception
            when Constraint_Error => Raised := True;
         end;
         Require (Raised, "48 months rejected");
         Fail_Closed_Cases := Fail_Closed_Cases + 1;
      end;

      declare
         F : Full.Family (47);
         L : constant Full.Natural_Array (1 .. 47) := (others => 123);
      begin
         Raised := False;
         begin
            Full.Build (F, L);
         exception
            when Constraint_Error => Raised := True;
         end;
         Require (Raised, "47x123=5781 days rejected");
         Fail_Closed_Cases := Fail_Closed_Cases + 1;
      end;

      declare
         F : Full.Family (47);
         L : Full.Natural_Array (1 .. 47) := (others => 123);
         C : G.Big_Integer;
      begin
         L (47) := 120;
         Full.Build (F, L);
         Full.Count (F, C);
         Require (C > G.Make ("1"), "exact 5778-day legal upper envelope accepted");
         Require (G.Image (C)'Length > 9000,
                  "upper-envelope count is genuinely arbitrary precision");
         Accepted_Cases := Accepted_Cases + 1;
      end;
   end Check_Invalid_Families;

   procedure Check_Wide_Rank_Boundaries is
      Result : G.Big_Integer;
      Raised : Boolean;
   begin
      Raised := False;
      begin
         Wide.Choose_Rank (One_Std, 0, N_Two, Result);
      exception
         when Constraint_Error => Raised := True;
      end;
      Require (Raised, "wide rank rejects zero direction");
      Fail_Closed_Cases := Fail_Closed_Cases + 1;

      Raised := False;
      begin
         Wide.Choose_Rank (One_Std, 2, N_Two, Result);
      exception
         when Constraint_Error => Raised := True;
      end;
      Require (Raised, "wide rank rejects step plus two");
      Fail_Closed_Cases := Fail_Closed_Cases + 1;

      Raised := False;
      begin
         Wide.Choose_Rank (One_Std, -2, N_Two, Result);
      exception
         when Constraint_Error => Raised := True;
      end;
      Require (Raised, "wide rank rejects step minus two");
      Fail_Closed_Cases := Fail_Closed_Cases + 1;

      Raised := False;
      begin
         Wide.Choose_Rank (Std.To_Big_Integer (0), 1, N_Two, Result);
      exception
         when Constraint_Error => Raised := True;
      end;
      Require (Raised, "wide rank rejects first answer zero");
      Fail_Closed_Cases := Fail_Closed_Cases + 1;

      Raised := False;
      begin
         Wide.Choose_Rank (M + One_Std, 1, N_Two, Result);
      exception
         when Constraint_Error => Raised := True;
      end;
      Require (Raised, "wide rank rejects first answer M+1");
      Fail_Closed_Cases := Fail_Closed_Cases + 1;

      Raised := False;
      begin
         Wide.Choose_Rank (One_Std, 1, G.Make ("0"), Result);
      exception
         when Constraint_Error => Raised := True;
      end;
      Require (Raised, "wide rank rejects zero-size family");
      Fail_Closed_Cases := Fail_Closed_Cases + 1;

      Raised := False;
      begin
         Wide.Choose_Rank (One_Std, 1, G.Make ("-1"), Result);
      exception
         when Constraint_Error => Raised := True;
      end;
      Require (Raised, "wide rank rejects negative-size family");
      Fail_Closed_Cases := Fail_Closed_Cases + 1;

      Wide.Choose_Rank (One_Std, 1, G.Make ("1"), Result);
      Require (Result = G.Make ("1"), "single-element family exact rank");
      Accepted_Cases := Accepted_Cases + 1;

      Wide.Choose_Rank (M, -1, N_Two, Result);
      Require (Result = N_Two, "descending rejection snaps to largest rank");
      Accepted_Cases := Accepted_Cases + 1;

      Wide.Choose_Rank (M, 1, N_Two, Result);
      Require (Result = G.Make ("1"), "ascending rejection wraps to first rank");
      Accepted_Cases := Accepted_Cases + 1;

      Wide.Choose_Rank (One_Std, 1, G.Make (Std.To_String (M + One_Std)), Result);
      Require (Result = G.Make (Std.To_String (M + One_Std)),
               "2-place GMP wide-rank domain M+1 boundary");
      Accepted_Cases := Accepted_Cases + 1;
   end Check_Wide_Rank_Boundaries;
begin
   Check_Unbuilt_And_Rank;
   Check_Invalid_Families;
   Check_Wide_Rank_Boundaries;
   Require (Fail_Closed_Cases = 17, "all negative contract cases exercised");
   Require (Accepted_Cases = 6, "all control families/stream cases exercised");
   Require (Checks >= 29, "real validation assertions executed");
   Put_Line ("V185_FAIL_CLOSED_CASES=" & Natural'Image (Fail_Closed_Cases));
   Put_Line ("V185_ACCEPTED_CONTROLS=" & Natural'Image (Accepted_Cases));
   Put_Line ("V185_ASSERTIONS=" & Natural'Image (Checks));
   Put_Line ("V185_GMP_NEGATIVE_CONTRACTS_EXACT_PASS_ZERO_F");
end Issue29_V185_Negative_Contract_Tests;
