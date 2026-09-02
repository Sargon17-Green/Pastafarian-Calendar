with Ada.Containers;
with Ada.Containers.Ordered_Maps;
with Ada.Containers.Vectors;
with Ada.Numerics.Big_Numbers.Big_Integers;
with Exact_Math;

package body Normative_Oracle is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Exact_Math;
   use type Ada.Containers.Count_Type;

   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));

   Gate_Gap_Min   : constant Big_Integer := B (42);
   Gate_Gap_Max   : constant Big_Integer := B (963);
   Year_Min_Days  : constant Big_Integer := B (252);
   Year_Max_Days  : constant Big_Integer := B (5_778);

   Seal_Gate_Gap         : constant Natural := 1;
   Seal_Year_5000        : constant Natural := 10;
   Seal_Next_Year        : constant Natural := 11;
   Seal_Previous_Year    : constant Natural := 12;
   Seal_Cutlet_Count     : constant Natural := 20;
   Seal_Cutlet_Partition : constant Natural := 21;
   Seal_Cutlet_Names     : constant Natural := 22;
   Seal_Month_Count      : constant Natural := 30;
   Seal_Month_Lengths    : constant Natural := 31;
   Seal_Month_Weaving    : constant Natural := 32;
   Seal_Month_Names      : constant Natural := 33;

   type Natural_Array is array (Positive range <>) of Natural;

   function Day_Count (Day : Big_Integer) return Big_Integer is
   begin
      if Day = Foundation_Day then
         return B (1);
      elsif Day > Foundation_Day then
         return B (2) * (Day - Foundation_Day) + B (1);
      else
         return B (2) * (Foundation_Day - Day);
      end if;
   end Day_Count;

   function Compute_Work_Counts
     (Calculation_Day, Target_Day : Big_Integer) return Work_Counts
   is
      C : constant Big_Integer := Day_Count (Calculation_Day);
      T : constant Big_Integer := Day_Count (Target_Day);
      D : Positive range 1 .. 3 := 2;
   begin
      if Target_Day < Calculation_Day then
         D := 1;
      elsif Target_Day > Calculation_Day then
         D := 3;
      end if;

      return
        (Action     => C,
         Target     => T,
         Distance   => abs (Target_Day - Calculation_Day) + B (1),
         Connection => C + T,
         Direction  => D);
   end Compute_Work_Counts;

   function Build_Stones return Stone_Table is
      T : Stone_Table;
   begin
      T (1) :=
        (Wheat  => B (17), Barley => B (29), Salt => B (43),
         Bitter => B (71), Red => B (101));

      for I in 2 .. 46 loop
         declare
            Old : constant Stone_Record := T (I - 1);
         begin
            T (I) :=
              (Wheat  => Save (Square (Old.Wheat) + B (3) * Old.Barley + B (I)),
               Barley => Save (Square (Old.Barley) + B (5) * Old.Salt + Old.Wheat),
               Salt   => Save (Square (Old.Salt) + B (7) * Old.Bitter + Old.Barley),
               Bitter => Save (Square (Old.Bitter) + B (11) * Old.Red + Old.Salt),
               Red    => Save (Square (Old.Red) + B (13) * Old.Wheat + Old.Bitter));
         end;
      end loop;
      return T;
   end Build_Stones;

   Frozen_Stones : constant Stone_Table := Build_Stones;

   type Coeff_Row is array (Positive range 1 .. 4) of Integer;
   type Hidden_Coeff_Array is array (Positive range 1 .. 7) of Coeff_Row;
   Hidden_Coeff : constant Hidden_Coeff_Array :=
     ((3, 4, 6, 8),
      (5, 7, 10, 12),
      (7, 10, 14, 16),
      (9, 13, 18, 20),
      (11, 16, 22, 24),
      (13, 19, 26, 28),
      (15, 22, 30, 32));

   type Stone_Kind is (Wheat, Barley, Salt, Bitter, Red);
   type Hidden_Kind_Array is array (Positive range 1 .. 7) of Stone_Kind;
   Hidden_Grind_Stone : constant Hidden_Kind_Array :=
     (Wheat, Barley, Salt, Bitter, Red, Wheat, Barley);

   function Stone_Value (S : Stone_Record; K : Stone_Kind) return Big_Integer is
   begin
      case K is
         when Wheat  => return S.Wheat;
         when Barley => return S.Barley;
         when Salt   => return S.Salt;
         when Bitter => return S.Bitter;
         when Red    => return S.Red;
      end case;
   end Stone_Value;

   function Build_Hidden_Drops
     (Counts : Work_Counts; Stones : Stone_Table) return Hidden_Drops
   is
      H : Hidden_Drops;
   begin
      for K in 1 .. 7 loop
         declare
            A : constant Big_Integer := B (Hidden_Coeff (K) (1));
            C2 : constant Big_Integer := B (Hidden_Coeff (K) (2));
            C3 : constant Big_Integer := B (Hidden_Coeff (K) (3));
            C4 : constant Big_Integer := B (Hidden_Coeff (K) (4));
            X : Big_Integer :=
              Counts.Action
              + A * Counts.Target
              + C2 * Counts.Distance
              + C3 * Counts.Connection
              + C4 * B (Counts.Direction)
              + Stones (K).Wheat + Stones (K).Barley + Stones (K).Salt
              + Stones (K).Bitter + Stones (K).Red;
         begin
            X := Save (X);
            for G in 1 .. 7 loop
               declare
                  Old_X : constant Big_Integer := X;
               begin
                  X := Save
                    (Square (Old_X) + B (3) * Old_X
                     + Stone_Value (Stones (K), Hidden_Grind_Stone (G)) + B (G));
               end;
            end loop;
            H (K) := X;
         end;
      end loop;
      return H;
   end Build_Hidden_Drops;

   type Grind_Row is record
      A, Bc, C, D : Integer;
      Kind : Stone_Kind;
   end record;
   type Grind_Table is array (Positive range 1 .. 11) of Grind_Row;
   Visible_Grinds : constant Grind_Table :=
     ((3, 5, 7, 11, Wheat),
      (5, 7, 11, 13, Barley),
      (7, 11, 13, 17, Salt),
      (11, 13, 17, 19, Bitter),
      (13, 17, 19, 23, Red),
      (17, 19, 23, 29, Wheat),
      (19, 23, 29, 31, Barley),
      (23, 29, 31, 37, Salt),
      (29, 31, 37, 41, Bitter),
      (31, 37, 41, 43, Red),
      (37, 41, 43, 47, Wheat));

   function Prior_Value
     (Visible : Visible_Drops;
      Hidden  : Hidden_Drops;
      I, Back : Positive) return Big_Integer
   is
      Slot : constant Integer := Integer (I) - Integer (Back);
      K    : Positive;
   begin
      if Slot >= 1 then
         return Visible (Positive (Slot));
      end if;
      K := Positive (1 - Slot);
      return Hidden (K);
   end Prior_Value;

   function Build_Visible_Drops
     (Counts : Work_Counts; Stones : Stone_Table; Hidden : Hidden_Drops)
      return Visible_Drops
   is
      V : Visible_Drops := (others => B (1));
   begin
      for I in 1 .. 46 loop
         declare
            P1 : constant Big_Integer := Prior_Value (V, Hidden, I, 1);
            P3 : constant Big_Integer := Prior_Value (V, Hidden, I, 3);
            P7 : constant Big_Integer := Prior_Value (V, Hidden, I, 7);
            X  : Big_Integer := Save
              (Stones (I).Wheat * Counts.Action
               + Stones (I).Barley * Counts.Target
               + Stones (I).Salt * Counts.Distance
               + Stones (I).Bitter * Counts.Connection
               + Stones (I).Red * B (Counts.Direction)
               + P1 + B (3) * P3 + B (5) * P7 + B (I));
         begin
            for G in 1 .. 11 loop
               declare
                  Old_X : constant Big_Integer := X;
                  R     : constant Grind_Row := Visible_Grinds (G);
               begin
                  X := Save
                    (Square (Old_X)
                     + B (R.A) * Old_X
                     + B (R.Bc) * P1
                     + B (R.C) * P3
                     + B (R.D) * P7
                     + Stone_Value (Stones (I), R.Kind));
               end;
            end loop;
            V (I) := X;
         end;
      end loop;
      return V;
   end Build_Visible_Drops;

   function Bowl_Order_From_Number (Order_Number : Positive) return Bowl_Order is
      Remaining : Natural_Array (1 .. 6) := (1, 2, 3, 4, 5, 6);
      Remaining_Count : Natural := 6;
      Rank_0 : Natural := Order_Number - 1;
      Result : Bowl_Order;
   begin
      if Order_Number > 720 then
         raise Constraint_Error with "కుండల క్రమ సంఖ్య 1 నుండి 720 మధ్య ఉండాలి";
      end if;

      for Position in 1 .. 6 loop
         declare
            Slots_Left : constant Natural := 7 - Position;
            Block      : constant Natural :=
              To_Natural_Checked (Factorial (Slots_Left - 1), 720);
            Q          : constant Natural := Rank_0 / Block;
            Pick       : constant Natural := Q + 1;
         begin
            Rank_0 := Rank_0 mod Block;
            Result (Position) := Remaining (Pick);
            if Pick < Remaining_Count then
               for J in Pick .. Remaining_Count - 1 loop
                  Remaining (J) := Remaining (J + 1);
               end loop;
            end if;
            Remaining_Count := Remaining_Count - 1;
         end;
      end loop;
      return Result;
   end Bowl_Order_From_Number;

   function Bowl_Order_From_Drop (Drop_Value : Big_Integer) return Bowl_Order is
      N : constant Natural := To_Natural_Checked
        (Regular_Mod (Drop_Value - B (1), B (720)) + B (1), 720);
   begin
      return Bowl_Order_From_Number (Positive (N));
   end Bowl_Order_From_Drop;

   function Initial_Bowls (Counts : Work_Counts) return Bowl_Array is
      Prime : constant Natural_Array (1 .. 6) := (17, 19, 23, 29, 31, 37);
      R : Bowl_Array;
   begin
      for Id in 1 .. 6 loop
         declare
            S : constant Big_Integer :=
              Counts.Action + Counts.Target * B (Id) + Counts.Distance
              + Counts.Connection + B (Counts.Direction)
              + Square (B (Prime (Id)));
         begin
            R (Id) := Save (Square (S) + B (Id));
         end;
      end loop;
      return R;
   end Initial_Bowls;

   function Apply_Visible_Drops
     (Bowls : Bowl_Array; Visible : Visible_Drops; Stones : Stone_Table)
      return Sauce_Result
   is
      Bv : Bowl_Array := Bowls;
      Order_46 : Bowl_Order := (1, 2, 3, 4, 5, 6);
      Stone_By_Position : constant array (Positive range 1 .. 6) of Stone_Kind :=
        (Wheat, Barley, Salt, Bitter, Red, Wheat);
   begin
      for I in 1 .. 46 loop
         declare
            Drop : constant Big_Integer := Visible (I);
            Order : constant Bowl_Order := Bowl_Order_From_Drop (Drop);
            Old : constant Bowl_Array := Bv;
            Pour : Bowl_Array := (others => B (0));
            Next_Bowls : Bowl_Array := Old;
         begin
            Pour (1) := Save
              (Square (Drop) + Stones (I).Wheat * Old (Order (1)) + B (3 * I));
            Pour (2) := Save
              (Square (Drop) + Stones (I).Barley * Old (Order (2)) + B (5 * I));
            Pour (3) := Save
              (Square (Drop) + Stones (I).Salt * Old (Order (3)) + B (7 * I));

            for Position in 1 .. 6 loop
               declare
                  Id      : constant Positive := Order (Position);
                  Prev_Id : constant Positive := Order (Wrap_1 (Position + 5, 6));
                  Next_Id : constant Positive := Order (Wrap_1 (Position + 1, 6));
                  S       : constant Big_Integer :=
                    Old (Id) + B (2) * Old (Prev_Id) + B (3) * Old (Next_Id)
                    + Pour (Position) + Drop
                    + Stone_Value (Stones (I), Stone_By_Position (Position));
               begin
                  Next_Bowls (Id) := Save
                    (Square (S) + B (5) * Old (Prev_Id) * Old (Next_Id)
                     + B (I * Position));
               end;
            end loop;
            Bv := Next_Bowls;
            if I = 46 then
               Order_46 := Order;
            end if;
         end;
      end loop;
      return (Bowls => Bv, Order_At_Drop_46 => Order_46);
   end Apply_Visible_Drops;

   function Post_Stir_12 (Bowls : Bowl_Array) return Bowl_Array is
      Bv : Bowl_Array := Bowls;
   begin
      for Stir in 1 .. 12 loop
         declare
            Old : constant Bowl_Array := Bv;
            Saved_Bowl_Sum : constant Big_Integer := Save
              (Old (1) + Old (2) + Old (3) + Old (4) + Old (5) + Old (6)
               + B (149 * Stir));
            Order_Number : constant Natural := To_Natural_Checked
              (Regular_Mod (Saved_Bowl_Sum - B (1), B (720)) + B (1), 720);
            Order : constant Bowl_Order := Bowl_Order_From_Number (Positive (Order_Number));
            Next_Bowls : Bowl_Array := Old;
         begin
            for Position in 1 .. 6 loop
               declare
                  Id      : constant Positive := Order (Position);
                  Prev_Id : constant Positive := Order (Wrap_1 (Position + 5, 6));
                  Next_Id : constant Positive := Order (Wrap_1 (Position + 1, 6));
                  S : constant Big_Integer :=
                    Old (Id) + B (3) * Old (Prev_Id) + B (5) * Old (Next_Id)
                    + Saved_Bowl_Sum + B (Stir) + B (Position * Position);
               begin
                  Next_Bowls (Id) := Save
                    (Square (S) + B (7) * Old (Prev_Id) * Old (Next_Id));
               end;
            end loop;
            Bv := Next_Bowls;
         end;
      end loop;
      return Bv;
   end Post_Stir_12;

   function Sauce
     (Calculation_Day, Target_Day : Big_Integer) return Sauce_Result
   is
      Counts : constant Work_Counts := Compute_Work_Counts (Calculation_Day, Target_Day);
      Hidden : constant Hidden_Drops := Build_Hidden_Drops (Counts, Frozen_Stones);
      Visible : constant Visible_Drops := Build_Visible_Drops (Counts, Frozen_Stones, Hidden);
      After_Drops : constant Sauce_Result :=
        Apply_Visible_Drops (Initial_Bowls (Counts), Visible, Frozen_Stones);
   begin
      return
        (Bowls => Post_Stir_12 (After_Drops.Bowls),
         Order_At_Drop_46 => After_Drops.Order_At_Drop_46);
   end Sauce;

   function Ask_Bowl
     (R : Sauce_Result; Queried_Bowl_Id : Positive; Seal : Natural)
      return Answer_Stream
   is
      Position : Positive := 1;
      Next_Id  : Positive;
      First, Direction_Number : Big_Integer;
      Step : Integer range -1 .. 1 := -1;
   begin
      if Queried_Bowl_Id > 6 then
         raise Constraint_Error with "కుండ గుర్తింపు 1 నుండి 6 మధ్య ఉండాలి";
      end if;
      while R.Order_At_Drop_46 (Position) /= Queried_Bowl_Id loop
         Position := Position + 1;
      end loop;
      Next_Id := R.Order_At_Drop_46 (Wrap_1 (Position + 1, 6));

      First := Save
        (Square (R.Bowls (Queried_Bowl_Id) + B (Seal) + B (181))
         + B (179) * R.Bowls (Next_Id) + B (Seal));
      Direction_Number := Save
        (Square (First + B (Seal) + B (1) + B (193))
         + B (193) * First + B (197) * R.Bowls (6));
      if Regular_Mod (Direction_Number, B (2)) = B (1) then
         Step := 1;
      end if;
      return (First => First, Direction_Step => Step);
   end Ask_Bowl;

   function Answer_At (Stream : Answer_Stream; K : Big_Integer) return Big_Integer is
   begin
      if K < B (0) then
         raise Constraint_Error with "సమాధాన స్థానము ఋణం కాకూడదు";
      end if;
      return B (1) + Regular_Mod
        (Stream.First - B (1) + B (Stream.Direction_Step) * K, M);
   end Answer_At;

   function Choose_Rank_Short
     (Stream : Answer_Stream; N : Big_Integer) return Big_Integer
   is
      Acceptance_Limit : constant Big_Integer := Floor_Div (M, N) * N;
      K : Big_Integer := B (0);
      X : Big_Integer;
   begin
      loop
         X := Answer_At (Stream, K);
         if X <= Acceptance_Limit then
            return Regular_Mod (X - B (1), N) + B (1);
         end if;
         K := K + B (1);
      end loop;
   end Choose_Rank_Short;

   function Choose_Rank_Wide
     (Stream : Answer_Stream; N : Big_Integer) return Big_Integer
   is
      Places : Natural := 1;
      Space  : Big_Integer := M;
      Wide   : Big_Integer := B (1);
      Weight : Big_Integer := B (1);
   begin
      while Space < N loop
         Places := Places + 1;
         Space := Space * M;
      end loop;

      for J in 0 .. Places - 1 loop
         Wide := Wide + (Answer_At (Stream, B (J)) - B (1)) * Weight;
         Weight := Weight * M;
      end loop;

      declare
         Acceptance_Limit : constant Big_Integer := Floor_Div (Space, N) * N;
      begin
         while Wide > Acceptance_Limit loop
            Wide := B (1) + Regular_Mod
              (Wide - B (1) + B (Stream.Direction_Step), Space);
         end loop;
      end;
      return Regular_Mod (Wide - B (1), N) + B (1);
   end Choose_Rank_Wide;

   function Choose_Rank
     (Stream : Answer_Stream; N : Big_Integer) return Big_Integer
   is
   begin
      if N < B (1) then
         raise Constraint_Error with "ఎంపిక కుటుంబం ఖాళీగా ఉండకూడదు";
      end if;
      if N <= M then
         return Choose_Rank_Short (Stream, N);
      else
         return Choose_Rank_Wide (Stream, N);
      end if;
   end Choose_Rank;

   package Big_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type => Big_Integer, Element_Type => Big_Integer);

   type Gate_State is record
      Values    : Big_Maps.Map;
      Min_Index : Big_Integer := B (0);
      Max_Index : Big_Integer := B (0);
   end record;

   procedure Initialize_Gates (G : in out Gate_State) is
   begin
      G.Values.Clear;
      G.Values.Insert (B (0), Foundation_Day);
      G.Min_Index := B (0);
      G.Max_Index := B (0);
   end Initialize_Gates;

   function Positive_Gate_Gap (N : Big_Integer) return Big_Integer is
      R : constant Sauce_Result := Sauce (Foundation_Day, Foundation_Day + N);
      Stream : constant Answer_Stream := Ask_Bowl (R, 1, Seal_Gate_Gap);
   begin
      return B (41) + Choose_Rank (Stream, B (922));
   end Positive_Gate_Gap;

   function Negative_Gate_Gap (N : Big_Integer) return Big_Integer is
      R : constant Sauce_Result := Sauce (Foundation_Day, Foundation_Day - N);
      Stream : constant Answer_Stream := Ask_Bowl (R, 1, Seal_Gate_Gap);
   begin
      return B (41) + Choose_Rank (Stream, B (922));
   end Negative_Gate_Gap;

   function Gate_At (G : Gate_State; K : Big_Integer) return Big_Integer is
   begin
      return G.Values.Element (K);
   end Gate_At;

   procedure Ensure_Gate_Index (G : in out Gate_State; K : Big_Integer) is
      N : Big_Integer;
   begin
      if K > G.Max_Index then
         N := G.Max_Index + B (1);
         while N <= K loop
            G.Values.Insert (N, Gate_At (G, N - B (1)) + Positive_Gate_Gap (N));
            G.Max_Index := N;
            N := N + B (1);
         end loop;
      end if;

      if K < G.Min_Index then
         N := G.Min_Index - B (1);
         while N >= K loop
            G.Values.Insert
              (N, Gate_At (G, N + B (1)) - Negative_Gate_Gap (abs N));
            G.Min_Index := N;
            N := N - B (1);
         end loop;
      end if;
   end Ensure_Gate_Index;

   procedure Ensure_Gates_Cover
     (G : in out Gate_State; Low_Day, High_Day : Big_Integer)
   is
   begin
      if Low_Day > High_Day then
         raise Constraint_Error with "దిన పరిధి క్రమం తప్పింది";
      end if;
      while Gate_At (G, G.Min_Index) > Low_Day loop
         Ensure_Gate_Index (G, G.Min_Index - B (1));
      end loop;
      while Gate_At (G, G.Max_Index) < High_Day loop
         Ensure_Gate_Index (G, G.Max_Index + B (1));
      end loop;
   end Ensure_Gates_Cover;

   function Gate_Index_At_Or_Before
     (G : in out Gate_State; Day : Big_Integer) return Big_Integer
   is
      Lo, Hi, Mid : Big_Integer;
   begin
      Ensure_Gates_Cover (G, Day, Day);
      Lo := G.Min_Index;
      Hi := G.Max_Index;
      while Lo < Hi loop
         Mid := Lo + Floor_Div (Hi - Lo + B (1), B (2));
         if Gate_At (G, Mid) <= Day then
            Lo := Mid;
         else
            Hi := Mid - B (1);
         end if;
      end loop;
      return Lo;
   end Gate_Index_At_Or_Before;

   function Exact_Gate_Index
     (G : in out Gate_State; Day : Big_Integer; Found : out Boolean)
      return Big_Integer
   is
      I : constant Big_Integer := Gate_Index_At_Or_Before (G, Day);
   begin
      Found := Gate_At (G, I) = Day;
      return I;
   end Exact_Gate_Index;

   type Year_Record is record
      Number      : Big_Integer;
      Open_Index  : Big_Integer;
      Close_Index : Big_Integer;
      Open_Day    : Big_Integer;
      Close_Day   : Big_Integer;
   end record;

   function Valid_Year_Pair
     (G : Gate_State; Open_Index, Close_Index : Big_Integer) return Boolean
   is
      L : constant Big_Integer := Gate_At (G, Close_Index) - Gate_At (G, Open_Index);
   begin
      return Close_Index - Open_Index >= B (6)
        and then L >= Year_Min_Days and then L <= Year_Max_Days;
   end Valid_Year_Pair;

   type Pair_Record is record
      Open_Index, Close_Index : Big_Integer;
   end record;
   package Pair_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Pair_Record);
   package Big_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Big_Integer);

   function Pair_Less (G : Gate_State; A, C : Pair_Record) return Boolean is
      LA : constant Big_Integer := Gate_At (G, A.Close_Index) - Gate_At (G, A.Open_Index);
      LC : constant Big_Integer := Gate_At (G, C.Close_Index) - Gate_At (G, C.Open_Index);
   begin
      if LA /= LC then
         return LA < LC;
      end if;
      return Gate_At (G, A.Open_Index) < Gate_At (G, C.Open_Index);
   end Pair_Less;

   procedure Sort_Pairs (G : Gate_State; V : in out Pair_Vectors.Vector) is
      I, J : Natural;
      Temp : Pair_Record;
   begin
      if V.Length <= 1 then
         return;
      end if;
      I := V.First_Index + 1;
      while I <= V.Last_Index loop
         J := I;
         while J > V.First_Index
           and then Pair_Less (G, V.Element (J), V.Element (J - 1))
         loop
            Temp := V.Element (J - 1);
            V.Replace_Element (J - 1, V.Element (J));
            V.Replace_Element (J, Temp);
            J := J - 1;
         end loop;
         I := I + 1;
      end loop;
   end Sort_Pairs;

   function Pair_By_Rank
     (V : Pair_Vectors.Vector; Rank : Big_Integer) return Pair_Record
   is
      R : Big_Integer := Rank;
      I : Natural := V.First_Index;
   begin
      while R > B (1) loop
         R := R - B (1);
         I := I + 1;
      end loop;
      return V.Element (I);
   end Pair_By_Rank;

   function Big_By_Rank
     (V : Big_Vectors.Vector; Rank : Big_Integer) return Big_Integer
   is
      R : Big_Integer := Rank;
      I : Natural := V.First_Index;
   begin
      while R > B (1) loop
         R := R - B (1);
         I := I + 1;
      end loop;
      return V.Element (I);
   end Big_By_Rank;

   function Year_5000 (G : in out Gate_State; Calculation_Day : Big_Integer)
      return Year_Record
   is
      Candidates : Pair_Vectors.Vector;
      I, J : Big_Integer;
   begin
      Ensure_Gates_Cover
        (G, Calculation_Day - Year_Max_Days, Calculation_Day + Year_Max_Days);
      I := G.Min_Index;
      while I < G.Max_Index loop
         J := I + B (1);
         while J <= G.Max_Index loop
            if Valid_Year_Pair (G, I, J)
              and then Gate_At (G, I) < Calculation_Day
              and then Calculation_Day <= Gate_At (G, J)
            then
               Candidates.Append ((Open_Index => I, Close_Index => J));
            end if;
            J := J + B (1);
         end loop;
         I := I + B (1);
      end loop;

      if Candidates.Is_Empty then
         raise Program_Error with "5000 సంవత్సరానికి అభ్యర్థి దొరకలేదు";
      end if;
      Sort_Pairs (G, Candidates);
      declare
         R : constant Sauce_Result := Sauce (Calculation_Day, Calculation_Day);
         Stream : constant Answer_Stream := Ask_Bowl (R, 1, Seal_Year_5000);
         Rank : constant Big_Integer := Choose_Rank
           (Stream, B (Integer (Candidates.Length)));
         P : constant Pair_Record := Pair_By_Rank (Candidates, Rank);
      begin
         return
           (Number => B (5_000), Open_Index => P.Open_Index,
            Close_Index => P.Close_Index, Open_Day => Gate_At (G, P.Open_Index),
            Close_Day => Gate_At (G, P.Close_Index));
      end;
   end Year_5000;

   procedure Sort_Close_Indices
     (G : Gate_State; Open_Index : Big_Integer; V : in out Big_Vectors.Vector)
   is
      I, J : Natural;
      Temp : Big_Integer;
   begin
      if V.Length <= 1 then
         return;
      end if;
      I := V.First_Index + 1;
      while I <= V.Last_Index loop
         J := I;
         while J > V.First_Index
           and then Gate_At (G, V.Element (J)) - Gate_At (G, Open_Index)
             < Gate_At (G, V.Element (J - 1)) - Gate_At (G, Open_Index)
         loop
            Temp := V.Element (J - 1);
            V.Replace_Element (J - 1, V.Element (J));
            V.Replace_Element (J, Temp);
            J := J - 1;
         end loop;
         I := I + 1;
      end loop;
   end Sort_Close_Indices;

   procedure Sort_Open_Indices
     (G : Gate_State; Close_Index : Big_Integer; V : in out Big_Vectors.Vector)
   is
      I, J : Natural;
      Temp : Big_Integer;
   begin
      if V.Length <= 1 then
         return;
      end if;
      I := V.First_Index + 1;
      while I <= V.Last_Index loop
         J := I;
         while J > V.First_Index
           and then Gate_At (G, Close_Index) - Gate_At (G, V.Element (J))
             < Gate_At (G, Close_Index) - Gate_At (G, V.Element (J - 1))
         loop
            Temp := V.Element (J - 1);
            V.Replace_Element (J - 1, V.Element (J));
            V.Replace_Element (J, Temp);
            J := J - 1;
         end loop;
         I := I + 1;
      end loop;
   end Sort_Open_Indices;

   function Next_Year
     (G : in out Gate_State; Calculation_Day : Big_Integer; Known : Year_Record)
      return Year_Record
   is
      Open_Index : constant Big_Integer := Known.Close_Index;
      Candidates : Big_Vectors.Vector;
      J : Big_Integer := Open_Index + B (1);
   begin
      loop
         Ensure_Gate_Index (G, J);
         exit when Gate_At (G, J) - Gate_At (G, Open_Index) > Year_Max_Days;
         if Valid_Year_Pair (G, Open_Index, J) then
            Candidates.Append (J);
         end if;
         J := J + B (1);
      end loop;
      if Candidates.Is_Empty then
         raise Program_Error with "తదుపరి సంవత్సరానికి అభ్యర్థి లేదు";
      end if;
      Sort_Close_Indices (G, Open_Index, Candidates);
      declare
         R : constant Sauce_Result := Sauce (Calculation_Day, Gate_At (G, Open_Index));
         Stream : constant Answer_Stream := Ask_Bowl (R, 1, Seal_Next_Year);
         Rank : constant Big_Integer := Choose_Rank
           (Stream, B (Integer (Candidates.Length)));
         Close_Index : constant Big_Integer := Big_By_Rank (Candidates, Rank);
      begin
         return
           (Number => Known.Number + B (1), Open_Index => Open_Index,
            Close_Index => Close_Index, Open_Day => Gate_At (G, Open_Index),
            Close_Day => Gate_At (G, Close_Index));
      end;
   end Next_Year;

   function Previous_Year
     (G : in out Gate_State; Calculation_Day : Big_Integer; Known : Year_Record)
      return Year_Record
   is
      Close_Index : constant Big_Integer := Known.Open_Index;
      Candidates : Big_Vectors.Vector;
      I : Big_Integer := Close_Index - B (1);
   begin
      loop
         Ensure_Gate_Index (G, I);
         exit when Gate_At (G, Close_Index) - Gate_At (G, I) > Year_Max_Days;
         if Valid_Year_Pair (G, I, Close_Index) then
            Candidates.Append (I);
         end if;
         I := I - B (1);
      end loop;
      if Candidates.Is_Empty then
         raise Program_Error with "మునుపటి సంవత్సరానికి అభ్యర్థి లేదు";
      end if;
      Sort_Open_Indices (G, Close_Index, Candidates);
      declare
         R : constant Sauce_Result := Sauce (Calculation_Day, Gate_At (G, Close_Index));
         Stream : constant Answer_Stream := Ask_Bowl (R, 1, Seal_Previous_Year);
         Rank : constant Big_Integer := Choose_Rank
           (Stream, B (Integer (Candidates.Length)));
         Open_Index : constant Big_Integer := Big_By_Rank (Candidates, Rank);
      begin
         return
           (Number => Known.Number - B (1), Open_Index => Open_Index,
            Close_Index => Close_Index, Open_Day => Gate_At (G, Open_Index),
            Close_Day => Gate_At (G, Close_Index));
      end;
   end Previous_Year;

   function Find_Target_Year
     (G : in out Gate_State; Calculation_Day, Target_Day : Big_Integer)
      return Year_Record
   is
      Y : Year_Record := Year_5000 (G, Calculation_Day);
   begin
      while Target_Day > Y.Close_Day loop
         Y := Next_Year (G, Calculation_Day, Y);
      end loop;
      while Target_Day <= Y.Open_Day loop
         Y := Previous_Year (G, Calculation_Day, Y);
      end loop;
      return Y;
   end Find_Target_Year;

   type Cutlet_Key is record
      Rem, Slots, Cumulative : Natural;
      Hit : Boolean;
   end record;

   function "<" (A, C : Cutlet_Key) return Boolean is
   begin
      if A.Rem /= C.Rem then return A.Rem < C.Rem; end if;
      if A.Slots /= C.Slots then return A.Slots < C.Slots; end if;
      if A.Cumulative /= C.Cumulative then return A.Cumulative < C.Cumulative; end if;
      return (not A.Hit) and C.Hit;
   end "<";

   package Cutlet_Memo_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type => Cutlet_Key, Element_Type => Big_Integer);

   function Choose_Cutlet_Partition
     (Gates : in out Gate_State;
      Calculation_Day : Big_Integer;
      Y : Year_Record;
      Structure_R : Sauce_Result;
      K : Positive) return Natural_Array
   is
      Gaps : constant Natural := To_Natural_Checked (Y.Close_Index - Y.Open_Index, 1_000);
      Found : Boolean;
      Gate_Index : constant Big_Integer := Exact_Gate_Index (Gates, Calculation_Day, Found);
      Required : Natural := 0;
      Memo : Cutlet_Memo_Maps.Map;

      function Count
        (Rem, Slots, Cumulative : Natural; Hit : Boolean) return Big_Integer
      is
         Key : constant Cutlet_Key := (Rem, Slots, Cumulative, Hit);
         Total : Big_Integer := B (0);
      begin
         if Slots = 0 then
            if Rem /= 0 then return B (0); end if;
            if Required = 0 or else Hit then return B (1); end if;
            return B (0);
         end if;
         if Rem < Slots then return B (0); end if;
         if Memo.Contains (Key) then return Memo.Element (Key); end if;

         for X in 1 .. Rem - (Slots - 1) loop
            declare
               Next_Cumulative : constant Natural := Cumulative + X;
               Next_Hit : Boolean := Hit;
            begin
               if Required /= 0 and then not Hit then
                  if Next_Cumulative = Required then
                     Next_Hit := True;
                  elsif Next_Cumulative > Required then
                     goto Skip_X;
                  end if;
               end if;
               Total := Total + Count (Rem - X, Slots - 1, Next_Cumulative, Next_Hit);
               <<Skip_X>>
               null;
            end;
         end loop;
         Memo.Insert (Key, Total);
         return Total;
      end Count;

      Count_All : Big_Integer;
      Stream : Answer_Stream;
      Rank : Big_Integer;
      Result : Natural_Array (1 .. K);
      Rem : Natural := Gaps;
      Slots : Natural := K;
      Cumulative : Natural := 0;
      Hit : Boolean := False;
   begin
      if Found and then Gate_Index > Y.Open_Index and then Gate_Index < Y.Close_Index then
         Required := To_Natural_Checked (Gate_Index - Y.Open_Index, 1_000);
      end if;
      Count_All := Count (Gaps, K, 0, False);
      Stream := Ask_Bowl (Structure_R, 2, Seal_Cutlet_Partition);
      Rank := Choose_Rank (Stream, Count_All);

      for Position in 1 .. K loop
         for X in 1 .. Rem - (Slots - 1) loop
            declare
               Next_Cumulative : constant Natural := Cumulative + X;
               Next_Hit : Boolean := Hit;
               Block : Big_Integer := B (0);
            begin
               if Required /= 0 and then not Hit then
                  if Next_Cumulative = Required then
                     Next_Hit := True;
                  elsif Next_Cumulative > Required then
                     goto Skip_Unrank_X;
                  end if;
               end if;
               Block := Count (Rem - X, Slots - 1, Next_Cumulative, Next_Hit);
               if Rank > Block then
                  Rank := Rank - Block;
               else
                  Result (Position) := X;
                  Rem := Rem - X;
                  Slots := Slots - 1;
                  Cumulative := Next_Cumulative;
                  Hit := Next_Hit;
                  exit;
               end if;
               <<Skip_Unrank_X>>
               null;
            end;
         end loop;
      end loop;
      return Result;
   end Choose_Cutlet_Partition;

   function Unrank_Distinct
     (Master_Count, K : Positive; Rank_1 : Big_Integer) return Natural_Array
   is
      Remaining : Natural_Array (1 .. Master_Count);
      Remaining_Count : Natural := Master_Count;
      R : Big_Integer := Rank_1;
      Out_Row : Natural_Array (1 .. K);
   begin
      for I in 1 .. Master_Count loop
         Remaining (I) := I;
      end loop;
      for Position in 1 .. K loop
         declare
            Suffix : constant Natural := K - Position;
            Block : constant Big_Integer := Falling_Factorial (Remaining_Count - 1, Suffix);
         begin
            for Candidate in 1 .. Remaining_Count loop
               if R > Block then
                  R := R - Block;
               else
                  Out_Row (Position) := Remaining (Candidate);
                  if Candidate < Remaining_Count then
                     for J in Candidate .. Remaining_Count - 1 loop
                        Remaining (J) := Remaining (J + 1);
                     end loop;
                  end if;
                  Remaining_Count := Remaining_Count - 1;
                  exit;
               end if;
            end loop;
         end;
      end loop;
      return Out_Row;
   end Unrank_Distinct;

   type Bounded_Key is record
      Rem, Slots : Natural;
   end record;
   function "<" (A, C : Bounded_Key) return Boolean is
   begin
      return A.Rem < C.Rem or else (A.Rem = C.Rem and then A.Slots < C.Slots);
   end "<";
   package Bounded_Memo_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type => Bounded_Key, Element_Type => Big_Integer);

   procedure Choose_Month_Lengths
     (Structure_R : Sauce_Result;
      Total, Slots : Positive;
      Lengths : out Natural_Array)
   is
      Memo : Bounded_Memo_Maps.Map;
      function Count (Rem, K : Natural) return Big_Integer is
         Key : constant Bounded_Key := (Rem, K);
         Sum : Big_Integer := B (0);
      begin
         if K = 0 then
            return (if Rem = 0 then B (1) else B (0));
         end if;
         if Rem < K * 4 or else Rem > K * 123 then return B (0); end if;
         if Memo.Contains (Key) then return Memo.Element (Key); end if;
         for X in 4 .. 123 loop
            if X <= Rem then
               Sum := Sum + Count (Rem - X, K - 1);
            end if;
         end loop;
         Memo.Insert (Key, Sum);
         return Sum;
      end Count;

      Rank : Big_Integer := Choose_Rank
        (Ask_Bowl (Structure_R, 3, Seal_Month_Lengths), Count (Total, Slots));
      Rem : Natural := Total;
      K : Natural := Slots;
   begin
      for Position in Lengths'Range loop
         for X in 4 .. 123 loop
            if X <= Rem then
               declare
                  Block : constant Big_Integer := Count (Rem - X, K - 1);
               begin
                  if Rank > Block then
                     Rank := Rank - Block;
                  else
                     Lengths (Position) := X;
                     Rem := Rem - X;
                     K := K - 1;
                     exit;
                  end if;
               end;
            end if;
         end loop;
      end loop;
   end Choose_Month_Lengths;

   type Remaining_47 is array (Positive range 1 .. 47) of Natural;
   type Weave_Key is record
      Month_Count : Natural;
      Remaining   : Remaining_47;
      Opened_Up_To : Natural;
      Closed_Up_To : Natural;
   end record;

   function "<" (A, C : Weave_Key) return Boolean is
   begin
      if A.Month_Count /= C.Month_Count then
         return A.Month_Count < C.Month_Count;
      end if;
      if A.Opened_Up_To /= C.Opened_Up_To then
         return A.Opened_Up_To < C.Opened_Up_To;
      end if;
      if A.Closed_Up_To /= C.Closed_Up_To then
         return A.Closed_Up_To < C.Closed_Up_To;
      end if;
      for I in 1 .. 47 loop
         if A.Remaining (I) /= C.Remaining (I) then
            return A.Remaining (I) < C.Remaining (I);
         end if;
      end loop;
      return False;
   end "<";

   package Weave_Memo_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type => Weave_Key, Element_Type => Big_Integer);

   function Choose_Month_Weaving
     (Structure_R : Sauce_Result; Lengths : Natural_Array) return Natural_Array
   is
      M_Count : constant Natural := Lengths'Length;
      Total : Natural := 0;
      Original : Remaining_47 := (others => 0);
      Memo : Weave_Memo_Maps.Map;

      function Legal (State : Weave_Key; J : Positive) return Boolean is
         Already_Opened : Boolean;
         Will_Close : Boolean;
      begin
         if J > State.Month_Count or else State.Remaining (J) = 0 then return False; end if;
         Already_Opened := State.Remaining (J) < Original (J);
         if not Already_Opened and then J /= State.Opened_Up_To + 1 then return False; end if;
         Will_Close := State.Remaining (J) = 1;
         if Will_Close and then J /= State.Closed_Up_To + 1 then return False; end if;
         return True;
      end Legal;

      function Move (State : Weave_Key; J : Positive) return Weave_Key is
         N : Weave_Key := State;
      begin
         if N.Remaining (J) = Original (J) then N.Opened_Up_To := J; end if;
         N.Remaining (J) := N.Remaining (J) - 1;
         if N.Remaining (J) = 0 then N.Closed_Up_To := J; end if;
         return N;
      end Move;

      function All_Zero (State : Weave_Key) return Boolean is
      begin
         for J in 1 .. State.Month_Count loop
            if State.Remaining (J) /= 0 then return False; end if;
         end loop;
         return True;
      end All_Zero;

      function Count (State : Weave_Key) return Big_Integer is
         Sum : Big_Integer := B (0);
      begin
         if All_Zero (State) then return B (1); end if;
         if Memo.Contains (State) then return Memo.Element (State); end if;
         for J in 1 .. State.Month_Count loop
            if Legal (State, J) then
               Sum := Sum + Count (Move (State, J));
            end if;
         end loop;
         Memo.Insert (State, Sum);
         return Sum;
      end Count;

      State : Weave_Key :=
        (Month_Count => M_Count, Remaining => (others => 0),
         Opened_Up_To => 0, Closed_Up_To => 0);
   begin
      for J in Lengths'Range loop
         Original (J) := Lengths (J);
         State.Remaining (J) := Lengths (J);
         Total := Total + Lengths (J);
      end loop;

      declare
         Rank : Big_Integer := Choose_Rank
           (Ask_Bowl (Structure_R, 4, Seal_Month_Weaving), Count (State));
         Result : Natural_Array (1 .. Total);
      begin
         for Position in 1 .. Total loop
            for J in 1 .. M_Count loop
               if Legal (State, J) then
                  declare
                     Next_State : constant Weave_Key := Move (State, J);
                     Block : constant Big_Integer := Count (Next_State);
                  begin
                     if Rank > Block then
                        Rank := Rank - Block;
                     else
                        Result (Position) := J;
                        State := Next_State;
                        exit;
                     end if;
                  end;
               end if;
            end loop;
         end loop;
         return Result;
      end;
   end Choose_Month_Weaving;

   function Calendar_Date
     (Calculation_Day, Target_Day : Big_Integer) return Calendar_Result
   is
      Gates : Gate_State;
   begin
      Initialize_Gates (Gates);
      declare
         Y : constant Year_Record := Find_Target_Year (Gates, Calculation_Day, Target_Day);
         First_Day : constant Big_Integer := Y.Open_Day + B (1);
         Structure_R : constant Sauce_Result := Sauce (Calculation_Day, First_Day);
         Gap_Count : constant Natural := To_Natural_Checked (Y.Close_Index - Y.Open_Index, 1_000);
         Cutlet_Max : constant Natural := Natural'Min (17, Gap_Count);
         Cutlet_Choices : constant Natural := Cutlet_Max - 5;
         Cutlet_Rank : constant Natural := To_Natural_Checked
           (Choose_Rank
              (Ask_Bowl (Structure_R, 2, Seal_Cutlet_Count), B (Cutlet_Choices)),
            Cutlet_Choices);
         K : constant Positive := Positive (5 + Cutlet_Rank);
         Partition : constant Natural_Array :=
           Choose_Cutlet_Partition (Gates, Calculation_Day, Y, Structure_R, K);
         Cutlet_Name_Rank : constant Big_Integer := Choose_Rank
           (Ask_Bowl (Structure_R, 5, Seal_Cutlet_Names), Falling_Factorial (17, K));
         Cutlet_Names : constant Natural_Array := Unrank_Distinct (17, K, Cutlet_Name_Rank);
         Year_Length : constant Natural := To_Natural_Checked (Y.Close_Day - Y.Open_Day, 5_778);
         Low_Months : constant Natural := (Year_Length + 122) / 123;
         High_Months : constant Natural := Natural'Min (47, Year_Length / 4);
         Month_Choice_Count : constant Natural := High_Months - Low_Months + 1;
         Month_Rank : constant Natural := To_Natural_Checked
           (Choose_Rank
              (Ask_Bowl (Structure_R, 3, Seal_Month_Count), B (Month_Choice_Count)),
            Month_Choice_Count);
         Month_Count : constant Positive := Positive (Low_Months + Month_Rank - 1);
         Month_Lengths : Natural_Array (1 .. Month_Count);
         Cutlet_Id : Positive := 1;
         Day_In_Cutlet : Big_Integer := B (0);
      begin
         Choose_Month_Lengths (Structure_R, Year_Length, Month_Count, Month_Lengths);
         declare
            Weave : constant Natural_Array := Choose_Month_Weaving (Structure_R, Month_Lengths);
            Month_Name_Rank : constant Big_Integer := Choose_Rank
              (Ask_Bowl (Structure_R, 5, Seal_Month_Names),
               Falling_Factorial (47, Month_Count));
            Month_Names : constant Natural_Array :=
              Unrank_Distinct (47, Month_Count, Month_Name_Rank);
            Cursor : Big_Integer := Y.Open_Index;
            Offset_0 : constant Natural := To_Natural_Checked
              (Target_Day - First_Day, Year_Length - 1);
            Month_Id : constant Positive := Positive (Weave (Offset_0 + 1));
            Day_In_Month : Natural := 0;
         begin
            for C in 1 .. K loop
               declare
                  Open_Index : constant Big_Integer := Cursor;
                  Close_Index : constant Big_Integer := Cursor + B (Partition (C));
                  C_First : constant Big_Integer := Gate_At (Gates, Open_Index) + B (1);
                  C_Last : constant Big_Integer := Gate_At (Gates, Close_Index);
               begin
                  if C_First <= Target_Day and then Target_Day <= C_Last then
                     Cutlet_Id := C;
                     Day_In_Cutlet := Target_Day - C_First + B (1);
                  end if;
                  Cursor := Close_Index;
               end;
            end loop;

            if Day_In_Cutlet = B (0) then
               raise Program_Error with "లక్ష్య దినానికి కట్లెట్ దొరకలేదు";
            end if;

            for P in 1 .. Offset_0 + 1 loop
               if Weave (P) = Month_Id then
                  Day_In_Month := Day_In_Month + 1;
               end if;
            end loop;

            return
              (Year_Number => Y.Number,
               Cutlet_Canonical => Positive (Cutlet_Names (Cutlet_Id)),
               Day_In_Cutlet => Day_In_Cutlet,
               Month_Canonical => Positive (Month_Names (Month_Id)),
               Day_In_Month => B (Day_In_Month));
         end;
      end;
   end Calendar_Date;

end Normative_Oracle;
