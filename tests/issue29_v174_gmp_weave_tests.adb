with Ada.Integer_Text_IO;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

procedure Issue29_V174_GMP_Weave_Tests is
   package G renames GNATCOLL.GMP.Integers;
   package Full renames Canonical_Full_Weave_GMP_V164;
   use type G.Big_Integer;

   Assertions : Natural := 0;

   function GMP_Of (N : Natural) return G.Big_Integer is
     (G.Make (Ada.Strings.Fixed.Trim (Natural'Image (N), Ada.Strings.Both)));

   procedure Require (Condition : Boolean; Label : String) is
   begin
      Assertions := Assertions + 1;
      if not Condition then
         Ada.Text_IO.Put_Line ("CHECK=" & Label);
         raise Program_Error with "v174 exhaustive GMP weave assertion failed";
      end if;
   end Require;

   function Total_Length (Lengths : Full.Natural_Array) return Natural is
      Result : Natural := 0;
   begin
      for J in Lengths'Range loop
         Result := Result + Lengths (J);
      end loop;
      return Result;
   end Total_Length;

   function Same
     (Observed, Expected : Full.Natural_Array) return Boolean
   is
   begin
      if Observed'Length /= Expected'Length then
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

   --  Directly enforce the normative two ordering rules:
   --  first-occurrence positions increase with month id, and last-occurrence
   --  positions also increase with month id. There is no fixed prefix/suffix.
   function Is_Normatively_Valid
     (Lengths, Weave : Full.Natural_Array) return Boolean
   is
      M : constant Natural := Lengths'Length;
      Counts : Full.Natural_Array (1 .. Lengths'Length) := (others => 0);
      First_Position : Full.Natural_Array (1 .. Lengths'Length) := (others => 0);
      Last_Position : Full.Natural_Array (1 .. Lengths'Length) := (others => 0);
   begin
      if Weave'Length /= Total_Length (Lengths) then
         return False;
      end if;

      for P in Weave'Range loop
         declare
            J : constant Natural := Weave (P);
            Position : constant Natural := P - Weave'First + 1;
         begin
            if J not in 1 .. M then
               return False;
            end if;
            Counts (J) := Counts (J) + 1;
            if First_Position (J) = 0 then
               First_Position (J) := Position;
            end if;
            Last_Position (J) := Position;
         end;
      end loop;

      for J in 1 .. M loop
         if Counts (J) /= Lengths (Lengths'First + J - 1)
           or else First_Position (J) = 0
           or else Last_Position (J) = 0
         then
            return False;
         end if;
         if J > 1
           and then
             (First_Position (J - 1) >= First_Position (J)
              or else Last_Position (J - 1) >= Last_Position (J))
         then
            return False;
         end if;
      end loop;
      return True;
   end Is_Normatively_Valid;

   procedure Check_Family
     (Reference : in Ada.Text_IO.File_Type;
      Lengths : Full.Natural_Array;
      Expected_Count : Natural;
      Label : String)
   is
      M : constant Natural := Lengths'Length;
      Total : constant Natural := Total_Length (Lengths);
      Family : Full.Family (Lengths'Length);
      Header_Months : Integer;
      Header_Length : Integer;
      Header_Count : Integer;
      Actual_Count : G.Big_Integer;
      Previous : Full.Natural_Array (1 .. Total) := (others => 0);
   begin
      Ada.Integer_Text_IO.Get (Reference, Header_Months);
      Require (Header_Months = Integer (M), Label & ":reference month count");
      for J in Lengths'Range loop
         Ada.Integer_Text_IO.Get (Reference, Header_Length);
         Require
           (Header_Length = Integer (Lengths (J)),
            Label & ":reference month length" & Natural'Image (J));
      end loop;
      Ada.Integer_Text_IO.Get (Reference, Header_Count);
      Require
        (Header_Count = Integer (Expected_Count),
         Label & ":independent oracle expected count");

      Full.Build (Family, Lengths);
      Full.Count (Family, Actual_Count);
      Require
        (Actual_Count = GMP_Of (Expected_Count),
         Label & ":production GMP exact family count");

      --  Compare every legal sequence in rank order against the exhaustive
      --  multiset-permutation oracle, not against Month_Weaving.
      for Rank in 1 .. Expected_Count loop
         declare
            Expected : Full.Natural_Array (1 .. Total);
            Observed : constant Full.Natural_Array :=
              Full.Unrank (Family, GMP_Of (Rank));
            Value : Integer;
         begin
            for P in Expected'Range loop
               Ada.Integer_Text_IO.Get (Reference, Value);
               Require
                 (Value in 1 .. Integer (M),
                  Label & ":reference symbol range" & Natural'Image (Rank));
               Expected (P) := Natural (Value);
            end loop;

            Require
              (Same (Observed, Expected),
               Label & ":exact GMP/reference rank" & Natural'Image (Rank));
            Require
              (Is_Normatively_Valid (Lengths, Observed),
               Label & ":two ordering rules and multiplicity" & Natural'Image (Rank));
            if Rank > 1 then
               Require
                 (Lexicographically_Less (Previous, Observed),
                  Label & ":strict lexicographic order" & Natural'Image (Rank));
            end if;
            Previous := Observed;
         end;
      end loop;

      --  Both invalid boundaries must be rejected by the production package.
      declare
         Raised : Boolean := False;
      begin
         begin
            declare
               Ignored : constant Full.Natural_Array :=
                 Full.Unrank (Family, GMP_Of (0));
            begin
               if Ignored'Length = 0 then
                  null;
               end if;
            end;
         exception
            when Constraint_Error =>
               Raised := True;
         end;
         Require (Raised, Label & ":reject rank zero");
      end;

      declare
         Raised : Boolean := False;
      begin
         begin
            declare
               Ignored : constant Full.Natural_Array :=
                 Full.Unrank (Family, GMP_Of (Expected_Count + 1));
            begin
               if Ignored'Length = 0 then
                  null;
               end if;
            end;
         exception
            when Constraint_Error =>
               Raised := True;
         end;
         Require (Raised, Label & ":reject rank above exact count");
      end;
   end Check_Family;

   Small_Lengths : constant Full.Natural_Array (1 .. 2) := (4, 4);
   Three_Lengths : constant Full.Natural_Array (1 .. 3) := (4, 5, 4);
   Large_Lengths : constant Full.Natural_Array (1 .. 45) := (others => 94);

begin
   declare
      Reference : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Open
        (Reference, Ada.Text_IO.In_File, "evidence/v174-reference.dat");
      Check_Family (Reference, Small_Lengths, 20, "two-month family");
      Check_Family (Reference, Three_Lengths, 3_499, "three-month family");
      Ada.Text_IO.Close (Reference);
   end;

   --  Preserve the 45-month / 4,230-day production GMP boundary exercise,
   --  but do not assume the first and last m symbols form contiguous rails.
   declare
      Large_Family : Full.Family (45);
      Total : G.Big_Integer;
   begin
      Full.Build (Large_Family, Large_Lengths);
      Full.Count (Large_Family, Total);
      Require (Total > GMP_Of (1), "45-month GMP family has a nontrivial exact count");

      declare
         First_Weave : constant Full.Natural_Array :=
           Full.Unrank (Large_Family, GMP_Of (1));
         Last_Weave : constant Full.Natural_Array :=
           Full.Unrank (Large_Family, Total);
      begin
         Require
           (Is_Normatively_Valid (Large_Lengths, First_Weave),
            "45-month first global rank obeys both ordering rules");
         Require
           (Is_Normatively_Valid (Large_Lengths, Last_Weave),
            "45-month last global rank obeys both ordering rules");
         Require
           (Lexicographically_Less (First_Weave, Last_Weave),
            "45-month first rank precedes last rank");
      end;
   end;

   if Assertions /= 56_221 then
      raise Program_Error with
        "v174 expected exactly 56221 exhaustive GMP weave assertions";
   end if;

   Ada.Text_IO.Put_Line
     ("ISSUE29_V174_GMP_WEAVE_ASSERTIONS=" & Natural'Image (Assertions));
end Issue29_V174_GMP_Weave_Tests;
