with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Wide_Wide_Text_IO;
with Exact_Math;
with Normative_Oracle;

procedure Stage04_Discovery02_Tests is
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

   -- Independent bounded representation of the historical short-route
   -- per-answer walk. Never call Choose_Rank on the hostile witness.
   function Legacy_Short_Bounded
     (Stream : Answer_Stream; N : Big_Integer; Max_Probes : Positive)
      return Boolean
   is
      Limit : constant Big_Integer := Floor_Div (M, N) * N;
   begin
      for K in 0 .. Max_Probes - 1 loop
         if Answer_At (Stream, B (K)) <= Limit then
            return True;
         end if;
      end loop;
      return False;
   end Legacy_Short_Bounded;

   N     : constant Big_Integer := Floor_Div (M, B (2)) + B (1);
   Limit : constant Big_Integer := Floor_Div (M, N) * N;
   Minus_Stream : constant Answer_Stream :=
     (First => M - B (1), Direction_Step => -1);
   Plus_Stream : constant Answer_Stream :=
     (First => M - B (1), Direction_Step => 1);
   Stationary_Stream : constant Answer_Stream :=
     (First => M - B (1), Direction_Step => 0);
   Accepted_Stream : constant Answer_Stream :=
     (First => N, Direction_Step => -1);
   Start : constant Big_Integer := Answer_At (Minus_Stream, B (0));
   Steps : constant Big_Integer := Start - Limit;
begin
   Check (N > B (1), "చిన్న ఎంపిక కనీస పరిధి");
   Check (N < M, "చిన్న ఎంపిక గరిష్ఠ పరిధి");
   Check (B (2) * N = M + B (1), "అర్ధ పరిమితి");
   Check (Floor_Div (M, N) = B (1), "అంగీకరణ భాగఫలం");
   Check (Limit = N, "అంగీకరణ సరిహద్దు");
   Check (Start = M - B (1), "ప్రథమ అభ్యర్థి");
   Check (Start > Limit, "ప్రథమ తిరస్కరణ");
   Check (Steps = M - B (1) - N, "ఖచ్చిత పాత అడుగులు");
   Check (Steps > B (10) ** 30, "అపారమైన పని");
   Check (Answer_At (Minus_Stream, B (64)) = Start - B (64),
          "చిన్న ప్రతికూల ముందడుగు");
   Check (not Legacy_Short_Bounded (Minus_Stream, N, 64),
          "అసలు నడకకు 64 పరిశీలనలు సరిపోవు");
   Check (not Legacy_Short_Bounded (Stationary_Stream, N, 64),
          "స్థిర తిరస్కరణకు 64 పరిశీలనలు సరిపోవు");
   Check (Legacy_Short_Bounded (Plus_Stream, N, 3),
          "ధన దిశలో త్వరిత అంగీకారం");
   Check (Answer_At (Plus_Stream, B (2)) = B (1),
          "ధన దిశ చుట్టుముట్టడం");
   Check (Choose_Rank (Plus_Stream, N) = B (1),
          "నిజమైన చిన్న ఎంపిక ధన దిశ");
   Check (Legacy_Short_Bounded (Accepted_Stream, N, 1),
          "ముందుగా అంగీకరించిన నమూనా");
   Check (Choose_Rank (Accepted_Stream, N) = N,
          "నిజమైన చిన్న ఎంపిక మొదటి అంగీకారం");
   Check (Regular_Mod (Limit - B (1), N) + B (1) = N,
          "ప్రతికూల దిశ నేరుగా అంచనా");

   Ada.Wide_Wide_Text_IO.Put_Line
     ("STAGE04_DISCOVERY02_ASSERTIONS=" & Natural'Wide_Wide_Image (Checks));
end Stage04_Discovery02_Tests;
