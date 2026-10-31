with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Wide_Wide_Text_IO;
with Exact_Math;
with Normative_Oracle;

procedure Stage06_Discovery03_Tests is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Exact_Math;
   use Normative_Oracle;

   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));
   Checks : Natural := 0;

   procedure Check (Condition : Boolean; Message : Wide_Wide_String) is
   begin
      Checks := Checks + 1;
      if not Condition then
         Ada.Wide_Wide_Text_IO.Put_Line ("విఫలం: " & Message);
         raise Program_Error;
      end if;
   end Check;

   Malformed : Sauce_Result;
   Missing_Id_Raised : Boolean := False;
begin
   for Order_Number in 1 .. 720 loop
      declare
         R : Sauce_Result;
         Valid_Order : Boolean := True;
      begin
         R.Order_At_Drop_46 := Bowl_Order_From_Number (Order_Number);
         for Id in 1 .. 6 loop
            declare
               Occurrences : Natural := 0;
            begin
               for Position in 1 .. 6 loop
                  if R.Order_At_Drop_46 (Position) = Id then
                     Occurrences := Occurrences + 1;
                  end if;
               end loop;
               if Occurrences /= 1 then
                  Valid_Order := False;
               end if;
               if Order_Number mod 2 = 0 then
                  R.Bowls (Id) := M - B (31 * Id + Order_Number);
               else
                  R.Bowls (Id) := B (Order_Number * (Id + 3) + Id);
               end if;
            end;
         end loop;
         Check (Valid_Order, "ఆరు కుండలు ఒకసారి మాత్రమే");

         for Id in 1 .. 6 loop
            declare
               Next_Id : Positive := 1;
            begin
               for Position in 1 .. 6 loop
                  if R.Order_At_Drop_46 (Position) = Id then
                     Next_Id := R.Order_At_Drop_46 (1 + (Position mod 6));
                  end if;
               end loop;
               for Seal_Case in 1 .. 3 loop
                  declare
                     Seal : constant Natural :=
                       (case Seal_Case is when 1 => 0, when 2 => 1,
                        when others => 193);
                     Raw_First : constant Big_Integer :=
                       (R.Bowls (Id) + B (Seal) + B (181)) ** 2
                       + B (179) * R.Bowls (Next_Id) + B (Seal);
                     Expected_First : constant Big_Integer :=
                       B (1) + ((Raw_First - B (1)) mod M);
                     Raw_Direction : constant Big_Integer :=
                       (Expected_First + B (Seal) + B (194)) ** 2
                       + B (193) * Expected_First + B (197) * R.Bowls (6);
                     Direction_Number : constant Big_Integer :=
                       B (1) + ((Raw_Direction - B (1)) mod M);
                     Expected_Step : constant Integer :=
                       (if Direction_Number mod B (2) = B (1) then 1 else -1);
                     Stream : constant Answer_Stream := Ask_Bowl (R, Id, Seal);
                     Expected_Next : constant Big_Integer :=
                       B (1) + ((Expected_First - B (1) + B (Expected_Step)) mod M);
                  begin
                     Check (Stream.First = Expected_First, "మొదటి జవాబు");
                     Check (Stream.Direction_Step = Expected_Step, "జవాబు దిశ");
                     Check (Answer_At (Stream, B (1)) = Expected_Next,
                            "రెండో జవాబు");
                  end;
               end loop;
            end;
         end loop;
      end;
   end loop;

   for Id in 1 .. 6 loop
      Malformed.Bowls (Id) := B (Id);
      Malformed.Order_At_Drop_46 (Id) := 1;
   end loop;
   begin
      declare
         Unused_Stream : constant Answer_Stream := Ask_Bowl (Malformed, 2, 0);
      begin
         Check (Unused_Stream.First = B (0), "తప్పు కుండ క్రమం");
      end;
   exception
      when Constraint_Error => Missing_Id_Raised := True;
   end;
   Check (Missing_Id_Raised, "లేని కుండకు పరిధి దోషం");

   Ada.Wide_Wide_Text_IO.Put_Line
     ("STAGE06_DISCOVERY03_ASSERTIONS=" & Natural'Wide_Wide_Image (Checks));
end Stage06_Discovery03_Tests;
