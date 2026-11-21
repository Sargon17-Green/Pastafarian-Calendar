with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

--  Finite multiset brute force: independent of canonical DP.
procedure Test_Issue29_GMP_V164 is
   package CW renames Canonical_Full_Weave_GMP_V164;
   package G renames GNATCOLL.GMP.Integers;
   subtype Natural_Array is CW.Natural_Array;
   use type CW.Natural_Array;
   use G;

   procedure Check (Lengths : Natural_Array; Expected : Natural) is
      M : constant Positive := Lengths'Length;
      Total : Natural := 0;
   begin
      for J in Lengths'Range loop
         Total := Total + Lengths (J);
      end loop;
      declare
         F : CW.Family (M);
         Rem : Natural_Array (1 .. M);
         Word : Natural_Array (1 .. Total);
         First_Pos : Natural_Array (1 .. M);
         Last_Pos : Natural_Array (1 .. M);
         Found : Natural := 0;

         function Legal return Boolean is
         begin
            First_Pos := (others => 0);
            Last_Pos := (others => 0);
            for P in Word'Range loop
               if First_Pos (Word (P)) = 0 then
                  First_Pos (Word (P)) := P;
               end if;
               Last_Pos (Word (P)) := P;
            end loop;
            for J in 1 .. M - 1 loop
               if First_Pos (J) >= First_Pos (J + 1)
                 or else Last_Pos (J) >= Last_Pos (J + 1)
               then
                  return False;
               end if;
            end loop;
            return True;
         end Legal;

         procedure Walk (P : Positive) is
         begin
            if P > Total then
               if Legal then
                  Found := Found + 1;
                  declare
                     Got : constant Natural_Array :=
                       CW.Unrank (F, G.Make (Natural'Image (Found)));
                  begin
                     if Got /= Word then
                        raise Program_Error with
                          "GMP lexicographic mismatch at rank"
                          & Natural'Image (Found);
                     end if;
                  end;
               end if;
               return;
            end if;
            for J in 1 .. M loop
               if Rem (J) > 0 then
                  Rem (J) := Rem (J) - 1;
                  Word (P) := J;
                  Walk (P + 1);
                  Rem (J) := Rem (J) + 1;
               end if;
            end loop;
         end Walk;
      begin
         for J in 1 .. M loop
            Rem (J) := Lengths (Lengths'First + J - 1);
         end loop;
         CW.Build (F, Lengths);
         Walk (1);
         declare
            Size : G.Big_Integer;
         begin
            CW.Count (F, Size);
            if Found /= Expected or else Size /= G.Make (Natural'Image (Found)) then
               raise Program_Error with "GMP full-family count mismatch";
            end if;
         end;
         Ada.Text_IO.Put_Line
           ("V164_GMP_SMALL_EXHAUSTIVE_PASS_" & Natural'Image (Found));
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
   Ada.Text_IO.Put_Line ("V164_ALL_SEVEN_GMP_EXHAUSTIVE_CASES_PASS_NO_CALENDAR_F");
end Test_Issue29_GMP_V164;
