with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Wide_Wide_Text_IO;
with Exact_Math;
with Normative_Oracle;

procedure Stage02_Discovery01_Tests is
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

   --  This probe never calls Choose_Rank on a hostile wide candidate.
   --  It computes the exact iteration count of its documented loop.
   Stream : constant Answer_Stream :=
     (First => M - B (1), Direction_Step => -1);
   Space  : constant Big_Integer := M * M;
   N      : constant Big_Integer := Space / B (2) + B (1);
   Wide   : constant Big_Integer :=
     B (1) + (Answer_At (Stream, B (0)) - B (1))
     + (Answer_At (Stream, B (1)) - B (1)) * M;
   Limit  : constant Big_Integer := Floor_Div (Space, N) * N;
   Steps  : constant Big_Integer := Wide - Limit;
begin
   Check (Answer_At (Stream, B (0)) = M - B (1),
          "మొదటి సమాధానం");
   Check (Answer_At (Stream, B (1)) = M - B (2),
          "రెండవ సమాధానం");
   Check (N > M, "విస్తృత ఎంపిక మార్గం");
   Check (B (2) * N > Space, "అంగీకరణ పరిమితి శాఖ");
   Check (Limit = N, "ఖచ్చిత అంగీకరణ పరిమితి");
   Check (Wide = Space - B (2) * M - B (1),
          "విస్తృత సంఖ్య పునర్నిర్మాణం");
   Check (Wide > Limit, "తిరస్కరణకు గురయ్యే మొదటి సంఖ్య");
   Check (Steps > B (10) ** 60,
          "నేరుగా లెక్కించే లూప్ అమితమైన పని చేస్తుంది");

   Ada.Wide_Wide_Text_IO.Put_Line
     ("Stage 2 DISCOVERY01: 8 పరిమిత పరీక్షలు విజయవంతమయ్యాయి");
end Stage02_Discovery01_Tests;
