with Ada.Numerics.Big_Numbers.Big_Integers;

--  QA-only pure synthetic transposition of the original answer-stream math.
--  No original Calendar_Date, Sauce or F(c,t) import / source execution.
package Synthetic_Rank_Stream_V145 is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   M : constant Big_Integer := (To_Big_Integer (2) ** 127) - To_Big_Integer (1);

   type Answer_Stream is record
      First : Big_Integer;
      Direction_Step : Integer range -1 .. 1;
   end record;

   type Bowl_Array is array (Positive range 1 .. 6) of Big_Integer;
   type Bowl_Order is array (Positive range 1 .. 6) of Positive range 1 .. 6;

   --  Synthetic bowls only. The full original Sauce is not computed.
   function Ask_Bowl
     (Bowls : Bowl_Array; Order : Bowl_Order;
      Queried_Bowl_Id : Positive; Seal : Natural)
      return Answer_Stream;

   function Answer_At
     (Stream : Answer_Stream; K : Big_Integer) return Big_Integer;

   --  One-based rank in 1..N. QA cap: N must be < 2**1024.
   --  For +/-1 streams, the immediate accepted wrap endpoint is exact
   --  and avoids astronomical linear rejection walk iterations.
   function Choose_Rank
     (Stream : Answer_Stream; N : Big_Integer) return Big_Integer;
end Synthetic_Rank_Stream_V145;
