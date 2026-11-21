with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;
with Month_Weaving;

procedure Issue29_V173_GMP_Weave_Tests is
   package Std renames Ada.Numerics.Big_Numbers.Big_Integers;
   package G renames GNATCOLL.GMP.Integers;
   package Full renames Canonical_Full_Weave_GMP_V164;
   package Ref renames Month_Weaving;
   use type G.Big_Integer;

   Assertions : Natural := 0;

   function GMP_Of (N : Natural) return G.Big_Integer is
     (G.Make (Ada.Strings.Fixed.Trim (Natural'Image (N), Ada.Strings.Both)));

   function Std_Of (N : Natural) return Std.Big_Integer is
     (Std.To_Big_Integer (Integer (N)));

   procedure Require (Condition : Boolean; Label : String) is
   begin
      Assertions := Assertions + 1;
      if not Condition then
         Ada.Text_IO.Put_Line ("CHECK=" & Label);
         raise Program_Error with "v173 production GMP weave assertion failed";
      end if;
   end Require;

   function Same
     (Observed : Full.Natural_Array; Expected : Ref.Natural_Array)
      return Boolean
   is
   begin
      if Observed'Length = 0 or else Observed'Length /= Expected'Length then
         return False;
      end if;
      for K in 0 .. Observed'Length - 1 loop
         if Observed (Observed'First + K) /= Expected (Expected'First + K) then
            return False;
         end if;
      end loop;
      return True;
   end Same;

   function Lexicographically_Less
     (Left, Right : Full.Natural_Array) return Boolean
   is
   begin
      if Left'Length /= Right'Length then
         return False;
      end if;
      for K in 0 .. Left'Length - 1 loop
         if Left (Left'First + K) < Right (Right'First + K) then
            return True;
         elsif Left (Left'First + K) > Right (Right'First + K) then
            return False;
         end if;
      end loop;
      return False;
   end Lexicographically_Less;

   procedure Check_Shape
     (Lengths, Weave : Full.Natural_Array; Label : String)
   is
      Month_Count : constant Natural := Lengths'Length;
      Total : Natural := 0;
      Counts : Full.Natural_Array (1 .. Lengths'Length) := (others => 0);
   begin
      for J in Lengths'Range loop
         Total := Total + Lengths (J);
      end loop;

      Require (Weave'Length = Total, Label & ":length");
      for J in 1 .. Month_Count loop
         Require (Weave (J) = J, Label & ":opening" & Natural'Image (J));
         Require
           (Weave (Total - Month_Count + J) = J,
            Label & ":closing" & Natural'Image (J));
      end loop;

      for P in Weave'Range loop
         if Weave (P) not in 1 .. Month_Count then
            raise Program_Error with "GMP weave contains an invalid month id";
         end if;
         Counts (Weave (P)) := Counts (Weave (P)) + 1;
      end loop;

      for J in 1 .. Month_Count loop
         Require
           (Counts (J) = Lengths (J),
            Label & ":multiplicity" & Natural'Image (J));
      end loop;
   end Check_Shape;

   Small_Lengths : constant Full.Natural_Array (1 .. 2) := (4, 4);
   Three_Lengths : constant Full.Natural_Array (1 .. 3) := (4, 5, 4);
   Large_Lengths : constant Full.Natural_Array (1 .. 45) := (others => 94);

   Small_Family : Full.Family (2);
   Three_Family : Full.Family (3);
   Large_Family : Full.Family (45);

begin
   --  Compare every rank in the two-month family with the independent
   --  standard-Big_Integer Month_Weaving reference implementation.
   Full.Build (Small_Family, Small_Lengths);
   declare
      Total : G.Big_Integer;
   begin
      Full.Count (Small_Family, Total);
      Require (Total = GMP_Of (6), "two-month exact family count");
   end;

   for Rank in 1 .. 6 loop
      declare
         Observed : constant Full.Natural_Array :=
           Full.Unrank (Small_Family, GMP_Of (Rank));
         Expected : constant Ref.Natural_Array :=
           Ref.Unrank_Canonical_Weave
             (Ref.Natural_Array (Small_Lengths), Std_Of (Rank));
      begin
         Require (Same (Observed, Expected), "two-month GMP/reference rank" & Natural'Image (Rank));
         Check_Shape (Small_Lengths, Observed, "two-month rank" & Natural'Image (Rank));
      end;
   end loop;

   --  The lower and upper invalid rank boundaries must both be rejected.
   for Bad_Rank in 0 .. 0 loop
      declare
         Raised : Boolean := False;
      begin
         begin
            declare
               Ignored : constant Full.Natural_Array :=
                 Full.Unrank (Small_Family, GMP_Of (Bad_Rank));
            begin
               if Ignored'Length = 0 then
                  null;
               end if;
            end;
         exception
            when Constraint_Error =>
               Raised := True;
         end;
         Require (Raised, "two-month rejected rank" & Natural'Image (Bad_Rank));
      end;
   end loop;

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Ignored : constant Full.Natural_Array :=
              Full.Unrank (Small_Family, GMP_Of (7));
         begin
            if Ignored'Length = 0 then
               null;
            end if;
         end;
      exception
         when Constraint_Error =>
            Raised := True;
      end;
      Require (Raised, "two-month rejected rank above count");
   end;

   --  Compare all 210 ranks for a three-month family and independently verify
   --  strict lexicographic ordering and both fixed rails.
   Full.Build (Three_Family, Three_Lengths);
   declare
      Total : G.Big_Integer;
      Previous : Full.Natural_Array (1 .. 13) := (others => 0);
      Have_Previous : Boolean := False;
   begin
      Full.Count (Three_Family, Total);
      Require (Total = GMP_Of (210), "three-month exact family count");

      for Rank in 1 .. 210 loop
         declare
            Observed : constant Full.Natural_Array :=
              Full.Unrank (Three_Family, GMP_Of (Rank));
            Expected : constant Ref.Natural_Array :=
              Ref.Unrank_Canonical_Weave
                (Ref.Natural_Array (Three_Lengths), Std_Of (Rank));
         begin
            Require
              (Same (Observed, Expected),
               "three-month GMP/reference rank" & Natural'Image (Rank));
            Check_Shape
              (Three_Lengths, Observed, "three-month rank" & Natural'Image (Rank));
            if Have_Previous then
               Require
                 (Lexicographically_Less (Previous, Observed),
                  "three-month strict lexicographic order" & Natural'Image (Rank));
            end if;
            Previous := Observed;
            Have_Previous := True;
         end;
      end loop;
   end;

   --  Exercise the production GMP path at the 45-month/4,230-day boundary:
   --  exact huge count, first and last global ranks, full shape and rails.
   Full.Build (Large_Family, Large_Lengths);
   declare
      Total : G.Big_Integer;
   begin
      Full.Count (Large_Family, Total);
      Require (Total > GMP_Of (1), "45-month GMP family has multiple legal weaves");

      declare
         First_Weave : constant Full.Natural_Array :=
           Full.Unrank (Large_Family, GMP_Of (1));
         Last_Weave : constant Full.Natural_Array :=
           Full.Unrank (Large_Family, Total);
      begin
         Check_Shape (Large_Lengths, First_Weave, "45-month first global rank");
         Check_Shape (Large_Lengths, Last_Weave, "45-month last global rank");
         Require (First_Weave (46) = 1, "45-month first interior symbol");
         Require (Last_Weave (46) = 45, "45-month last interior symbol");
      end;
   end;

   if Assertions /= 2_846 then
      raise Program_Error with "v173 expected exactly 2846 GMP weave assertions";
   end if;

   Ada.Text_IO.Put_Line
     ("STAGE13_GMP_WEAVE_ASSERTIONS=" & Natural'Image (Assertions));
end Issue29_V173_GMP_Weave_Tests;
