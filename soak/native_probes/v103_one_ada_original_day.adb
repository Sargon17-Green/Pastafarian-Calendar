with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Normative_Oracle;

-- One read-only call to the pinned Ada original production/reference source.
-- This QA bridge does no date calculation or independent algorithm.
procedure V103_One_Ada_Original_Day is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Normative_Oracle;
   C : constant Big_Integer := Foundation_Day;
   T : constant Big_Integer := Foundation_Day;
   R : constant Calendar_Result := Calendar_Date (C, T);
begin
   Ada.Text_IO.Put_Line
     ("V103_ADA_ORIGINAL_FCT_NATIVE "
      & To_String (C) & " " & To_String (T)
      & " " & To_String (R.Year_Number)
      & " " & Positive'Image (R.Cutlet_Canonical)
      & " " & To_String (R.Day_In_Cutlet)
      & " " & Positive'Image (R.Month_Canonical)
      & " " & To_String (R.Day_In_Month));
end V103_One_Ada_Original_Day;
