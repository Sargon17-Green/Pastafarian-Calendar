with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Normative_Oracle;

procedure Stage15_Multi_Calibration_Observer is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Normative_Oracle;
   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));
   Repeated : constant Calendar_Result :=
     Calendar_Date (Foundation_Day, Foundation_Day);
   Checked : Natural := 0;

   procedure Require (OK : Boolean; Pair_ID : Positive; What : String) is
   begin
      Checked := Checked + 1;
      if not OK then
         Ada.Text_IO.Put_Line
           ("STAGE15_OBSERVER_FAIL pair=" & Positive'Image (Pair_ID)
            & " check=" & What);
         raise Program_Error with "Stage15 invariant failed";
      end if;
   end Require;
begin
   for C in -1 .. 1 loop
      for T in -1 .. 1 loop
         declare
            Cal : constant Big_Integer := Foundation_Day + B (C);
            Target : constant Big_Integer := Foundation_Day + B (T);
            Pair_ID : constant Positive := Positive (3 * (C + 1) + T + 2);
            V : constant Calendar_Result := Calendar_Date (Cal, Target);
         begin
            Require (V.Year_Number >= B (4_999)
                     and then V.Year_Number <= B (5_001), Pair_ID, "year");
            Require (V.Cutlet_Canonical in 1 .. 17, Pair_ID, "cutlet");
            Require (V.Day_In_Cutlet >= B (1)
                     and then V.Day_In_Cutlet <= B (5_778),
                     Pair_ID, "cutlet day");
            Require (V.Month_Canonical in 1 .. 47, Pair_ID, "month");
            Require (V.Day_In_Month >= B (1)
                     and then V.Day_In_Month <= B (123),
                     Pair_ID, "month day");
            if C = 0 and then T = 0 then
               Require (V.Year_Number = B (5_000), Pair_ID, "anchor");
               Require (V.Year_Number = Repeated.Year_Number, Pair_ID, "repeat year");
               Require (V.Cutlet_Canonical = Repeated.Cutlet_Canonical,
                        Pair_ID, "repeat cutlet");
               Require (V.Day_In_Cutlet = Repeated.Day_In_Cutlet,
                        Pair_ID, "repeat cutlet day");
               Require (V.Month_Canonical = Repeated.Month_Canonical,
                        Pair_ID, "repeat month");
               Require (V.Day_In_Month = Repeated.Day_In_Month,
                        Pair_ID, "repeat month day");
            end if;
            Ada.Text_IO.Put_Line
              ("STAGE15_NATIVE_PAIR " & To_String (Cal) & " "
               & To_String (Target) & " " & To_String (V.Year_Number)
               & " " & Positive'Image (V.Cutlet_Canonical)
               & " " & To_String (V.Day_In_Cutlet)
               & " " & Positive'Image (V.Month_Canonical)
               & " " & To_String (V.Day_In_Month));
         end;
      end loop;
   end loop;
   if Checked /= 51 then
      raise Program_Error with "Stage15 expected 51 checks";
   end if;
   Ada.Text_IO.Put_Line
     ("STAGE15_NATIVE_DOMAIN_REPEAT_ASSERTIONS=" & Natural'Image (Checked));
end Stage15_Multi_Calibration_Observer;
