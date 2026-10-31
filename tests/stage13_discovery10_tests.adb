with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Normative_Oracle;

procedure Stage13_Discovery10_Tests is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Normative_Oracle;

   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));

   -- Three adjacent target days, one fixed calculation day.
   -- This probes the real five-field calendar output, not a synthetic stream.
   type Result_Vector is array (Positive range 1 .. 3) of Calendar_Result;
   Results : constant Result_Vector :=
     (1 => Calendar_Date (Foundation_Day, Foundation_Day - B (1)),
      2 => Calendar_Date (Foundation_Day, Foundation_Day),
      3 => Calendar_Date (Foundation_Day, Foundation_Day + B (1)));
   Repeated_Anchor : constant Calendar_Result :=
     Calendar_Date (Foundation_Day, Foundation_Day);

   Assertions : Natural := 0;

   procedure Require (Condition : Boolean; Case_No : Natural; Name : String) is
   begin
      Assertions := Assertions + 1;
      if not Condition then
         Ada.Text_IO.Put_Line
           ("CASE=" & Natural'Image (Case_No) & " CHECK=" & Name);
         raise Program_Error with "Stage13 calendar postcondition mismatch";
      end if;
   end Require;

begin
   for C in Results'Range loop
      -- Independent, published domain constraints. The year anchor is 5000
      -- and one-day targets cannot traverse more than one full year.
      Require (Results (C).Year_Number >= B (4_999)
               and then Results (C).Year_Number <= B (5_001),
               C, "year neighborhood");
      Require (Results (C).Cutlet_Canonical in 1 .. 17,
               C, "cutlet name");
      Require (Results (C).Day_In_Cutlet >= B (1)
               and then Results (C).Day_In_Cutlet <= B (5_778),
               C, "cutlet day");
      Require (Results (C).Month_Canonical in 1 .. 47,
               C, "month name");
      Require (Results (C).Day_In_Month >= B (1)
               and then Results (C).Day_In_Month <= B (123),
               C, "month day");
   end loop;

   -- The year-5000 candidate interval is defined to contain its
   -- calculation day (Open < Foundation <= Close).
   Require (Results (2).Year_Number = B (5_000), 2, "year-5000 anchor");

   -- A second independent invocation must give identical five components.
   Require (Repeated_Anchor.Year_Number = Results (2).Year_Number,
            2, "repeat year");
   Require (Repeated_Anchor.Cutlet_Canonical = Results (2).Cutlet_Canonical,
            2, "repeat cutlet");
   Require (Repeated_Anchor.Day_In_Cutlet = Results (2).Day_In_Cutlet,
            2, "repeat cutlet day");
   Require (Repeated_Anchor.Month_Canonical = Results (2).Month_Canonical,
            2, "repeat month");
   Require (Repeated_Anchor.Day_In_Month = Results (2).Day_In_Month,
            2, "repeat month day");

   for C in 1 .. 2 loop
      Require (Results (C).Year_Number <= Results (C + 1).Year_Number,
               C, "year monotonicity");
      Require (Results (C + 1).Year_Number - Results (C).Year_Number <= B (1),
               C, "adjacent year step");
   end loop;

   if Assertions /= 25 then
      raise Program_Error with "Stage13 expected exactly 25 assertions";
   end if;
   Ada.Text_IO.Put_Line
     ("STAGE13_DISCOVERY10_ASSERTIONS=" & Natural'Image (Assertions));
end Stage13_Discovery10_Tests;
