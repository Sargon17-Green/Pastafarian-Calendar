with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Ada.Wide_Wide_Text_IO;
with Exact_Math;
with Normative_Oracle;

procedure Stage11_Discovery08_Tests is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Exact_Math;
   use Normative_Oracle;

   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));
   function Reduce (N : Big_Integer) return Big_Integer is
     (B (1) + ((N - B (1)) mod M));

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

   type Coefficients is array (Positive range 1 .. 11) of Integer;
   -- Independent column vectors rather than the production Grind_Row table.
   Linear : constant Coefficients :=
     (3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37);
   Lag_1 : constant Coefficients :=
     (5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41);
   Lag_3 : constant Coefficients :=
     (7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43);
   Lag_7 : constant Coefficients :=
     (11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47);

   -- A five-way cycle, not production's enumerated Stone_Kind.
   function Stone_Cycle (S : Stone_Record; G : Positive)
     return Big_Integer
   is
   begin
      case (G - 1) mod 5 is
         when 0 => return S.Wheat;
         when 1 => return S.Barley;
         when 2 => return S.Salt;
         when 3 => return S.Bitter;
         when 4 => return S.Red;
         when others => raise Program_Error;
      end case;
   end Stone_Cycle;

   type Seven_History is array (Positive range 1 .. 7) of Big_Integer;

   -- The oldest-to-newest seven-cell queue is seeded with Hidden(7..1).
   -- Queue(7), Queue(5), Queue(1) denote prior 1, 3 and 7 drops.
   -- This avoids production's Prior_Value negative-index decision.
   function Reference_Visible
     (Counts : Work_Counts; Stones : Stone_Table; Hidden : Hidden_Drops)
      return Visible_Drops
   is
      Result : Visible_Drops;
      Queue : Seven_History :=
        (Hidden (7), Hidden (6), Hidden (5), Hidden (4),
         Hidden (3), Hidden (2), Hidden (1));
   begin
      for I in Result'Range loop
         declare
            S  : constant Stone_Record := Stones (I);
            P1 : constant Big_Integer := Queue (7);
            P3 : constant Big_Integer := Queue (5);
            P7 : constant Big_Integer := Queue (1);
            X  : Big_Integer := Reduce
              (S.Wheat * Counts.Action
               + S.Barley * Counts.Target
               + S.Salt * Counts.Distance
               + S.Bitter * Counts.Connection
               + S.Red * B (Counts.Direction)
               + P1 + B (3) * P3 + B (5) * P7 + B (I));
         begin
            for G in Linear'Range loop
               X := Reduce
                 (X * X
                  + B (Linear (G)) * X
                  + B (Lag_1 (G)) * P1
                  + B (Lag_3 (G)) * P3
                  + B (Lag_7 (G)) * P7
                  + Stone_Cycle (S, G));
            end loop;
            Result (I) := X;
            for J in Queue'First .. Queue'Last - 1 loop
               Queue (J) := Queue (J + 1);
            end loop;
            Queue (Queue'Last) := X;
         end;
      end loop;
      return Result;
   end Reference_Visible;

   Assertions : Natural := 0;
   procedure Compare
     (Actual, Expected : Big_Integer; Case_Index, Drop_Index : Positive)
   is
   begin
      Assertions := Assertions + 1;
      if Actual /= Expected
        or else Actual < B (1) or else Actual > M
        or else Expected < B (1) or else Expected > M
      then
         Ada.Wide_Wide_Text_IO.Put_Line ("కనిపించే చుక్కలో వ్యత్యాసం");
         Ada.Text_IO.Put_Line
           ("CASE=" & Positive'Image (Case_Index)
            & " DROP=" & Positive'Image (Drop_Index)
            & " EXPECTED=" & To_String (Expected)
            & " OBSERVED=" & To_String (Actual));
         raise Program_Error;
      end if;
   end Compare;

   Stones : constant Stone_Table := Build_Stones;
begin
   -- Upstream counts, stones and hidden drops have their own Stage10
   -- independent native oracle. They are inputs, never expected visibles.
   for C in Cases'Range loop
      declare
         Counts : constant Work_Counts := Compute_Work_Counts
           (Cases (C).Calculation_Day, Cases (C).Target_Day);
         Hidden : constant Hidden_Drops := Build_Hidden_Drops (Counts, Stones);
         Expected : constant Visible_Drops :=
           Reference_Visible (Counts, Stones, Hidden);
         Actual : constant Visible_Drops :=
           Build_Visible_Drops (Counts, Stones, Hidden);
      begin
         for I in Actual'Range loop
            Compare (Actual (I), Expected (I), C, I);
         end loop;
      end;
   end loop;
   if Assertions /= 368 then
      raise Program_Error with "Stage11 expected 368 comparisons";
   end if;
   Ada.Text_IO.Put_Line
     ("STAGE11_DISCOVERY08_ASSERTIONS=" & Natural'Image (Assertions));
end Stage11_Discovery08_Tests;
