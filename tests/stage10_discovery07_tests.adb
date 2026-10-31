with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Ada.Wide_Wide_Text_IO;
with Exact_Math;
with Normative_Oracle;

procedure Stage10_Discovery07_Tests is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Exact_Math;
   use Normative_Oracle;

   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));
   function Project (X : Big_Integer) return Big_Integer is
     (B (1) + ((X - B (1)) mod M));

   type Date_Pair is record
      Calculation_Day, Target_Day : Big_Integer;
   end record;
   Cases : constant array (Positive range 1 .. 8) of Date_Pair :=
     (1 => (Foundation_Day, Foundation_Day),
      2 => (Foundation_Day, Foundation_Day + B (1)),
      3 => (Foundation_Day, Foundation_Day - B (1)),
      4 => (Tablets_Day, Tablets_Day),
      5 => (Tablets_Day - B (1), Tablets_Day + B (31)),
      6 => (Foundation_Day + B (400), Foundation_Day - B (400)),
      7 => (Tablets_Day + B (1_000_000), Foundation_Day - B (1_000_000)),
      8 => (Foundation_Day - B (3_000_000), Tablets_Day + B (3_000_000)));
   Assertions : Natural := 0;

   procedure Compare
     (Observed, Expected : Big_Integer;
      Label_Text : Wide_Wide_String;
      Case_Number, Element_Number : Natural) is
   begin
      Assertions := Assertions + 1;
      if Observed /= Expected then
         Ada.Wide_Wide_Text_IO.Put_Line ("విఫలం: " & Label_Text);
         Ada.Text_IO.Put_Line
           ("CASE=" & Natural'Image (Case_Number)
            & " ELEMENT=" & Natural'Image (Element_Number)
            & " EXPECTED=" & To_String (Expected)
            & " OBSERVED=" & To_String (Observed));
         raise Program_Error;
      end if;
   end Compare;

   -- Work-count expectation independent from production Day_Count.
   function Reference_Day_Count (Day : Big_Integer) return Big_Integer is
   begin
      if Day < Foundation_Day then
         return B (2) * (Foundation_Day - Day);
      end if;
      return B (1) + B (2) * (Day - Foundation_Day);
   end Reference_Day_Count;

   function Reference_Counts
     (Calculation_Day, Target_Day : Big_Integer) return Work_Counts
   is
      A : constant Big_Integer := Reference_Day_Count (Calculation_Day);
      T : constant Big_Integer := Reference_Day_Count (Target_Day);
      D : Positive range 1 .. 3 := 2;
   begin
      if Calculation_Day > Target_Day then
         D := 1;
      elsif Calculation_Day < Target_Day then
         D := 3;
      end if;
      return (Action => A, Target => T,
              Distance => abs (Target_Day - Calculation_Day) + B (1),
              Connection => A + T, Direction => D);
   end Reference_Counts;

   -- Recurrence recomputed without Build_Stones, Save, or Square.
   function Reference_Stones return Stone_Table is
      Result : Stone_Table;
   begin
      Result (1) :=
        (Wheat => B (17), Barley => B (29), Salt => B (43),
         Bitter => B (71), Red => B (101));
      for I in 2 .. 46 loop
         declare
            S : constant Stone_Record := Result (I - 1);
         begin
            Result (I) :=
              (Wheat  => Project (S.Wheat * S.Wheat + B (3) * S.Barley + B (I)),
               Barley => Project (S.Barley * S.Barley + B (5) * S.Salt + S.Wheat),
               Salt   => Project (S.Salt * S.Salt + B (7) * S.Bitter + S.Barley),
               Bitter => Project (S.Bitter * S.Bitter + B (11) * S.Red + S.Salt),
               Red    => Project (S.Red * S.Red + B (13) * S.Wheat + S.Bitter));
         end;
      end loop;
      return Result;
   end Reference_Stones;

   type Coeff_Row is array (Positive range 1 .. 4) of Integer;
   type Coeff_Table is array (Positive range 1 .. 7) of Coeff_Row;
   Coeffs : constant Coeff_Table :=
     ((3, 4, 6, 8),
      (5, 7, 10, 12),
      (7, 10, 14, 16),
      (9, 13, 18, 20),
      (11, 16, 22, 24),
      (13, 19, 26, 28),
      (15, 22, 30, 32));

   function Stone_At (S : Stone_Record; Grind : Positive)
      return Big_Integer
   is
   begin
      case Grind is
         when 1 | 6 => return S.Wheat;
         when 2 | 7 => return S.Barley;
         when 3     => return S.Salt;
         when 4     => return S.Bitter;
         when 5     => return S.Red;
         when others => raise Constraint_Error;
      end case;
   end Stone_At;

   -- New test-only hidden-drop recurrence. No Build_Hidden_Drops.
   function Reference_Hidden
     (Counts : Work_Counts; Stones : Stone_Table) return Hidden_Drops
   is
      H : Hidden_Drops;
   begin
      for K in 1 .. 7 loop
         declare
            S : constant Stone_Record := Stones (K);
            X : Big_Integer :=
              Counts.Action
              + B (Coeffs (K) (1)) * Counts.Target
              + B (Coeffs (K) (2)) * Counts.Distance
              + B (Coeffs (K) (3)) * Counts.Connection
              + B (Coeffs (K) (4)) * B (Counts.Direction)
              + S.Wheat + S.Barley + S.Salt + S.Bitter + S.Red;
         begin
            X := Project (X);
            for G in 1 .. 7 loop
               X := Project
                 (X * X + B (3) * X + Stone_At (S, G) + B (G));
            end loop;
            H (K) := X;
         end;
      end loop;
      return H;
   end Reference_Hidden;

   Expected_Stones : constant Stone_Table := Reference_Stones;
   Observed_Stones : constant Stone_Table := Build_Stones;
begin
   -- One global stone table: 46 records x 5 independently checked fields.
   for I in 1 .. 46 loop
      Compare (Observed_Stones (I).Wheat, Expected_Stones (I).Wheat,
               "గోధుమ", 0, I);
      Compare (Observed_Stones (I).Barley, Expected_Stones (I).Barley,
               "యవలు", 0, I);
      Compare (Observed_Stones (I).Salt, Expected_Stones (I).Salt,
               "ఉప్పు", 0, I);
      Compare (Observed_Stones (I).Bitter, Expected_Stones (I).Bitter,
               "చేదు", 0, I);
      Compare (Observed_Stones (I).Red, Expected_Stones (I).Red,
               "ఎరుపు", 0, I);
   end loop;

   for I in Cases'Range loop
      declare
         Pair : constant Date_Pair := Cases (I);
         Expected_Counts : constant Work_Counts :=
           Reference_Counts (Pair.Calculation_Day, Pair.Target_Day);
         Observed_Counts : constant Work_Counts :=
           Compute_Work_Counts (Pair.Calculation_Day, Pair.Target_Day);
         Expected_Hidden : constant Hidden_Drops :=
           Reference_Hidden (Expected_Counts, Expected_Stones);
         Observed_Hidden : constant Hidden_Drops :=
           Build_Hidden_Drops (Observed_Counts, Observed_Stones);
      begin
         Compare (Observed_Counts.Action, Expected_Counts.Action,
                  "చర్య", I, 1);
         Compare (Observed_Counts.Target, Expected_Counts.Target,
                  "లక్ష్యం", I, 2);
         Compare (Observed_Counts.Distance, Expected_Counts.Distance,
                  "దూరం", I, 3);
         Compare (Observed_Counts.Connection, Expected_Counts.Connection,
                  "బంధం", I, 4);
         Compare (B (Observed_Counts.Direction), B (Expected_Counts.Direction),
                  "దిశ", I, 5);
         for K in 1 .. 7 loop
            Compare (Observed_Hidden (K), Expected_Hidden (K),
                     "దాచిన చుక్క", I, K);
         end loop;
      end;
   end loop;

   Ada.Wide_Wide_Text_IO.Put_Line
     ("STAGE10_DISCOVERY07_ASSERTIONS=" & Natural'Wide_Wide_Image (Assertions));
end Stage10_Discovery07_Tests;
