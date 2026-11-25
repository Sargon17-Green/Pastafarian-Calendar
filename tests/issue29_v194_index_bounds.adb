with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

procedure Issue29_V194_Index_Bounds is
   package G renames GNATCOLL.GMP.Integers;
   package W renames Canonical_Full_Weave_GMP_V164;
   use type G.Big_Integer;
   use type W.Natural_Array;
   use Ada.Text_IO;
   Checks : Natural := 0;

   procedure Check (OK : Boolean; Label_Text : String) is
   begin
      if not OK then
         Put_Line ("V194_CHECK_FAILED " & Label_Text);
         raise Program_Error;
      end if;
      Checks := Checks + 1;
   end Check;

   procedure Compare_Bounds (Lengths : W.Natural_Array; First : Positive;
                             All_Ranks : Natural) is
      A, B : W.Family (Lengths'Length);
      Shifted : W.Natural_Array (First .. First + (Lengths'Length - 1)) := Lengths;
      CA, CB : G.Big_Integer;
   begin
      W.Build (A, Lengths);
      W.Count (A, CA);
      Put_Line ("V194_BEGIN_BOUND " & Positive'Image (Shifted'First) &
                " " & Positive'Image (Shifted'Last));
      begin
         W.Build (B, Shifted);
      exception
         when E : Constraint_Error =>
            Put_Line ("V194_BUILD_CONSTRAINT_ERROR " & Ada.Exceptions.Exception_Information (E));
            raise;
      end;
      W.Count (B, CB);
      Check (CA = CB, "same count");
      Check (W.Unrank (A, G.Make ("1")) = W.Unrank (B, G.Make ("1")), "first rank");
      Check (W.Unrank (A, CA) = W.Unrank (B, CB), "last rank");
      if All_Ranks > 0 then
         Check (CA = G.Make (Natural'Image (All_Ranks)), "independent small count");
         for I in 1 .. All_Ranks loop
            declare
               R : constant G.Big_Integer := G.Make (Natural'Image (I));
            begin
               Check (W.Unrank (A, R) = W.Unrank (B, R), "every rank");
            end;
         end loop;
      end if;
      Put_Line ("V194_BOUND_MATCH");
   end Compare_Bounds;
begin
   --  Runtime argument makes the extreme bound independent of constant folding.
   if Ada.Command_Line.Argument_Count /= 1 then
      raise Constraint_Error with "expected maximum index argument";
   end if;
   declare
      High : constant Positive := Positive'Value (Ada.Command_Line.Argument (1));
   begin
      Check (High = Positive'Last, "maximum index");
      Compare_Bounds ((4, 4), 17, 20);
      Compare_Bounds ((1 => 123), High, 1);
      Compare_Bounds ((4, 4), High - 1, 20);
      Compare_Bounds ((4, 5), High - 1, 35);
      Compare_Bounds ((4, 4, 4), High - 2, 1301);
      Compare_Bounds ((4, 4), High - 2, 20);
   end;
   Put_Line ("V194_ASSERTIONS=" & Natural'Image (Checks));
   Put_Line ("V194_ALL_BOUND_CONTROLS_PASS_ZERO_F");
end Issue29_V194_Index_Bounds;
