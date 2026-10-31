with Ada.Strings.UTF_Encoding.Wide_Wide_Strings;
with Exact_Math;

package body Month_Weaving is
   use Exact_Math;

   function B (N : Natural) return Big_Integer is
     (To_Big_Integer (Integer (N)));

   procedure Validate_Lengths (Lengths : Natural_Array) is
   begin
      if Lengths'Length = 0 or else Lengths'First /= 1 then
         raise Constraint_Error with Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode ("నెలల పొడవులు ఖాళీ కాని 1-ఆధారిత శ్రేణి కావాలి");
      end if;

      for J in Lengths'Range loop
         if Lengths (J) < 2 then
            raise Constraint_Error with Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode ("ప్రతి నెలకు ప్రారంభ మరియు ముగింపు రోజు అవసరం");
         end if;
      end loop;
   end Validate_Lengths;

   function Canonical_Weave_Count (Lengths : Natural_Array) return Big_Integer is
      Total : Natural := 0;
      Denominator : Big_Integer := B (1);
      Month_Count : constant Natural := Lengths'Length;
   begin
      Validate_Lengths (Lengths);

      for J in Lengths'Range loop
         Total := Total + Lengths (J);
         Denominator := Denominator * Factorial (Lengths (J) - 2);
      end loop;

      -- The opening and closing rails consume two positions per month.
      -- The remaining multiset has (Total - 2 * Month_Count) positions.
      return Factorial (Total - 2 * Month_Count) / Denominator;
   end Canonical_Weave_Count;

   function Unrank_Canonical_Weave
     (Lengths : Natural_Array; Rank : Big_Integer) return Natural_Array
   is
      Month_Count : constant Natural := Lengths'Length;
      Total : Natural := 0;
      Interior_Total : Natural;
      Remaining : Natural_Array (Lengths'Range);
      Ways : Big_Integer;
      Ways_Left : Big_Integer;
      R : Big_Integer := Rank;
      Slots : Natural;
      Position : Positive := 1;
   begin
      Validate_Lengths (Lengths);

      for J in Lengths'Range loop
         Total := Total + Lengths (J);
      end loop;

      Interior_Total := Total - 2 * Month_Count;
      Slots := Interior_Total;
      Ways := Canonical_Weave_Count (Lengths);
      if Rank < B (1) or else Rank > Ways then
         raise Constraint_Error with Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode ("ర్యాంకు కానానికల్ వీవ్ కుటుంబం వెలుపల ఉంది");
      end if;
      Ways_Left := Ways;

      declare
         Output : Natural_Array (1 .. Total);
      begin
         -- Fixed opening rail: first occurrence of each month.
         for J in 1 .. Month_Count loop
            Output (Position) := J;
            Position := Position + 1;
            Remaining (J) := Lengths (J) - 2;
         end loop;

         -- Lexicographically unrank the multiset permutation of interior
         -- occurrences. If c_j copies remain among r slots, exactly
         -- Ways_Left * c_j / r completions begin with month j.
         while Slots > 0 loop
            declare
               Chosen : Boolean := False;
            begin
               for J in 1 .. Month_Count loop
                  if Remaining (J) > 0 then
                     declare
                        Block : constant Big_Integer :=
                          (Ways_Left * B (Remaining (J))) / B (Slots);
                     begin
                        if R > Block then
                           R := R - Block;
                        else
                           Output (Position) := J;
                           Position := Position + 1;
                           Remaining (J) := Remaining (J) - 1;
                           Ways_Left := Block;
                           Slots := Slots - 1;
                           Chosen := True;
                           exit;
                        end if;
                     end;
                  end if;
               end loop;

               if not Chosen then
                  raise Program_Error with Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode ("కానానికల్ వీవ్ అన్‌రాంకింగ్‌లో బ్లాకులు ముగిశాయి");
               end if;
            end;
         end loop;

         if R /= B (1) or else Ways_Left /= B (1) then
            raise Program_Error with Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode ("కానానికల్ వీవ్ ర్యాంకు పూర్తిగా వినియోగించబడలేదు");
         end if;

         -- Fixed closing rail: last occurrence of each month.
         for J in 1 .. Month_Count loop
            Output (Position) := J;
            Position := Position + 1;
         end loop;

         if Position /= Total + 1 then
            raise Program_Error with Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode ("కానానికల్ వీవ్ అవుట్‌పుట్ పొడవు సరిపోలలేదు");
         end if;
         return Output;
      end;
   end Unrank_Canonical_Weave;
end Month_Weaving;
