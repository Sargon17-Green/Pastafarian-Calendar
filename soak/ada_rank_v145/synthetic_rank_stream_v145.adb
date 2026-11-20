package body Synthetic_Rank_Stream_V145 is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   Zero : constant Big_Integer := To_Big_Integer (0);
   One  : constant Big_Integer := To_Big_Integer (1);

   function B (N : Natural) return Big_Integer is
     (To_Big_Integer (Integer (N)));

   function Save (X : Big_Integer) return Big_Integer is
     (One + ((X - One) mod M));

   procedure Check_Stream (Stream : Answer_Stream) is
   begin
      if Stream.First < One or else Stream.First > M
        or else abs Stream.Direction_Step /= 1
      then
         raise Constraint_Error with "invalid synthetic +/-1 answer stream";
      end if;
   end Check_Stream;

   function Ask_Bowl
     (Bowls : Bowl_Array; Order : Bowl_Order;
      Queried_Bowl_Id : Positive; Seal : Natural)
      return Answer_Stream
   is
      type Presence is array (Positive range 1 .. 6) of Boolean;
      Seen : Presence := (others => False);
      Position : Natural := 0;
      Next_Id  : Positive;
      First, Direction_Number : Big_Integer;
      Step : Integer range -1 .. 1 := -1;
   begin
      if Queried_Bowl_Id > 6 then
         raise Constraint_Error with "synthetic queried bowl outside 1..6";
      end if;
      for J in Order'Range loop
         if Seen (Order (J)) then
            raise Constraint_Error with "duplicate bowl order label";
         end if;
         Seen (Order (J)) := True;
         if Order (J) = Queried_Bowl_Id then
            Position := J;
         end if;
      end loop;
      if Position = 0 then
         raise Constraint_Error with "missing synthetic queried bowl";
      end if;
      if Position = 6 then
         Next_Id := Order (1);
      else
         Next_Id := Order (Position + 1);
      end if;
      First := Save
        ((Bowls (Queried_Bowl_Id) + B (Seal) + B (181)) ** 2
           + B (179) * Bowls (Next_Id) + B (Seal));
      Direction_Number := Save
        ((First + B (Seal) + B (194)) ** 2
           + B (193) * First + B (197) * Bowls (6));
      if (Direction_Number mod B (2)) = One then
         Step := 1;
      end if;
      return (First => First, Direction_Step => Step);
   end Ask_Bowl;

   function Answer_At
     (Stream : Answer_Stream; K : Big_Integer) return Big_Integer
   is
   begin
      Check_Stream (Stream);
      if K < Zero then
         raise Constraint_Error with "synthetic answer position negative";
      end if;
      return One +
        ((Stream.First - One
          + To_Big_Integer (Stream.Direction_Step) * K) mod M);
   end Answer_At;

   function Choose_Rank
     (Stream : Answer_Stream; N : Big_Integer) return Big_Integer
   is
      Places : Natural := 1;
      Space : Big_Integer := M;
      Wide : Big_Integer := One;
      Weight : Big_Integer := One;
      Limit : Big_Integer;
   begin
      Check_Stream (Stream);
      if N < One or else N >= (B (2) ** 1024) then
         raise Constraint_Error with "synthetic family size outside QA bound";
      end if;
      if N <= M then
         Limit := (M / N) * N;
         Wide := Answer_At (Stream, Zero);
         if Wide > Limit then
            if Stream.Direction_Step = 1 then
               Wide := One;
            else
               Wide := Limit;
            end if;
         end if;
         return ((Wide - One) mod N) + One;
      end if;

      while Space < N loop
         Places := Places + 1;
         Space := Space * M;
      end loop;

      for J in 0 .. Places - 1 loop
         Wide := Wide + (Answer_At (Stream, B (J)) - One) * Weight;
         Weight := Weight * M;
      end loop;

      Limit := (Space / N) * N;
      if Wide > Limit then
         --  On +/-1 cyclic streams, the first accepted endpoint is exact:
         --  descending enters at Limit, ascending wraps to One.
         if Stream.Direction_Step = 1 then
            Wide := One;
         else
            Wide := Limit;
         end if;
      end if;
      return ((Wide - One) mod N) + One;
   end Choose_Rank;

end Synthetic_Rank_Stream_V145;
