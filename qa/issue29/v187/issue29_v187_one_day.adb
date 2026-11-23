with Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers;
with Normative_Oracle;

procedure Issue29_V187_One_Day is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   D : constant Big_Integer := To_Big_Integer (-15_055_671);
   R : constant Normative_Oracle.Calendar_Result :=
     Normative_Oracle.Calendar_Date (D, D);
begin
   Ada.Text_IO.Put_Line
     ("ISSUE29_FINAL " &
      To_String (R.Year_Number) & " " &
      Positive'Image (R.Cutlet_Canonical) & " " &
      To_String (R.Day_In_Cutlet) & " " &
      Positive'Image (R.Month_Canonical) & " " &
      To_String (R.Day_In_Month));
end Issue29_V187_One_Day;
