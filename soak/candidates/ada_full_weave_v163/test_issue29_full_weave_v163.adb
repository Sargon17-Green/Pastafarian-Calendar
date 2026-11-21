with Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers;
with Canonical_Full_Weave_V163;

--  Exhaustive *independent* multiset enumeration, not calendar execution.
procedure Test_Issue29_Full_Weave_V163 is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   package CW renames Canonical_Full_Weave_V163;
   subtype Natural_Array is CW.Natural_Array;
   use type CW.Natural_Array;

   function B (X : Natural) return Big_Integer is (To_Big_Integer (Integer (X)));

   procedure Check (Lengths : Natural_Array; Expected : Natural) is
      M : constant Positive := Lengths'Length;
      Total : Natural := 0;
   begin
      for J in Lengths'Range loop
         Total := Total + Lengths (J);
      end loop;
      declare
         F : CW.Family (M);
         Remaining : Natural_Array (1 .. M);
         Current : Natural_Array (1 .. Total);
         First_Pos : Natural_Array (1 .. M);
         Last_Pos : Natural_Array (1 .. M);
         Found : Natural := 0;

         function Is_Legal return Boolean is
         begin
            First_Pos := (others => 0);
            Last_Pos := (others => 0);
            for P in Current'Range loop
               declare
                  K : constant Natural := Current (P);
               begin
                  if First_Pos (K) = 0 then
                     First_Pos (K) := P;
                  end if;
                  Last_Pos (K) := P;
               end;
            end loop;
            for K in 1 .. M - 1 loop
               if First_Pos (K) >= First_Pos (K + 1)
                 or else Last_Pos (K) >= Last_Pos (K + 1)
               then
                  return False;
               end if;
            end loop;
            return True;
         end Is_Legal;

         procedure Visit (Position : Positive) is
         begin
            if Position > Total then
               if Is_Legal then
                  Found := Found + 1;
                  declare
                     Actual : constant Natural_Array := CW.Unrank (F, B (Found));
                  begin
                     if Actual /= Current then
                        raise Program_Error with
                          "wrong lexicographic rank at" & Natural'Image (Found);
                     end if;
                  end;
               end if;
               return;
            end if;
            for J in 1 .. M loop
               if Remaining (J) > 0 then
                  Remaining (J) := Remaining (J) - 1;
                  Current (Position) := J;
                  Visit (Position + 1);
                  Remaining (J) := Remaining (J) + 1;
               end if;
            end loop;
         end Visit;
      begin
         for J in 1 .. M loop
            Remaining (J) := Lengths (Lengths'First + J - 1);
         end loop;
         CW.Build (F, Lengths);
         Visit (1);
         if Found /= Expected or else CW.Count (F) /= B (Found) then
            raise Program_Error with
              "full-family count mismatch, got" & Natural'Image (Found)
              & " expected" & Natural'Image (Expected);
         end if;
         declare
            Got_Exception : Boolean := False;
         begin
            begin
               declare
                  Invalid : constant Natural_Array := CW.Unrank (F, B (0));
               begin
                  Ada.Text_IO.Put_Line (Natural'Image (Invalid'Length));
               end;
            exception
               when Constraint_Error => Got_Exception := True;
            end;
            if not Got_Exception then
               raise Program_Error with "rank 0 must be rejected";
            end if;
         end;
         declare
            Got_Exception : Boolean := False;
         begin
            begin
               declare
                  Invalid : constant Natural_Array :=
                    CW.Unrank (F, CW.Count (F) + B (1));
               begin
                  Ada.Text_IO.Put_Line (Natural'Image (Invalid'Length));
               end;
            exception
               when Constraint_Error => Got_Exception := True;
            end;
            if not Got_Exception then
               raise Program_Error with "rank count+1 must be rejected";
            end if;
         end;
         Ada.Text_IO.Put_Line
           ("V163_PASS_MONTH_LENGTHS=" & Natural'Image (M)
            & " TOTAL=" & Natural'Image (Total)
            & " LEGAL=" & Natural'Image (Found));
      end;
   end Check;

begin
   Check ((2, 2), 2);
   Check ((4, 4), 20);
   Check ((4, 5), 35);
   Check ((2, 2, 2), 5);
   Check ((3, 2, 3), 19);
   Check ((3, 3, 3), 71);
   Check ((4, 4, 4), 1_301);
   Ada.Text_IO.Put_Line ("V163_ALL_SEVEN_EXHAUSTIVE_FAMILIES_PASS_NO_FCT");
end Test_Issue29_Full_Weave_V163;
