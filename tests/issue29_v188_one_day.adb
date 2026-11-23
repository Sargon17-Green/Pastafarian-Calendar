with Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers;
with Normative_Oracle;

--  Issue29 QA v188: exactly one real corrected Ada Calendar_Date invocation.
--  Input is the single formally authorized foundation-day witness.
procedure Issue29_V188_One_Day is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   D : constant Big_Integer := To_Big_Integer (-15_055_671);
   Result : constant Normative_Oracle.Calendar_Result :=
     Normative_Oracle.Calendar_Date (D, D);
begin
   Ada.Text_IO.Put_Line
     ("ISSUE29_V188_CORRECTED_ADA -15055671 -15055671 " &
       To_String (Result.Year_Number) & " " &
       Positive'Image (Result.Cutlet_Canonical) & " " &
       To_String (Result.Day_In_Cutlet) & " " &
       Positive'Image (Result.Month_Canonical) & " " &
       To_String (Result.Day_In_Month));
end Issue29_V188_One_Day;
