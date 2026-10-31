with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Wide_Wide_Text_IO;
with Exact_Math;
with Normative_Oracle;

procedure Stage07_Discovery04_Tests is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Exact_Math;
   use Normative_Oracle;

   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));

   type Fixture is record
      Calculation_Day, Target_Day : Big_Integer;
      Expected_Action, Expected_Target : Big_Integer;
      Expected_Distance, Expected_Connection : Big_Integer;
      Expected_Direction : Positive range 1 .. 3;
   end record;

   -- Literal independent Work_Count witnesses.
   Cases : constant array (Positive range 1 .. 6) of Fixture :=
     (1 => (Foundation_Day, Foundation_Day,
            B (1), B (1), B (1), B (2), 2),
      2 => (Foundation_Day, Foundation_Day + B (1),
            B (1), B (3), B (2), B (4), 3),
      3 => (Foundation_Day, Foundation_Day - B (1),
            B (1), B (2), B (2), B (3), 1),
      4 => (Tablets_Day, Tablets_Day,
            B (29_554_299), B (29_554_299), B (1), B (59_108_598), 2),
      5 => (Tablets_Day - B (1), Tablets_Day + B (31),
            B (29_554_297), B (29_554_361), B (33), B (59_108_658), 3),
      6 => (Foundation_Day + B (400), Foundation_Day - B (400),
            B (801), B (800), B (801), B (1_601), 1));
   Seals : constant array (Positive range 1 .. 3) of Natural := (0, 1, 193);
   Assertions : Natural := 0;

   procedure Check (Condition : Boolean; Message : Wide_Wide_String) is
   begin
      Assertions := Assertions + 1;
      if not Condition then
         Ada.Wide_Wide_Text_IO.Put_Line ("విఫలం: " & Message);
         raise Program_Error;
      end if;
   end Check;

begin
   for Index in Cases'Range loop
      declare
         F : constant Fixture := Cases (Index);
         Counts : constant Work_Counts :=
           Compute_Work_Counts (F.Calculation_Day, F.Target_Day);
         Stones : constant Stone_Table := Build_Stones;
         Hidden : constant Hidden_Drops := Build_Hidden_Drops (Counts, Stones);
         Visible : constant Visible_Drops :=
           Build_Visible_Drops (Counts, Stones, Hidden);
         Actual : constant Sauce_Result :=
           Sauce (F.Calculation_Day, F.Target_Day);
         Expected_Order : constant Bowl_Order :=
           Bowl_Order_From_Drop (Visible (46));
         Valid : Boolean := True;
      begin
         Check (Counts.Action = F.Expected_Action, "చర్య సంఖ్య");
         Check (Counts.Target = F.Expected_Target, "లక్ష్య సంఖ్య");
         Check (Counts.Distance = F.Expected_Distance, "దూరం");
         Check (Counts.Connection = F.Expected_Connection, "బంధం");
         Check (Counts.Direction = F.Expected_Direction, "దిశ");
         Check (Actual.Order_At_Drop_46 = Expected_Order, "కుండ క్రమ మూలం");
         for Id in 1 .. 6 loop
            declare
               Found : Natural := 0;
            begin
               for Position in 1 .. 6 loop
                  if Actual.Order_At_Drop_46 (Position) = Id then
                     Found := Found + 1;
                  end if;
               end loop;
               if Found /= 1 then
                  Valid := False;
               end if;
            end;
         end loop;
         Check (Valid, "ఆరు కుండలు ఒక్కొక్కసారి");

         for Id in 1 .. 6 loop
            Check (Actual.Bowls (Id) >= B (1) and then
                   Actual.Bowls (Id) <= M, "కుండ పరిధి");
            for Seal of Seals loop
               declare
                  S : constant Answer_Stream := Ask_Bowl (Actual, Id, Seal);
                  A0 : constant Big_Integer := Answer_At (S, B (0));
                  A1 : constant Big_Integer := Answer_At (S, B (1));
                  A2 : constant Big_Integer := Answer_At (S, B (2));
                  AM : constant Big_Integer := Answer_At (S, M);
                  AM1 : constant Big_Integer := Answer_At (S, M + B (1));
                  Expected_A2 : constant Big_Integer :=
                    B (1) + ((A1 - B (1) + B (S.Direction_Step)) mod M);
               begin
                  Check (S.First >= B (1) and then S.First <= M,
                         "నిజ సమాధాన పరిధి");
                  Check (S.Direction_Step = -1 or else
                         S.Direction_Step = 1, "నిజ దిశ");
                  Check (A0 = S.First, "మొదటి స్థానం");
                  Check (AM = S.First, "ఆవర్తన మూలం");
                  Check (AM1 = A1, "ఆవర్తన మార్పు");
                  Check (A2 = Expected_A2, "ఒకే మాడ్యులో అడుగు");
               end;
            end loop;
         end loop;

         declare
            Rejected : Boolean := False;
         begin
            begin
               declare
                  Unused : constant Answer_Stream := Ask_Bowl (Actual, 7, 0);
               begin
                  if Unused.Direction_Step = 0 then null; end if;
               end;
            exception
               when Constraint_Error => Rejected := True;
            end;
            Check (Rejected, "అనుమతిలేని కుండ గుర్తింపు");
         end;
         declare
            Rejected : Boolean := False;
         begin
            begin
               declare
                  S : constant Answer_Stream := Ask_Bowl (Actual, 1, 0);
                  Unused : constant Big_Integer := Answer_At (S, B (-1));
               begin
                  if Unused = B (0) then null; end if;
               end;
            exception
               when Constraint_Error => Rejected := True;
            end;
            Check (Rejected, "ఋణ స్థానం");
         end;
      end;
   end loop;
   Ada.Wide_Wide_Text_IO.Put_Line
     ("STAGE07_DISCOVERY04_ASSERTIONS=" & Natural'Wide_Wide_Image (Assertions));
end Stage07_Discovery04_Tests;
