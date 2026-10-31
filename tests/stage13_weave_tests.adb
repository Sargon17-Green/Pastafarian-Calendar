with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Month_Weaving;

procedure Stage13_Weave_Tests is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Month_Weaving;

   function B (N : Natural) return Big_Integer is
     (To_Big_Integer (Integer (N)));

   Assertions : Natural := 0;

   procedure Require (Condition : Boolean; Name : String) is
   begin
      Assertions := Assertions + 1;
      if not Condition then
         Ada.Text_IO.Put_Line ("CHECK=" & Name);
         raise Program_Error with "Stage13 canonical weave assertion failed";
      end if;
   end Require;

   type Small_Weave is array (Positive range 1 .. 8) of Natural;
   type Small_Weave_Table is array (Positive range 1 .. 6) of Small_Weave;
   Expected_Small : constant Small_Weave_Table :=
     (1 => (1, 2, 1, 1, 2, 2, 1, 2),
      2 => (1, 2, 1, 2, 1, 2, 1, 2),
      3 => (1, 2, 1, 2, 2, 1, 1, 2),
      4 => (1, 2, 2, 1, 1, 2, 1, 2),
      5 => (1, 2, 2, 1, 2, 1, 1, 2),
      6 => (1, 2, 2, 2, 1, 1, 1, 2));

   type Three_Weave is array (Positive range 1 .. 13) of Natural;
   Expected_Three_First : constant Three_Weave :=
     (1, 2, 3, 1, 1, 2, 2, 2, 3, 3, 1, 2, 3);
   Expected_Three_Middle : constant Three_Weave :=
     (1, 2, 3, 2, 2, 2, 1, 3, 3, 1, 1, 2, 3);
   Expected_Three_Last : constant Three_Weave :=
     (1, 2, 3, 3, 3, 2, 2, 2, 1, 1, 1, 2, 3);

   function Matches (Observed : Natural_Array; Expected : Three_Weave)
     return Boolean
   is
   begin
      if Observed'Length /= Expected'Length then
         return False;
      end if;
      for I in Expected'Range loop
         if Observed (I) /= Expected (I) then
            return False;
         end if;
      end loop;
      return True;
   end Matches;

   function Lexicographically_Less (Left, Right : Natural_Array)
     return Boolean
   is
   begin
      for I in Left'Range loop
         if Left (I) < Right (I) then
            return True;
         elsif Left (I) > Right (I) then
            return False;
         end if;
      end loop;
      return False;
   end Lexicographically_Less;

   procedure Check_Shape
     (Lengths, Weave : Natural_Array; Name : String)
   is
      Month_Count : constant Natural := Lengths'Length;
      Total : Natural := 0;
      Counts : Natural_Array (1 .. Month_Count) := (others => 0);
   begin
      for J in Lengths'Range loop
         Total := Total + Lengths (J);
      end loop;

      Require (Weave'Length = Total, Name & ":length");
      for J in 1 .. Month_Count loop
         Require (Weave (J) = J, Name & ":opening rail" & Positive'Image (J));
         Require
           (Weave (Total - Month_Count + J) = J,
            Name & ":closing rail" & Positive'Image (J));
      end loop;

      for P in Weave'Range loop
         if Weave (P) not in 1 .. Month_Count then
            raise Program_Error with "Canonical weave contains an invalid month id";
         end if;
         Counts (Weave (P)) := Counts (Weave (P)) + 1;
      end loop;

      for J in 1 .. Month_Count loop
         Require
           (Counts (J) = Lengths (J),
            Name & ":month multiplicity" & Positive'Image (J));
      end loop;
   end Check_Shape;

   Small_Lengths : constant Natural_Array (1 .. 2) := (4, 4);
   Three_Lengths : constant Natural_Array (1 .. 3) := (4, 5, 4);
   Large_Lengths : constant Natural_Array (1 .. 45) := (others => 94);

begin
   Require
     (Canonical_Weave_Count (Small_Lengths) = B (6),
      "two-month exact family count");

   for Rank in Expected_Small'Range loop
      declare
         Observed : constant Natural_Array :=
           Unrank_Canonical_Weave (Small_Lengths, B (Rank));
         Copy : Small_Weave;
      begin
         for I in Copy'Range loop
            Copy (I) := Observed (I);
         end loop;
         Require (Copy = Expected_Small (Rank), "two-month exact lexicographic rank");
      end;
   end loop;

   Require
     (Canonical_Weave_Count (Three_Lengths) = B (210),
      "three-month multinomial family count");

   declare
      Previous : Natural_Array (1 .. 13) := (others => 0);
      Have_Previous : Boolean := False;
   begin
      for Rank in 1 .. 210 loop
         declare
            Observed : constant Natural_Array :=
              Unrank_Canonical_Weave (Three_Lengths, B (Rank));
         begin
            Check_Shape (Three_Lengths, Observed, "three-month rank");
            if Have_Previous then
               Require
                 (Lexicographically_Less (Previous, Observed),
                  "strict rank order" & Positive'Image (Rank));
            end if;

            if Rank = 1 then
               Require (Matches (Observed, Expected_Three_First), "three-month first rank");
            elsif Rank = 105 then
               Require (Matches (Observed, Expected_Three_Middle), "three-month middle rank");
            elsif Rank = 210 then
               Require (Matches (Observed, Expected_Three_Last), "three-month last rank");
            end if;

            Previous := Observed;
            Have_Previous := True;
         end;
      end loop;
   end;

   declare
      Interior : constant Positive := 45 * (94 - 2);
      First_Picks : constant Natural_Array (1 .. Interior) := (others => 1);
      Last_Picks : Natural_Array (1 .. Interior);
   begin
      for I in Last_Picks'Range loop
         Last_Picks (I) := Interior - I + 1;
      end loop;
      declare
         First_Weave : constant Natural_Array :=
           From_Choices (Large_Lengths, First_Picks);
         Last_Weave : constant Natural_Array :=
           From_Choices (Large_Lengths, Last_Picks);
      begin
         Require (First_Weave /= Last_Weave, "45-month distinct extremes");
         Check_Shape (Large_Lengths, First_Weave, "45-month first tickets");
         Check_Shape (Large_Lengths, Last_Weave, "45-month last tickets");
         Require (First_Weave (46) = 1, "45-month first interior symbol");
         Require (Last_Weave (46) = 45, "45-month last interior symbol");
      end;
   end;

   if Assertions /= 2_595 then
      raise Program_Error with "Stage13 weave test assertion count mismatch";
   end if;

   Ada.Text_IO.Put_Line
     ("STAGE13_PATCH01_WEAVE_ASSERTIONS=" & Natural'Image (Assertions));
end Stage13_Weave_Tests;
