with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Wide_Wide_Text_IO;
with Exact_Math;
with Normative_Oracle;
procedure Stage05_Patch02_Tests is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Exact_Math;
   use Normative_Oracle;
   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));
   Checks : Natural := 0;
   Zero_Raised : Boolean := False;
   procedure Check (Condition : Boolean; Message : Wide_Wide_String) is
   begin
      Checks := Checks + 1;
      if not Condition then
         Ada.Wide_Wide_Text_IO.Put_Line ("విఫలం: " & Message);
         raise Program_Error;
      end if;
   end Check;
   N : constant Big_Integer := Floor_Div (M, B (2)) + B (1);
   Minus_Stream : constant Answer_Stream :=
     (First => M - B (1), Direction_Step => -1);
   Plus_Stream : constant Answer_Stream :=
     (First => M - B (1), Direction_Step => 1);
begin
   -- Exhaustive bounded independent mini-model: 1456 comparisons.
   for Modulus in 7 .. 13 loop
      for Family_Size in 1 .. Modulus loop
         for First in 1 .. Modulus loop
            for Direction in -1 .. 1 loop
               if Direction /= 0 then
                  declare
                     Limit : constant Integer :=
                       (Modulus / Family_Size) * Family_Size;
                     Historic : Integer := First;
                     Direct : constant Integer :=
                       (if First <= Limit then First
                        elsif Direction = -1 then Limit else 1);
                     Steps : Natural := 0;
                  begin
                     while Historic > Limit loop
                        Historic := 1 + ((Historic - 1 + Direction
                                             + Modulus) mod Modulus);
                        Steps := Steps + 1;
                        if Steps > Modulus then
                           raise Program_Error with "mini loop exhausted";
                        end if;
                     end loop;
                     Check (1 + ((Historic - 1) mod Family_Size)
                            = 1 + ((Direct - 1) mod Family_Size),
                            "చిన్న చక్ర భేద పరీక్ష");
                  end;
               end if;
            end loop;
         end loop;
      end loop;
   end loop;
   Check (Choose_Rank (Minus_Stream, N) = N, "ఋణ ప్రత్యక్ష ఫలితం");
   Check (Choose_Rank (Plus_Stream, N) = B (1), "ధన తిరుగు");
   Check (Choose_Rank ((First => N, Direction_Step => -1), N) = N,
          "తక్షణ స్వీకరణ");
   Check (Choose_Rank ((First => B (1), Direction_Step => 0), N) = B (1),
          "స్థిర స్వీకరణ");
   begin
      declare
         Ignored : constant Big_Integer :=
           Choose_Rank ((First => M - B (1), Direction_Step => 0), N);
      begin
         if Ignored >= B (1) then null; end if;
      end;
   exception
      when Constraint_Error => Zero_Raised := True;
   end;
   Check (Zero_Raised, "స్థిర తిరస్కరణ దోషం");
   Check (Choose_Rank ((First => M + B (1), Direction_Step => 1), N)
          = B (1), "మొదటి సంఖ్య మాడ్యులో");
   Check (Choose_Rank (Minus_Stream, B (1)) = B (1), "ఒకే ఎంపిక");
   Check (Choose_Rank (Minus_Stream, M) = M - B (1), "చిన్న సరిహద్దు");
   Check (Choose_Rank ((First => B (1), Direction_Step => 1), M + B (1))
          = M + B (1), "విస్తృత మార్గం");
   Ada.Wide_Wide_Text_IO.Put_Line
     ("STAGE05_PATCH02_ASSERTIONS=" & Natural'Wide_Wide_Image (Checks));
end Stage05_Patch02_Tests;
