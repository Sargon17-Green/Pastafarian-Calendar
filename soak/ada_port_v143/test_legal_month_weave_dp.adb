with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Legal_Month_Weave_DP;

--  QA standalone GNAT test. All 35 expected sequences are hardcoded from
--  pinned v141 rank golden vectors, NOT recomputed by an original converter.
procedure Test_Legal_Month_Weave_DP is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Legal_Month_Weave_DP;

   Checked : Natural := 0;
   Zero : constant Big_Integer := To_Big_Integer (0);

   function B (N : Natural) return Big_Integer is
      (To_Big_Integer (Integer (N)));

   procedure Check (L : Month_Lengths; Expected_Count, R : Natural;
                    Expected : Month_Sequence) is
      Got_Count : constant Big_Integer := Count (L);
      Got_Sequence : constant Month_Sequence := Unrank (L, B (R));
      Got_Rank : constant Big_Integer := Rank (L, Expected);
   begin
      if Got_Count /= B (Expected_Count) or else Got_Sequence /= Expected
        or else Got_Rank /= B (R) then
         Ada.Text_IO.Put_Line ("V143_ADA_GOLDEN_MISMATCH case=" & Natural'Image (Checked + 1));
         raise Program_Error with "isolated month weave does not match v141 golden";
      end if;
      Checked := Checked + 1;
   end Check;

   procedure Check_Rejections is
      Rejected : Boolean := False;
   begin
      --  Zero is not a legal one-based global rank.
      begin
         declare
            Bad : constant Month_Sequence :=
              Unrank (Month_Lengths'(1 => 4, 2 => 4), Zero);
         begin
            if Bad'Length > 0 then
               null;
            end if;
         end;
      exception
         when Constraint_Error => Rejected := True;
      end;
      if not Rejected then
         raise Program_Error with "zero global rank was accepted";
      end if;
      Rejected := False;

      --  This sequence starts with month 2 before month 1.
      begin
         declare
            Bad : constant Big_Integer :=
              Rank (Month_Lengths'(1 => 4, 2 => 4),
                    Month_Sequence'(1 => 2, 2 => 2, 3 => 2, 4 => 2,
                                    5 => 1, 6 => 1, 7 => 1, 8 => 1));
         begin
            if Bad > Zero then
               null;
            end if;
         end;
      exception
         when Constraint_Error => Rejected := True;
      end;
      if not Rejected then
         raise Program_Error with "illegal month weave was accepted";
      end if;
      Rejected := False;

      --  QA resource bound is 30 synthetic occurrences; this has 36.
      begin
         declare
            Bad : constant Big_Integer :=
              Count (Month_Lengths'(1 => 6, 2 => 6, 3 => 6,
                                    4 => 6, 5 => 6, 6 => 6));
         begin
            if Bad > Zero then
               null;
            end if;
         end;
      exception
         when Constraint_Error => Rejected := True;
      end;
      if not Rejected then
         raise Program_Error with "realistic-size synthetic guard missing";
      end if;
   end Check_Rejections;

begin
   Check (Month_Lengths'(1 => 4, 2 => 4), 20, 1,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 2, 6 => 2, 7 => 2, 8 => 2));
   Check (Month_Lengths'(1 => 4, 2 => 4), 20, 2,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 1, 4 => 2, 5 => 1, 6 => 2, 7 => 2, 8 => 2));
   Check (Month_Lengths'(1 => 4, 2 => 4), 20, 10,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 2, 4 => 2, 5 => 2, 6 => 1, 7 => 1, 8 => 2));
   Check (Month_Lengths'(1 => 4, 2 => 4), 20, 11,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 1, 4 => 1, 5 => 1, 6 => 2, 7 => 2, 8 => 2));
   Check (Month_Lengths'(1 => 4, 2 => 4), 20, 19,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 2, 4 => 1, 5 => 2, 6 => 1, 7 => 1, 8 => 2));
   Check (Month_Lengths'(1 => 4, 2 => 4), 20, 20,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 2, 4 => 2, 5 => 1, 6 => 1, 7 => 1, 8 => 2));
   Check (Month_Lengths'(1 => 4, 2 => 5), 35, 1,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 2, 6 => 2, 7 => 2, 8 => 2, 9 => 2));
   Check (Month_Lengths'(1 => 4, 2 => 5), 35, 2,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 1, 4 => 2, 5 => 1, 6 => 2, 7 => 2, 8 => 2, 9 => 2));
   Check (Month_Lengths'(1 => 4, 2 => 5), 35, 17,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 1, 4 => 1, 5 => 2, 6 => 1, 7 => 2, 8 => 2, 9 => 2));
   Check (Month_Lengths'(1 => 4, 2 => 5), 35, 18,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 1, 4 => 1, 5 => 2, 6 => 2, 7 => 1, 8 => 2, 9 => 2));
   Check (Month_Lengths'(1 => 4, 2 => 5), 35, 34,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 2, 4 => 2, 5 => 1, 6 => 2, 7 => 1, 8 => 1, 9 => 2));
   Check (Month_Lengths'(1 => 4, 2 => 5), 35, 35,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 2, 4 => 2, 5 => 2, 6 => 1, 7 => 1, 8 => 1, 9 => 2));
   Check (Month_Lengths'(1 => 4, 2 => 4, 3 => 4), 1301, 1,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 2, 6 => 2, 7 => 2, 8 => 2, 9 => 3, 10 => 3, 11 => 3, 12 => 3));
   Check (Month_Lengths'(1 => 4, 2 => 4, 3 => 4), 1301, 2,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 2, 6 => 2, 7 => 2, 8 => 3, 9 => 2, 10 => 3, 11 => 3, 12 => 3));
   Check (Month_Lengths'(1 => 4, 2 => 4, 3 => 4), 1301, 650,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 1, 4 => 2, 5 => 3, 6 => 2, 7 => 1, 8 => 3, 9 => 1, 10 => 2, 11 => 3, 12 => 3));
   Check (Month_Lengths'(1 => 4, 2 => 4, 3 => 4), 1301, 651,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 1, 4 => 2, 5 => 3, 6 => 2, 7 => 1, 8 => 3, 9 => 1, 10 => 3, 11 => 2, 12 => 3));
   Check (Month_Lengths'(1 => 4, 2 => 4, 3 => 4), 1301, 1300,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 3, 4 => 3, 5 => 3, 6 => 2, 7 => 1, 8 => 2, 9 => 1, 10 => 1, 11 => 2, 12 => 3));
   Check (Month_Lengths'(1 => 4, 2 => 4, 3 => 4), 1301, 1301,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 3, 4 => 3, 5 => 3, 6 => 2, 7 => 2, 8 => 1, 9 => 1, 10 => 1, 11 => 2, 12 => 3));
   Check (Month_Lengths'(1 => 4, 2 => 5, 3 => 4), 3499, 1,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 2, 6 => 2, 7 => 2, 8 => 2, 9 => 2, 10 => 3, 11 => 3, 12 => 3, 13 => 3));
   Check (Month_Lengths'(1 => 4, 2 => 5, 3 => 4), 3499, 2,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 2, 6 => 2, 7 => 2, 8 => 2, 9 => 3, 10 => 2, 11 => 3, 12 => 3, 13 => 3));
   Check (Month_Lengths'(1 => 4, 2 => 5, 3 => 4), 3499, 1749,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 1, 4 => 3, 5 => 2, 6 => 1, 7 => 1, 8 => 2, 9 => 3, 10 => 3, 11 => 2, 12 => 2, 13 => 3));
   Check (Month_Lengths'(1 => 4, 2 => 5, 3 => 4), 3499, 1750,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 1, 4 => 3, 5 => 2, 6 => 1, 7 => 1, 8 => 3, 9 => 2, 10 => 2, 11 => 2, 12 => 3, 13 => 3));
   Check (Month_Lengths'(1 => 4, 2 => 5, 3 => 4), 3499, 3498,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 3, 4 => 3, 5 => 3, 6 => 2, 7 => 2, 8 => 1, 9 => 2, 10 => 1, 11 => 1, 12 => 2, 13 => 3));
   Check (Month_Lengths'(1 => 4, 2 => 5, 3 => 4), 3499, 3499,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 3, 4 => 3, 5 => 3, 6 => 2, 7 => 2, 8 => 2, 9 => 1, 10 => 1, 11 => 1, 12 => 2, 13 => 3));
   Check (Month_Lengths'(1 => 4, 2 => 4, 3 => 4, 4 => 4), 177260, 1,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 2, 6 => 2, 7 => 2, 8 => 2, 9 => 3, 10 => 3, 11 => 3, 12 => 3, 13 => 4, 14 => 4, 15 => 4, 16 => 4));
   Check (Month_Lengths'(1 => 4, 2 => 4, 3 => 4, 4 => 4), 177260, 2,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 2, 6 => 2, 7 => 2, 8 => 2, 9 => 3, 10 => 3, 11 => 3, 12 => 4, 13 => 3, 14 => 4, 15 => 4, 16 => 4));
   Check (Month_Lengths'(1 => 4, 2 => 4, 3 => 4, 4 => 4), 177260, 88630,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 1, 4 => 3, 5 => 4, 6 => 4, 7 => 2, 8 => 1, 9 => 1, 10 => 2, 11 => 3, 12 => 3, 13 => 2, 14 => 3, 15 => 4, 16 => 4));
   Check (Month_Lengths'(1 => 4, 2 => 4, 3 => 4, 4 => 4), 177260, 88631,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 1, 4 => 3, 5 => 4, 6 => 4, 7 => 2, 8 => 1, 9 => 1, 10 => 2, 11 => 3, 12 => 3, 13 => 2, 14 => 4, 15 => 3, 16 => 4));
   Check (Month_Lengths'(1 => 4, 2 => 4, 3 => 4, 4 => 4), 177260, 177259,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 4, 6 => 4, 7 => 3, 8 => 3, 9 => 2, 10 => 1, 11 => 2, 12 => 1, 13 => 1, 14 => 2, 15 => 3, 16 => 4));
   Check (Month_Lengths'(1 => 4, 2 => 4, 3 => 4, 4 => 4), 177260, 177260,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 4, 6 => 4, 7 => 3, 8 => 3, 9 => 2, 10 => 2, 11 => 1, 12 => 1, 13 => 1, 14 => 2, 15 => 3, 16 => 4));
   Check (Month_Lengths'(1 => 2, 2 => 2, 3 => 2), 5, 1,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 2, 4 => 2, 5 => 3, 6 => 3));
   Check (Month_Lengths'(1 => 2, 2 => 2, 3 => 2), 5, 2,
          Month_Sequence'(1 => 1, 2 => 1, 3 => 2, 4 => 3, 5 => 2, 6 => 3));
   Check (Month_Lengths'(1 => 2, 2 => 2, 3 => 2), 5, 3,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 1, 4 => 2, 5 => 3, 6 => 3));
   Check (Month_Lengths'(1 => 2, 2 => 2, 3 => 2), 5, 4,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 1, 4 => 3, 5 => 2, 6 => 3));
   Check (Month_Lengths'(1 => 2, 2 => 2, 3 => 2), 5, 5,
          Month_Sequence'(1 => 1, 2 => 2, 3 => 3, 4 => 1, 5 => 2, 6 => 3));
   if Checked /= 35 then
      raise Program_Error with "wrong number of fixed v141 golden vectors";
   end if;
   Check_Rejections;
   Ada.Text_IO.Put_Line ("V143_ADA_ISOLATED_GOLDEN_VECTORS=" & Natural'Image (Checked));
   Ada.Text_IO.Put_Line ("V143_ORIGINAL_CALENDAR_FCT_CALLS=0");
   Ada.Text_IO.Put_Line ("V143_PRODUCTION_ADA_PATCH_APPLIED=FALSE");
end Test_Legal_Month_Weave_DP;
