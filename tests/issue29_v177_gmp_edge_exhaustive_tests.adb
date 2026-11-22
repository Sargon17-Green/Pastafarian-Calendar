with Ada.Integer_Text_IO;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

--  Issue29 v177: production Count/Unrank versus an independently generated,
--  completely exhaustive oracle of ten distinct heterogeneous tiny families.
--  This test references NO full calendar, NO Normative_Oracle and NO F(c,t).
procedure Issue29_V177_GMP_Edge_Exhaustive_Tests is
   package G renames GNATCOLL.GMP.Integers;
   package Full renames Canonical_Full_Weave_GMP_V164;
   use type G.Big_Integer;

   Assertions : Natural := 0;
   Cases : Natural := 0;
   Compared_Ranks : Natural := 0;

   function GMP_Of (N : Natural) return G.Big_Integer is
     (G.Make (Ada.Strings.Fixed.Trim (Natural'Image (N), Ada.Strings.Both)));

   procedure Require (Condition : Boolean; Label : String) is
   begin
      Assertions := Assertions + 1;
      if not Condition then
         Ada.Text_IO.Put_Line ("FAILED_CHECK=" & Label);
         raise Program_Error with "v177 GMP exhaustive edge check failed";
      end if;
   end Require;

   function Valid (Lengths, Weave : Full.Natural_Array) return Boolean is
      M : constant Natural := Lengths'Length;
      Count : Full.Natural_Array (1 .. M) := (others => 0);
      First : Full.Natural_Array (1 .. M) := (others => 0);
      Last : Full.Natural_Array (1 .. M) := (others => 0);
      Sum : Natural := 0;
   begin
      for J in Lengths'Range loop
         Sum := Sum + Lengths (J);
      end loop;
      if Sum /= Weave'Length then
         return False;
      end if;
      for K in Weave'Range loop
         declare
            J : constant Natural := Weave (K);
            P : constant Natural := K - Weave'First + 1;
         begin
            if J not in 1 .. M then
               return False;
            end if;
            Count (J) := Count (J) + 1;
            if First (J) = 0 then
               First (J) := P;
            end if;
            Last (J) := P;
         end;
      end loop;
      for J in 1 .. M loop
         if Count (J) /= Lengths (Lengths'First + J - 1) then
            return False;
         end if;
         if J > 1 and then
           (First (J - 1) >= First (J)
            or else Last (J - 1) >= Last (J))
         then
            return False;
         end if;
      end loop;
      return True;
   end Valid;

   function Is_Less
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
   end Is_Less;

   procedure Check_Case (Reference : Ada.Text_IO.File_Type) is
      N_Months : Integer;
   begin
      Ada.Integer_Text_IO.Get (Reference, N_Months);
      Require (N_Months in 1 .. 47, "oracle months bounds");
      declare
         Lengths : Full.Natural_Array (1 .. Positive (N_Months));
         N_Ranks : Integer;
         Sum : Natural := 0;
      begin
         for J in Lengths'Range loop
            declare
               V : Integer;
            begin
               Ada.Integer_Text_IO.Get (Reference, V);
               Require (V in 2 .. 123, "oracle month length");
               Lengths (J) := Natural (V);
               Sum := Sum + Natural (V);
            end;
         end loop;
         Ada.Integer_Text_IO.Get (Reference, N_Ranks);
         Require (N_Ranks in 1 .. 100_000, "small reference rank count");
         declare
            F : Full.Family (Positive (N_Months));
            Actual_Count : G.Big_Integer;
            Previous : Full.Natural_Array (1 .. Sum) := (others => 0);
         begin
            Full.Build (F, Lengths);
            Full.Count (F, Actual_Count);
            Require (Actual_Count = GMP_Of (Natural (N_Ranks)),
                     "exact GMP count matches exhaustive reference");
            for Rank in 1 .. N_Ranks loop
               declare
                  Observed : constant Full.Natural_Array :=
                    Full.Unrank (F, GMP_Of (Rank));
               begin
                  Require (Observed'Length = Sum, "unrank sequence length");
                  for K in 1 .. Sum loop
                     declare
                        Expected_ID : Integer;
                     begin
                        Ada.Integer_Text_IO.Get (Reference, Expected_ID);
                        Require (Expected_ID in 1 .. N_Months,
                                 "reference token in expected month IDs");
                        Require (Observed (Observed'First + K - 1) =
                                  Natural (Expected_ID),
                                 "production unrank equals independent rank list");
                     end;
                  end loop;
                  Require (Valid (Lengths, Observed),
                           "multiplicity and normative first/last order");
                  if Rank > 1 then
                     Require (Is_Less (Previous, Observed),
                              "ranks strictly increase lexicographically");
                  end if;
                  Previous := Observed;
                  Compared_Ranks := Compared_Ranks + 1;
               end;
            end loop;

            declare
               Caught : Boolean := False;
            begin
               begin
                  declare
                     Ignored : constant Full.Natural_Array :=
                       Full.Unrank (F, GMP_Of (0));
                  begin
                     if Ignored'Length = 0 then null; end if;
                  end;
               exception
                  when Constraint_Error => Caught := True;
               end;
               Require (Caught, "reject zero rank");
            end;

            declare
               Caught : Boolean := False;
            begin
               begin
                  declare
                     Ignored : constant Full.Natural_Array :=
                       Full.Unrank (F, GMP_Of (Natural (N_Ranks + 1)));
                  begin
                     if Ignored'Length = 0 then null; end if;
                  end;
               exception
                  when Constraint_Error => Caught := True;
               end;
               Require (Caught, "reject rank > count");
            end;
         end;
         Cases := Cases + 1;
      end;
   end Check_Case;

   procedure Check_Catalan_47 is
      Lengths : constant Full.Natural_Array (1 .. 47) := (others => 2);
      F : Full.Family (47);
      Count : G.Big_Integer;
      Expected : constant G.Big_Integer :=
        G.Make ("33868773757191046886429490");
   begin
      Full.Build (F, Lengths);
      Full.Count (F, Count);
      Require (Count = Expected, "47 two-day months have Catalan(47) sequences");
      declare
         Minimum : constant Full.Natural_Array :=
           Full.Unrank (F, GMP_Of (1));
         Maximum : constant Full.Natural_Array :=
           Full.Unrank (F, Count);
      begin
         Require (Valid (Lengths, Minimum), "Catalan47 first legal");
         Require (Valid (Lengths, Maximum), "Catalan47 last legal");
         for J in 1 .. 47 loop
            Require (Minimum (2 * J - 1) = J
                       and then Minimum (2 * J) = J,
                     "Catalan47 exact lexicographically first");
            Require (Maximum (J) = J
                       and then Maximum (47 + J) = J,
                     "Catalan47 exact lexicographically last");
         end loop;
         Require (Is_Less (Minimum, Maximum),
                  "Catalan47 first rank precedes final rank");
      end;
   end Check_Catalan_47;

   procedure Check_Reject_Invalid_Inputs is
   begin
      declare
         F : Full.Family (1);
         Lengths : Full.Natural_Array (1 .. 1) := (1 => 1);
         Raised : Boolean := False;
      begin
         begin
            Full.Build (F, Lengths);
         exception
            when Constraint_Error => Raised := True;
         end;
         Require (Raised, "minimum month length 2");
      end;
      declare
         F : Full.Family (1);
         Lengths : Full.Natural_Array (1 .. 1) := (1 => 124);
         Raised : Boolean := False;
      begin
         begin
            Full.Build (F, Lengths);
         exception
            when Constraint_Error => Raised := True;
         end;
         Require (Raised, "maximum month length 123");
      end;
      declare
         F : Full.Family (48);
         Lengths : Full.Natural_Array (1 .. 48) := (others => 2);
         Raised : Boolean := False;
      begin
         begin
            Full.Build (F, Lengths);
         exception
            when Constraint_Error => Raised := True;
         end;
         Require (Raised, "reject 48 months");
      end;
      declare
         F : Full.Family (47);
         Lengths : Full.Natural_Array (1 .. 47) := (others => 123);
         Raised : Boolean := False;
      begin
         begin
            Full.Build (F, Lengths);
         exception
            when Constraint_Error => Raised := True;
         end;
         Require (Raised, "reject year length 5781 > 5778");
      end;
      declare
         F : Full.Family (1);
         Count : G.Big_Integer;
         Raised : Boolean := False;
      begin
         begin
            Full.Count (F, Count);
         exception
            when Program_Error => Raised := True;
         end;
         Require (Raised, "reject Count before Build");
      end;
      declare
         F : Full.Family (1);
         Lengths : Full.Natural_Array (1 .. 1) := (1 => 2);
         Raised : Boolean := False;
      begin
         Full.Build (F, Lengths);
         begin
            Full.Build (F, Lengths);
         exception
            when Program_Error => Raised := True;
         end;
         Require (Raised, "reject repeated Build");
      end;
   end Check_Reject_Invalid_Inputs;

   Reference : Ada.Text_IO.File_Type;
   N_Cases : Integer;
begin
   Ada.Text_IO.Open
     (Reference, Ada.Text_IO.In_File, "evidence/v177-reference.dat");
   Ada.Integer_Text_IO.Get (Reference, N_Cases);
   Require (N_Cases = 10, "all ten independent family types present");
   for I in 1 .. N_Cases loop
      Check_Case (Reference);
   end loop;
   Ada.Text_IO.Close (Reference);

   Require (Cases = 10, "all ten source-locked family cases checked");
   Require (Compared_Ranks = 305, "all 305 exhaustive ranks compared");
   Check_Catalan_47;
   Check_Reject_Invalid_Inputs;
   Require (Assertions > 1_000, "positive substantive GMP edge coverage");

   Ada.Text_IO.Put_Line ("ISSUE29_V177_GMP_EDGE_CASES=" & Natural'Image (Cases));
   Ada.Text_IO.Put_Line
     ("ISSUE29_V177_GMP_EDGE_RANKS=" & Natural'Image (Compared_Ranks));
   Ada.Text_IO.Put_Line
     ("ISSUE29_V177_GMP_EDGE_ASSERTIONS=" & Natural'Image (Assertions));
   Ada.Text_IO.Put_Line ("ISSUE29_V177_CATALAN47=" &
                         "33868773757191046886429490");
end Issue29_V177_GMP_Edge_Exhaustive_Tests;
