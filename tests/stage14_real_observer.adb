with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Normative_Oracle;

procedure Stage14_Real_Observer is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Normative_Oracle;

   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));

   type Result_List is array (Positive range 1 .. 3) of Calendar_Result;
   Actual : constant Result_List :=
     (1 => Calendar_Date (Foundation_Day, Foundation_Day - B (1)),
      2 => Calendar_Date (Foundation_Day, Foundation_Day),
      3 => Calendar_Date (Foundation_Day, Foundation_Day + B (1)));
   Repeated : constant Calendar_Result := Calendar_Date (Foundation_Day, Foundation_Day);
   Checked : Natural := 0;

   procedure Require (OK : Boolean; At_Case : Positive; What : String) is
   begin
      Checked := Checked + 1;
      if not OK then
         Ada.Text_IO.Put_Line
           ("STAGE14_OBSERVER_FAIL case=" & Positive'Image (At_Case)
            & " check=" & What);
         raise Program_Error with "Stage14 native observer invariant failed";
      end if;
   end Require;

   procedure Print_Date (Target : Big_Integer; Result : Calendar_Result) is
   begin
      Ada.Text_IO.Put_Line
        ("STAGE14_NATIVE_DATE "
         & To_String (Target) & " " & To_String (Result.Year_Number)
         & " " & Positive'Image (Result.Cutlet_Canonical)
         & " " & To_String (Result.Day_In_Cutlet)
         & " " & Positive'Image (Result.Month_Canonical)
         & " " & To_String (Result.Day_In_Month));
   end Print_Date;
begin
   for I in Actual'Range loop
      Require (Actual (I).Year_Number >= B (4_999)
               and then Actual (I).Year_Number <= B (5_001), I, "year");
      Require (Actual (I).Cutlet_Canonical in 1 .. 17, I, "cutlet");
      Require (Actual (I).Day_In_Cutlet >= B (1)
               and then Actual (I).Day_In_Cutlet <= B (5_778),
               I, "day in cutlet");
      Require (Actual (I).Month_Canonical in 1 .. 47, I, "month");
      Require (Actual (I).Day_In_Month >= B (1)
               and then Actual (I).Day_In_Month <= B (123),
               I, "day in month");
      Print_Date (Foundation_Day + B (I - 2), Actual (I));
   end loop;
   Require (Actual (2).Year_Number = B (5_000), 2, "year anchor");
   Require (Repeated.Year_Number = Actual (2).Year_Number, 2, "repeat year");
   Require (Repeated.Cutlet_Canonical = Actual (2).Cutlet_Canonical, 2, "repeat cutlet");
   Require (Repeated.Day_In_Cutlet = Actual (2).Day_In_Cutlet, 2, "repeat cutlet day");
   Require (Repeated.Month_Canonical = Actual (2).Month_Canonical, 2, "repeat month");
   Require (Repeated.Day_In_Month = Actual (2).Day_In_Month, 2, "repeat month day");
   if Checked /= 21 then
      raise Program_Error with "Stage14 observer expected 21 invariants";
   end if;
   Ada.Text_IO.Put_Line
     ("STAGE14_NATIVE_DOMAIN_REPEAT_ASSERTIONS=" & Natural'Image (Checked));
end Stage14_Real_Observer;
