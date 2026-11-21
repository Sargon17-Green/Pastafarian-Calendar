with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Normative_Oracle;

-- QA-only probe, compiled against EXACT Ada+Telugu development branch sources.
-- Deliberately contains one and only one Calendar_Date invocation.
procedure Issue29_V168_Native_Foundation_Probe is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Normative_Oracle;
begin
   declare
      Result : constant Calendar_Result :=
        Calendar_Date (Foundation_Day, Foundation_Day);
   begin
      Ada.Text_IO.Put_Line
        ("ISSUE29_V168_NATIVE_FOUNDATION|"
         & To_String (Result.Year_Number)
         & "|" & Positive'Image (Result.Cutlet_Canonical)
         & "|" & To_String (Result.Day_In_Cutlet)
         & "|" & Positive'Image (Result.Month_Canonical)
         & "|" & To_String (Result.Day_In_Month));
   end;
end Issue29_V168_Native_Foundation_Probe;
