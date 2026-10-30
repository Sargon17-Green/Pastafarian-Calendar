with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Wide_Wide_Text_IO;
with Exact_Math;
with Normative_Oracle;

procedure Stage03_Patch01_Tests is
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

   --  Only two places are required for these N values (M < N <= M*M).
   --  Independent algebraic result, rather than invoking the patched loop.
   function Expected_Wide
     (Stream : Answer_Stream; N : Big_Integer) return Big_Integer
   is
      Space : constant Big_Integer := M * M;
      Limit : constant Big_Integer := Floor_Div (Space, N) * N;
      W     : constant Big_Integer :=
        B (1) + Answer_At (Stream, B (0)) - B (1)
        + (Answer_At (Stream, B (1)) - B (1)) * M;
   begin
      if W > Limit then
         if Stream.Direction_Step = -1 then
            return Regular_Mod (Limit - B (1), N) + B (1);
         elsif Stream.Direction_Step = 1 then
            return B (1);
         else
            raise Constraint_Error;
         end if;
      end if;
      return Regular_Mod (W - B (1), N) + B (1);
   end Expected_Wide;

   --  Preserved historical loop for tiny, explicitly bounded comparisons.
   --  Never use this on the astronomical Stage 2 witness.
   function Legacy_Bounded
     (Stream : Answer_Stream; N : Big_Integer; Max_Steps : Positive)
      return Big_Integer
   is
      Space : constant Big_Integer := M * M;
      Limit : constant Big_Integer := Floor_Div (Space, N) * N;
      W     : Big_Integer :=
        B (1) + (Answer_At (Stream, B (0)) - B (1))
        + (Answer_At (Stream, B (1)) - B (1)) * M;
   begin
      for I in 1 .. Max_Steps loop
         exit when W <= Limit;
         W := B (1) + Regular_Mod
           (W - B (1) + B (Stream.Direction_Step), Space);
      end loop;
      if W > Limit then
         raise Program_Error with "historical bounded comparison exhausted";
      end if;
      return Regular_Mod (W - B (1), N) + B (1);
   end Legacy_Bounded;

   procedure Check_Real_Ask_Bowl
     (Calculation_Day, Target_Day : Big_Integer; N : Big_Integer)
   is
      R : constant Sauce_Result := Sauce (Calculation_Day, Target_Day);
      S : constant Answer_Stream := Ask_Bowl (R, 1, 10);
   begin
      Check (S.First >= B (1) and then S.First <= M,
             "Ask_Bowl మొదటి విలువ పరిధి");
      Check (S.Direction_Step = -1 or else S.Direction_Step = 1,
             "Ask_Bowl దిశ ±1");
      Check (Choose_Rank (S, N) = Expected_Wide (S, N),
             "నిజమైన Ask_Bowl విస్తృత ఎంపిక");
   end Check_Real_Ask_Bowl;

   Space : constant Big_Integer := M * M;
   N_Half : constant Big_Integer := Space / B (2) + B (1);
   --  Force three radix-M positions, not just the original two.
   Space_Three : constant Big_Integer := Space * M;
   N_Three : constant Big_Integer := Space_Three / B (2) + B (1);
   Plus_Stream_Three : constant Answer_Stream :=
     (First => M - B (3), Direction_Step => 1);
   Minus_Stream : constant Answer_Stream :=
     (First => M - B (1), Direction_Step => -1);
   Plus_Stream : constant Answer_Stream :=
     (First => M - B (1), Direction_Step => 1);
   W_Minus : constant Big_Integer := Space - B (2) * M - B (1);
   N_One_Step : constant Big_Integer := W_Minus - B (1);
   Zero_Rejection_Raised : Boolean := False;
begin
   --  Exhaustive miniature cyclic model: 2*(7^2+...+13^2) = 1456.
   --  This compares the O(1) endpoint proof to the original stepping.
   for Modulus in 7 .. 13 loop
      for Limit in 1 .. Modulus loop
         for Start in 1 .. Modulus loop
            for Direction in -1 .. 1 loop
               if Direction /= 0 then
                  declare
                     Historic : Integer := Start;
                     Steps    : Natural := 0;
                     Direct   : constant Integer :=
                       (if Start <= Limit then Start
                        elsif Direction = -1 then Limit else 1);
                  begin
                     while Historic > Limit loop
                        Historic :=
                          1 + ((Historic - 1 + Direction + Modulus) mod Modulus);
                        Steps := Steps + 1;
                        if Steps > Modulus then
                           raise Program_Error with "miniature model did not stop";
                        end if;
                     end loop;
                     Check (Historic = Direct, "చిన్న స్థల భేద పరీక్ష");
                  end;
               end if;
            end loop;
         end loop;
      end loop;
   end loop;

   --  Synthetic liveness witness: the old -1 loop would not finish.
   Check (Choose_Rank (Minus_Stream, N_Half) = N_Half,
          "అపారమైన తిరస్కరణ నేరుగా గమ్యం చేరింది");
   Check (Choose_Rank (Plus_Stream, N_Half) = B (1),
          "ధన దిశ తిరిగి మొదటికి చేరింది");

   --  Three-place wide rejection checks. Both initial candidates exceed
   --  floor (M**3 / N_Three) * N_Three, so these exercise the fix itself.
   Check (Choose_Rank (Minus_Stream, N_Three) = N_Three,
          "మూడు స్థానాల ఋణ దిశ");
   Check (Choose_Rank (Plus_Stream_Three, N_Three) = B (1),
          "మూడు స్థానాల ధన దిశ");

   --  Two genuine, safely bounded historical-loop differential cases.
   Check
     (Choose_Rank (Minus_Stream, N_One_Step) =
        Legacy_Bounded (Minus_Stream, N_One_Step, 2),
      "చరిత్రాత్మక ఒక్క అడుగు");
   Check
     (Choose_Rank (Plus_Stream, N_Half) =
        Legacy_Bounded (Plus_Stream, N_Half, 3),
      "చరిత్రాత్మక రెండు అడుగులు");

   Check
     (Choose_Rank ((First => B (1), Direction_Step => 1), M + B (1))
        = M + B (1),
      "విస్తృత సరిహద్దు");
   Check
     (Choose_Rank ((First => B (1), Direction_Step => 0), N_Half)
        = B (1),
      "స్థిర ప్రవాహం అంగీకరించినప్పుడు మార్పు లేదు");

   --  A rejected stationary stream historically never terminates. Fail fast.
   begin
      declare
         Ignored : constant Big_Integer :=
           Choose_Rank
             ((First => M - B (1), Direction_Step => 0), N_Half);
      begin
         if Ignored >= B (1) then
            null;
         end if;
      end;
   exception
      when Constraint_Error => Zero_Rejection_Raised := True;
   end;
   Check (Zero_Rejection_Raised, "స్థిర తిరస్కరణ స్పష్టమైన దోషం");

   --  Real Sauce/Ask_Bowl paths; these do not claim full calendar output.
   Check_Real_Ask_Bowl (Foundation_Day, Foundation_Day, N_Half);
   Check_Real_Ask_Bowl
     (Foundation_Day + B (1), Foundation_Day - B (1), N_Half);

   Ada.Wide_Wide_Text_IO.Put_Line
     ("STAGE03_PATCH01_ASSERTIONS=" & Natural'Wide_Wide_Image (Checks));
end Stage03_Patch01_Tests;
