with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Normative_Oracle;
with Exact_Math;

procedure Stage12_Discovery09_Tests is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Normative_Oracle;
   use Exact_Math;

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

   Seals : constant array (Positive range 1 .. 4) of Natural :=
     (0, 1, 193, 1_000_003);
   Samples : constant array (Positive range 1 .. 5) of Big_Integer :=
     (B (0), B (1), M, M + B (1), B (2) * M + B (9));

   -- Independent direct formula and successor lookup in the six-slot ring.
   -- Does not call Ask_Bowl, Answer_At, Save, Square or Wrap_1.
   function Reference_Stream
     (R : Sauce_Result; Id : Positive; Seal : Natural)
      return Answer_Stream
   is
      Next_Id : Positive := 1;
      Found   : Boolean := False;
      Salt    : constant Big_Integer := B (Integer (Seal));
      First   : Big_Integer;
      Parity  : Big_Integer;
      Step    : Integer := -1;
   begin
      for Position in R.Order_At_Drop_46'Range loop
         if R.Order_At_Drop_46 (Position) = Id then
            if Position = 6 then
               Next_Id := R.Order_At_Drop_46 (1);
            else
               Next_Id := R.Order_At_Drop_46 (Position + 1);
            end if;
            Found := True;
            exit;
         end if;
      end loop;
      if not Found then
         raise Program_Error with "Missing bowl in real Sauce ordering";
      end if;
      declare
         Seed : constant Big_Integer :=
           R.Bowls (Id) + Salt + B (181);
      begin
         First := Project
           (Seed * Seed + B (179) * R.Bowls (Next_Id) + Salt);
      end;
      declare
         Seed : constant Big_Integer := First + Salt + B (194);
      begin
         Parity := Project
           (Seed * Seed + B (193) * First + B (197) * R.Bowls (6));
      end;
      if Parity mod B (2) = B (1) then
         Step := 1;
      end if;
      return (First => First, Direction_Step => Step);
   end Reference_Stream;

   function Reference_At (Stream : Answer_Stream; K : Big_Integer)
     return Big_Integer
   is
   begin
      return Project
        (Stream.First + B (Stream.Direction_Step) * K);
   end Reference_At;

   Assertions : Natural := 0;
   procedure Check_Number
     (Observed, Expected : Big_Integer;
      Case_No, Id, Seal_No, Index_No : Positive)
   is
   begin
      Assertions := Assertions + 1;
      if Observed /= Expected or else
        Observed < B (1) or else Observed > M or else
        Expected < B (1) or else Expected > M
      then
         Ada.Text_IO.Put_Line
           ("CASE=" & Positive'Image (Case_No) &
            " BOWL=" & Positive'Image (Id) &
            " SEAL_INDEX=" & Positive'Image (Seal_No) &
            " SAMPLE=" & Positive'Image (Index_No) &
            " EXPECTED=" & To_String (Expected) &
            " OBSERVED=" & To_String (Observed));
         raise Program_Error;
      end if;
   end Check_Number;

   procedure Check_Step
     (Observed, Expected : Integer;
      Case_No, Id, Seal_No : Positive)
   is
   begin
      Assertions := Assertions + 1;
      if Observed /= Expected or else abs (Observed) /= 1 then
         Ada.Text_IO.Put_Line
           ("CASE=" & Positive'Image (Case_No) &
            " BOWL=" & Positive'Image (Id) &
            " SEAL_INDEX=" & Positive'Image (Seal_No) &
            " STEP_EXPECTED=" & Integer'Image (Expected) &
            " STEP_OBSERVED=" & Integer'Image (Observed));
         raise Program_Error;
      end if;
   end Check_Step;

begin
   for C in Cases'Range loop
      declare
         Real_Sauce : constant Sauce_Result :=
           Sauce (Cases (C).Calculation_Day, Cases (C).Target_Day);
      begin
         for Id in Positive range 1 .. 6 loop
            for S in Seals'Range loop
               declare
                  Expected : constant Answer_Stream :=
                    Reference_Stream (Real_Sauce, Id, Seals (S));
                  Observed : constant Answer_Stream :=
                    Ask_Bowl (Real_Sauce, Id, Seals (S));
               begin
                  Check_Number
                    (Observed.First, Expected.First, C, Id, S, 1);
                  Check_Step
                    (Observed.Direction_Step, Expected.Direction_Step,
                     C, Id, S);
                  for K in Samples'Range loop
                     Check_Number
                       (Answer_At (Observed, Samples (K)),
                        Reference_At (Expected, Samples (K)),
                        C, Id, S, K + 1);
                  end loop;
               end;
            end loop;
         end loop;
      end;
   end loop;
   if Assertions /= 1_344 then
      raise Program_Error with "Stage12 expected exactly 1344 assertions";
   end if;
   Ada.Text_IO.Put_Line
     ("STAGE12_DISCOVERY09_ASSERTIONS=" & Natural'Image (Assertions));
end Stage12_Discovery09_Tests;
