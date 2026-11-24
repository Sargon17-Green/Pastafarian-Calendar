with Ada.Command_Line;
with Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers;
with Normative_Oracle;

procedure Issue29_V192_Panel is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   C : constant Big_Integer := To_Big_Integer (-15_055_671);
   T : Big_Integer;
begin
   if Ada.Command_Line.Argument_Count /= 1 then
      raise Constraint_Error with "expected exactly one target";
   end if;
   T := From_String (Ada.Command_Line.Argument (1));
   if T /= To_Big_Integer (-15_055_658)
     and then T /= To_Big_Integer (-15_056_671)
     and then T /= To_Big_Integer (-15_054_671)
     and then T /= To_Big_Integer (-15_057_702)
     and then T /= To_Big_Integer (-15_057_696)
     and then T /= To_Big_Integer (-15_057_695)
     and then T /= To_Big_Integer (-15_056_944)
     and then T /= To_Big_Integer (-15_056_943)
     and then T /= To_Big_Integer (-15_055_670)
   then
      raise Constraint_Error with "target outside bounded QA panel";
   end if;
   declare
      R : constant Normative_Oracle.Calendar_Result :=
        Normative_Oracle.Calendar_Date (C, T);
   begin
      Ada.Text_IO.Put_Line
        ("ISSUE29_V191_CORRECTED_ADA " & To_String (C) & " " &
         To_String (T) & " " & To_String (R.Year_Number) & " " &
         Positive'Image (R.Cutlet_Canonical) & " " &
         To_String (R.Day_In_Cutlet) & " " &
         Positive'Image (R.Month_Canonical) & " " &
         To_String (R.Day_In_Month));
   end;
end Issue29_V192_Panel;
