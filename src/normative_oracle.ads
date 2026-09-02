with Ada.Numerics.Big_Numbers.Big_Integers;

package Normative_Oracle is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   Tablets_Day    : constant Big_Integer := To_Big_Integer (-278_522);
   Foundation_Day : constant Big_Integer := To_Big_Integer (-15_055_671);

   type Work_Counts is record
      Action     : Big_Integer;
      Target     : Big_Integer;
      Distance   : Big_Integer;
      Connection : Big_Integer;
      Direction  : Positive range 1 .. 3;
   end record;

   type Stone_Record is record
      Wheat  : Big_Integer;
      Barley : Big_Integer;
      Salt   : Big_Integer;
      Bitter : Big_Integer;
      Red    : Big_Integer;
   end record;

   type Stone_Table is array (Positive range 1 .. 46) of Stone_Record;
   type Hidden_Drops is array (Positive range 1 .. 7) of Big_Integer;
   type Visible_Drops is array (Positive range 1 .. 46) of Big_Integer;
   type Bowl_Array is array (Positive range 1 .. 6) of Big_Integer;
   type Bowl_Order is array (Positive range 1 .. 6) of Positive range 1 .. 6;

   type Sauce_Result is record
      Bowls            : Bowl_Array;
      Order_At_Drop_46 : Bowl_Order;
   end record;

   type Answer_Stream is record
      First          : Big_Integer;
      Direction_Step : Integer range -1 .. 1;
   end record;

   type Calendar_Result is record
      Year_Number          : Big_Integer;
      Cutlet_Canonical     : Positive range 1 .. 17;
      Day_In_Cutlet        : Big_Integer;
      Month_Canonical      : Positive range 1 .. 47;
      Day_In_Month         : Big_Integer;
   end record;

   function Day_Count (Day : Big_Integer) return Big_Integer;
   function Compute_Work_Counts
     (Calculation_Day, Target_Day : Big_Integer) return Work_Counts;
   function Build_Stones return Stone_Table;
   function Build_Hidden_Drops
     (Counts : Work_Counts; Stones : Stone_Table) return Hidden_Drops;
   function Build_Visible_Drops
     (Counts : Work_Counts; Stones : Stone_Table; Hidden : Hidden_Drops)
      return Visible_Drops;
   function Bowl_Order_From_Number (Order_Number : Positive) return Bowl_Order;
   function Bowl_Order_From_Drop (Drop_Value : Big_Integer) return Bowl_Order;
   function Sauce
     (Calculation_Day, Target_Day : Big_Integer) return Sauce_Result;
   function Ask_Bowl
     (R : Sauce_Result; Queried_Bowl_Id : Positive; Seal : Natural)
      return Answer_Stream;
   function Answer_At (Stream : Answer_Stream; K : Big_Integer) return Big_Integer;
   function Choose_Rank
     (Stream : Answer_Stream; N : Big_Integer) return Big_Integer;
   function Calendar_Date
     (Calculation_Day, Target_Day : Big_Integer) return Calendar_Result;
end Normative_Oracle;
