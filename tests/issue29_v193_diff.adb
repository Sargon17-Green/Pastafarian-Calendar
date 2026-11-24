with Ada.Command_Line;
with Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers;
with Normative_Oracle;
procedure Issue29_V193_Diff is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   C, T : Big_Integer;
begin
   if Ada.Command_Line.Argument_Count /= 2 then
      raise Constraint_Error with "exactly two arguments";
   end if;
   C := From_String (Ada.Command_Line.Argument (1));
   T := From_String (Ada.Command_Line.Argument (2));
   if not ((C = To_Big_Integer (-15055671) and then T = To_Big_Integer (-15057703))
      or else (C = To_Big_Integer (-15055671) and then T = To_Big_Integer (-15053459))
      or else (C = To_Big_Integer (-15055671) and then T = To_Big_Integer (-15053458))
      or else (C = To_Big_Integer (-15055672) and then T = To_Big_Integer (-15055671))
      or else (C = To_Big_Integer (-15055670) and then T = To_Big_Integer (-15055671))
      or else (C = To_Big_Integer (-15055629) and then T = To_Big_Integer (-15055629)))
   then
      raise Constraint_Error with "outside six-case whitelist";
   end if;
   declare
      R : constant Normative_Oracle.Calendar_Result := Normative_Oracle.Calendar_Date (C, T);
   begin
      Ada.Text_IO.Put_Line ("ISSUE29_V193 " & To_String (C) & " " &
         To_String (T) & " " & To_String (R.Year_Number) & " " &
         Positive'Image (R.Cutlet_Canonical) & " " & To_String (R.Day_In_Cutlet) & " " &
         Positive'Image (R.Month_Canonical) & " " & To_String (R.Day_In_Month));
   end;
end Issue29_V193_Diff;
