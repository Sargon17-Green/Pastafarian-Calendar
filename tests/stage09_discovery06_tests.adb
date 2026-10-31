with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Wide_Wide_Text_IO;
with Exact_Math;
with Normative_Oracle;

procedure Stage09_Discovery06_Tests is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Exact_Math;
   use Normative_Oracle;

   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));

   -- No Save, Square, or production mixing/stir helper in the reference.
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

   procedure Check (Condition : Boolean; Message : Wide_Wide_String) is
   begin
      Assertions := Assertions + 1;
      if not Condition then
         Ada.Wide_Wide_Text_IO.Put_Line ("విఫలం: " & Message);
         raise Program_Error;
      end if;
   end Check;

   -- Independent factorial unranking, never call Bowl_Order_From_Drop.
   function Reference_Order (Drop : Big_Integer) return Bowl_Order is
      Available : array (Positive range 1 .. 6) of Positive range 1 .. 6 :=
        (1, 2, 3, 4, 5, 6);
      Count : Natural := 6;
      Rank_Zero : Natural := Natural'Value
        (To_String ((Drop - B (1)) mod B (720)));
      Result : Bowl_Order;
   begin
      for Position in 1 .. 6 loop
         declare
            Block : Natural := 1;
            Pick  : Positive;
         begin
            for K in 2 .. 6 - Position loop
               Block := Block * K;
            end loop;
            Pick := Rank_Zero / Block + 1;
            Result (Position) := Available (Pick);
            Rank_Zero := Rank_Zero mod Block;
            for J in Pick .. Count - 1 loop
               Available (J) := Available (J + 1);
            end loop;
            Count := Count - 1;
         end;
      end loop;
      return Result;
   end Reference_Order;

   function Stone_At
     (S : Stone_Record; Position : Positive) return Big_Integer
   is
   begin
      case Position is
         when 1 | 6 => return S.Wheat;
         when 2     => return S.Barley;
         when 3     => return S.Salt;
         when 4     => return S.Bitter;
         when 5     => return S.Red;
         when others => raise Constraint_Error;
      end case;
   end Stone_At;

   -- Upstream counts/stones/hidden/visible drops are reused. This tests
   -- Sauce bowl mixing and final stirs, not the upstream drop algebra.
   function Reference_Sauce
     (Calculation_Day, Target_Day : Big_Integer) return Sauce_Result
   is
      Counts : constant Work_Counts :=
        Compute_Work_Counts (Calculation_Day, Target_Day);
      Stones : constant Stone_Table := Build_Stones;
      Hidden : constant Hidden_Drops := Build_Hidden_Drops (Counts, Stones);
      Visible : constant Visible_Drops :=
        Build_Visible_Drops (Counts, Stones, Hidden);
      Primes : constant array (Positive range 1 .. 6) of Integer :=
        (17, 19, 23, 29, 31, 37);
      Bowls : Bowl_Array;
      Order_46 : Bowl_Order := (1, 2, 3, 4, 5, 6);
   begin
      for Id in 1 .. 6 loop
         declare
            Seed : constant Big_Integer :=
              Counts.Action + Counts.Target * B (Id)
              + Counts.Distance + Counts.Connection
              + B (Counts.Direction) + B (Primes (Id) * Primes (Id));
         begin
            Bowls (Id) := Project (Seed * Seed + B (Id));
         end;
      end loop;

      for Round in 1 .. 46 loop
         declare
            Drop : constant Big_Integer := Visible (Round);
            Order : constant Bowl_Order := Reference_Order (Drop);
            Old : constant Bowl_Array := Bowls;
            Pours : Bowl_Array := (others => B (0));
            Next_Bowls : Bowl_Array := Old;
         begin
            Pours (1) := Project
              (Drop * Drop + Stones (Round).Wheat * Old (Order (1))
               + B (3 * Round));
            Pours (2) := Project
              (Drop * Drop + Stones (Round).Barley * Old (Order (2))
               + B (5 * Round));
            Pours (3) := Project
              (Drop * Drop + Stones (Round).Salt * Old (Order (3))
               + B (7 * Round));

            for Position in 1 .. 6 loop
               declare
                  Id : constant Positive := Order (Position);
                  Previous_Id : constant Positive :=
                    Order (((Position + 4) mod 6) + 1);
                  Following_Id : constant Positive :=
                    Order ((Position mod 6) + 1);
                  Mix : constant Big_Integer :=
                    Old (Id) + B (2) * Old (Previous_Id)
                    + B (3) * Old (Following_Id) + Pours (Position)
                    + Drop + Stone_At (Stones (Round), Position);
               begin
                  Next_Bowls (Id) := Project
                    (Mix * Mix + B (5) * Old (Previous_Id)
                     * Old (Following_Id) + B (Round * Position));
               end;
            end loop;
            Bowls := Next_Bowls;
            if Round = 46 then
               Order_46 := Order;
            end if;
         end;
      end loop;

      for Stir in 1 .. 12 loop
         declare
            Old : constant Bowl_Array := Bowls;
            Saved_Sum : Big_Integer := B (149 * Stir);
            Order : Bowl_Order;
            Next_Bowls : Bowl_Array := Old;
         begin
            for Id in 1 .. 6 loop
               Saved_Sum := Saved_Sum + Old (Id);
            end loop;
            Saved_Sum := Project (Saved_Sum);
            Order := Reference_Order (Saved_Sum);

            for Position in 1 .. 6 loop
               declare
                  Id : constant Positive := Order (Position);
                  Previous_Id : constant Positive :=
                    Order (((Position + 4) mod 6) + 1);
                  Following_Id : constant Positive :=
                    Order ((Position mod 6) + 1);
                  Mix : constant Big_Integer :=
                    Old (Id) + B (3) * Old (Previous_Id)
                    + B (5) * Old (Following_Id)
                    + Saved_Sum + B (Stir) + B (Position * Position);
               begin
                  Next_Bowls (Id) := Project
                    (Mix * Mix + B (7) * Old (Previous_Id)
                     * Old (Following_Id));
               end;
            end loop;
            Bowls := Next_Bowls;
         end;
      end loop;

      return (Bowls => Bowls, Order_At_Drop_46 => Order_46);
   end Reference_Sauce;

begin
   Check (Reference_Order (B (1)) =
          Bowl_Order'(1, 2, 3, 4, 5, 6), "క్రమం మొదలు");
   Check (Reference_Order (B (720)) =
          Bowl_Order'(6, 5, 4, 3, 2, 1), "క్రమం చివర");

   for Pair of Cases loop
      declare
         Expected : constant Sauce_Result :=
           Reference_Sauce (Pair.Calculation_Day, Pair.Target_Day);
         Actual : constant Sauce_Result :=
           Sauce (Pair.Calculation_Day, Pair.Target_Day);
         Seen : array (Positive range 1 .. 6) of Boolean :=
           (others => False);
         Unique_Order : Boolean := True;
      begin
         for Id in 1 .. 6 loop
            Check (Actual.Bowls (Id) = Expected.Bowls (Id),
                   "నిజమైన సాస్ కుండ విలువ");
            Check (Actual.Order_At_Drop_46 (Id) =
                   Expected.Order_At_Drop_46 (Id),
                   "46వ చుక్క కుండ క్రమం");
            if Seen (Actual.Order_At_Drop_46 (Id)) then
               Unique_Order := False;
            end if;
            Seen (Actual.Order_At_Drop_46 (Id)) := True;
         end loop;
         Check (Unique_Order, "కుండ క్రమంలో ఆరు ప్రత్యేక గుర్తులు");
      end;
   end loop;

   Ada.Wide_Wide_Text_IO.Put_Line
     ("STAGE09_DISCOVERY06_ASSERTIONS=" &
      Natural'Wide_Wide_Image (Assertions));
end Stage09_Discovery06_Tests;
