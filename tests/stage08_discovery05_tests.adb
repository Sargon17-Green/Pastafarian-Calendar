with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Wide_Wide_Text_IO;
with Exact_Math;
with Normative_Oracle;

procedure Stage08_Discovery05_Tests is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Exact_Math;
   use Normative_Oracle;

   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));

   type Date_Pair is record
      Calculation_Day, Target_Day : Big_Integer;
   end record;
   Cases : constant array (Positive range 1 .. 6) of Date_Pair :=
     (1 => (Foundation_Day, Foundation_Day),
      2 => (Foundation_Day, Foundation_Day + B (1)),
      3 => (Foundation_Day, Foundation_Day - B (1)),
      4 => (Tablets_Day, Tablets_Day),
      5 => (Tablets_Day - B (1), Tablets_Day + B (31)),
      6 => (Foundation_Day + B (400), Foundation_Day - B (400)));
   Seals : constant array (Positive range 1 .. 3) of Natural := (0, 1, 193);
   Short_Reject_N : constant Big_Integer := (M / B (2)) + B (1);
   Wide_Reject_N : constant Big_Integer := ((M * M) / B (2)) + B (1);
   Assertions : Natural := 0;

   procedure Check (Condition : Boolean; Message : Wide_Wide_String) is
   begin
      Assertions := Assertions + 1;
      if not Condition then
         Ada.Wide_Wide_Text_IO.Put_Line ("విఫలం: " & Message);
         raise Program_Error;
      end if;
   end Check;

   -- Independent two-digit base-M positional model of the acceptance
   -- interval. It does not call Choose_Rank or Answer_At.
   -- Precondition: S.First in 1..M, step +/-1, 1 <= N <= M*M.
   function Reference_Rank
     (S : Answer_Stream; N : Big_Integer) return Big_Integer
   is
      Space : Big_Integer := M;
      Initial : Big_Integer := S.First;
   begin
      if N > M then
         Space := M * M;
         declare
            Second : constant Big_Integer :=
              B (1) + ((S.First - B (1) + B (S.Direction_Step)) mod M);
         begin
            Initial := S.First + M * (Second - B (1));
         end;
      end if;

      declare
         Limit : constant Big_Integer := Space - (Space mod N);
         Accepted : Big_Integer := Initial;
      begin
         if Accepted > Limit then
            if S.Direction_Step = -1 then
               Accepted := Limit;
            elsif S.Direction_Step = 1 then
               Accepted := B (1);
            else
               raise Constraint_Error;
            end if;
         end if;
         return B (1) + ((Accepted - B (1)) mod N);
      end;
   end Reference_Rank;

   procedure Check_Invalid_Family (N : Big_Integer) is
      Rejected : Boolean := False;
   begin
      begin
         declare
            Ignored : constant Big_Integer :=
              Choose_Rank ((First => B (1), Direction_Step => 1), N);
         begin
            if Ignored < B (0) then null; end if;
         end;
      exception
         when Constraint_Error => Rejected := True;
      end;
      Check (Rejected, "చెల్లని ఎంపిక పరిమాణం");
   end Check_Invalid_Family;

begin
   -- 6 dates x 6 actual Sauce bowls x 3 seals x 4 rank families = 432.
   for Pair of Cases loop
      declare
         Actual : constant Sauce_Result :=
           Sauce (Pair.Calculation_Day, Pair.Target_Day);
      begin
         for Id in 1 .. 6 loop
            for Seal of Seals loop
               declare
                  S : constant Answer_Stream := Ask_Bowl (Actual, Id, Seal);
               begin
                  Check (Choose_Rank (S, B (922)) =
                         Reference_Rank (S, B (922)), "చిన్న 922 ఎంపిక");
                  Check (Choose_Rank (S, Short_Reject_N) =
                         Reference_Rank (S, Short_Reject_N),
                         "చిన్న తిరస్కరణ సరిహద్దు");
                  Check (Choose_Rank (S, M + B (1)) =
                         Reference_Rank (S, M + B (1)),
                         "విస్తృత రెండు అంకెల సరిహద్దు");
                  Check (Choose_Rank (S, Wide_Reject_N) =
                         Reference_Rank (S, Wide_Reject_N),
                         "విస్తృత తిరస్కరణ సరిహద్దు");
               end;
            end loop;
         end loop;
      end;
   end loop;

   -- Four forced rejection endpoints; each direction and width.
   Check (Choose_Rank
            ((First => M - B (1), Direction_Step => -1),
             Short_Reject_N) = Short_Reject_N, "చిన్న ఋణ చివర");
   Check (Choose_Rank
            ((First => M - B (1), Direction_Step => 1),
             Short_Reject_N) = B (1), "చిన్న ధన చివర");
   Check (Choose_Rank
            ((First => M, Direction_Step => -1),
             Wide_Reject_N) = Wide_Reject_N, "విస్తృత ఋణ చివర");
   Check (Choose_Rank
            ((First => M - B (1), Direction_Step => 1),
             Wide_Reject_N) = B (1), "విస్తృత ధన చివర");
   Check_Invalid_Family (B (0));
   Check_Invalid_Family (B (-1));

   Ada.Wide_Wide_Text_IO.Put_Line
     ("STAGE08_DISCOVERY05_ASSERTIONS=" & Natural'Wide_Wide_Image (Assertions));
end Stage08_Discovery05_Tests;
