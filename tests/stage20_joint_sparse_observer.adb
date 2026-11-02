with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Normative_Oracle;

procedure Stage20_Joint_Sparse_Observer is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Normative_Oracle;
   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));
   Repeated : constant Calendar_Result :=
     Calendar_Date (Foundation_Day, Foundation_Day);
   Checked : Natural := 0;
   Cal_Offsets : constant array (Positive range 1 .. 5) of Integer :=
     (-5_779, -31, 0, 31, 5_779);
   Target_Offsets : constant array (Positive range 1 .. 5) of Integer :=
     (-5_779, -31, 0, 31, 5_779);

   procedure Require (OK : Boolean; Pair_ID : Positive; What : String) is
   begin
      Checked := Checked + 1;
      if not OK then
         Ada.Text_IO.Put_Line
           ("STAGE20_OBSERVER_FAIL pair=" & Positive'Image (Pair_ID)
            & " check=" & What);
         raise Program_Error with "Stage20 invariant failed";
      end if;
   end Require;
begin
   for CI in Cal_Offsets'Range loop
      for TI in Target_Offsets'Range loop
         declare
            Cal : constant Big_Integer := Foundation_Day + B (Cal_Offsets (CI));
            Target : constant Big_Integer := Foundation_Day + B (Target_Offsets (TI));
            Pair_ID : constant Positive := Positive (5 * (CI - 1) + TI);
            V : constant Calendar_Result := Calendar_Date (Cal, Target);
         begin
            Require (V.Year_Number >= B (4_900)
                     and then V.Year_Number <= B (5_100), Pair_ID, "year");
            Require (V.Cutlet_Canonical in 1 .. 17, Pair_ID, "cutlet");
            Require (V.Day_In_Cutlet >= B (1)
                     and then V.Day_In_Cutlet <= B (5_778),
                     Pair_ID, "cutlet day");
            Require (V.Month_Canonical in 1 .. 47, Pair_ID, "month");
            Require (V.Day_In_Month >= B (1)
                     and then V.Day_In_Month <= B (123),
                     Pair_ID, "month day");
            if CI = 3 and then TI = 3 then
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
              ("STAGE20_NATIVE_PAIR " & To_String (Cal) & " "
               & To_String (Target) & " " & To_String (V.Year_Number)
               & " " & Positive'Image (V.Cutlet_Canonical)
               & " " & To_String (V.Day_In_Cutlet)
               & " " & Positive'Image (V.Month_Canonical)
               & " " & To_String (V.Day_In_Month));
         end;
      end loop;
   end loop;
   if Checked /= 131 then
      raise Program_Error with "Stage20 expected 131 checks";
   end if;
   Ada.Text_IO.Put_Line
     ("STAGE20_NATIVE_JOINT_SPARSE_ASSERTIONS=" & Natural'Image (Checked));
end Stage20_Joint_Sparse_Observer;
