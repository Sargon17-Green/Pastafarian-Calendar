with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Legal_Month_Weave_DP;

--  v144 QA isolated *synthetic* Ada wide-rank contract. No original F(c,t).
--  3 exact family-count constants + 12 whole-sequence rolling hashes were
--  derived from pinned mathematical reference and are checked in CI.
procedure Test_Legal_Month_Weave_Wide_V144 is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Legal_Month_Weave_DP;

   One  : constant Big_Integer := To_Big_Integer (1);
   Zero : constant Big_Integer := To_Big_Integer (0);
   Two  : constant Big_Integer := To_Big_Integer (2);
   P    : constant Big_Integer := From_String ("2305843009213693951");
   Step : constant Big_Integer := To_Big_Integer (257);

   type Rank_Array is array (Positive range 1 .. 4) of Big_Integer;

   Wide_Golden_Count : Natural := 0;
   Passed_Families   : Natural := 0;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         raise Program_Error with Message;
      end if;
   end Require;

   function Hash_Sequence (Sequence : Month_Sequence) return Big_Integer is
      State : Big_Integer := Zero;
   begin
      for J in Sequence'Range loop
         State := (State * Step
                   + To_Big_Integer (Integer (Sequence (J)))) mod P;
      end loop;
      return State;
   end Hash_Sequence;

   procedure Check_Family
     (M, Days_Per_Month, Expected_Bits : Positive;
      Expected_Count, H_First, H_Wide, H_Middle, H_Last : String)
   is
      L : constant Month_Lengths (1 .. M) := (others => Days_Per_Month);
      N : constant Big_Integer := Count (L);
      R : constant Rank_Array :=
        (1 => One,
         2 => (Two ** 127) + One,
         3 => (N + One) / Two,
         4 => N);
      Expected_Hashes : constant Rank_Array :=
        (From_String (H_First), From_String (H_Wide),
         From_String (H_Middle), From_String (H_Last));
   begin
      Require (N = From_String (Expected_Count),
               "v144 exact full-family count mismatch");
      Require (N >= Two ** Natural (Expected_Bits - 1)
               and then N < Two ** Natural (Expected_Bits),
               "v144 arbitrary-precision family count bit width mismatch");
      Require (R (2) > Two ** 127 and then R (2) < N,
               "v144 wide global rank was not genuinely >127-bit");
      for I in R'Range loop
         declare
            S : constant Month_Sequence := Unrank (L, R (I));
         begin
            Require (S'Length = M * Days_Per_Month,
                     "v144 sequence length mismatch");
            Require (Hash_Sequence (S) = Expected_Hashes (I),
                     "v144 source-derived whole-sequence golden hash mismatch");
            Require (Rank (L, S) = R (I),
                     "v144 global rank/unrank inverse mismatch");
         end;
         Wide_Golden_Count := Wide_Golden_Count + 1;
      end loop;
      Passed_Families := Passed_Families + 1;
   end Check_Family;

   procedure Check_Rejections is
      Rejected : Boolean := False;
   begin
      --  More than the QA-only 256 total-day cap.
      begin
         declare
            Bad : constant Big_Integer :=
              Count (Month_Lengths'(1 => 33, 2 => 33, 3 => 33,
                                    4 => 33, 5 => 33, 6 => 33,
                                    7 => 33, 8 => 33));
         begin
            if Bad > Zero then null; end if;
         end;
      exception
         when Constraint_Error => Rejected := True;
      end;
      Require (Rejected, "v144 256-day QA synthetic limit bypassed");
      Rejected := False;

      --  More than the QA-only 12-month cap.
      begin
         declare
            Bad : constant Big_Integer :=
              Count (Month_Lengths'(1 => 4, 2 => 4, 3 => 4, 4 => 4,
                  5 => 4, 6 => 4, 7 => 4, 8 => 4, 9 => 4, 10 => 4,
                  11 => 4, 12 => 4, 13 => 4));
         begin
            if Bad > Zero then null; end if;
         end;
      exception
         when Constraint_Error => Rejected := True;
      end;
      Require (Rejected, "v144 12-month QA synthetic limit bypassed");
      Rejected := False;

      --  One-based rank cannot exceed exact family count.
      begin
         declare
            L : constant Month_Lengths (1 .. 8) := (others => 16);
            Bad : constant Month_Sequence := Unrank (L, Count (L) + One);
         begin
            if Bad'Length > 0 then null; end if;
         end;
      exception
         when Constraint_Error => Rejected := True;
      end;
      Require (Rejected, "v144 out-of-family rank accepted");
   end Check_Rejections;

begin
   Check_Family
     (M => 8,
      Days_Per_Month => 16,
      Expected_Bits => 332,
      Expected_Count => "8484570857678108456252429355893789531769120343894823957866334278987787485159718203651318043348194800",
      H_First => "716973684692580079",
      H_Wide => "1776394615692406099",
      H_Middle => "203723759202362302",
      H_Last => "853333561835942501");
   Check_Family
     (M => 8,
      Days_Per_Month => 32,
      Expected_Bits => 713,
      Expected_Count => "26254089435165697729528393257871603255707257609737749025501387135406164344323199990591639256125823042318635882820638131218736213447130931322662579357911091228956700002794085172789952584178523338265523391407270930400",
      H_First => "1675301637606544654",
      H_Wide => "721533734026488729",
      H_Middle => "1752890047684416739",
      H_Last => "1656766864843718784");
   Check_Family
     (M => 12,
      Days_Per_Month => 12,
      Expected_Bits => 427,
      Expected_Count => "300023061462656623377368054467125768149585357472311800429674901748375323502606423930061133993742830823476708866723045193185973392",
      H_First => "940787654782621958",
      H_Wide => "1827887923208027127",
      H_Middle => "1406895117283389262",
      H_Last => "1962590964466250543");
   Require (Passed_Families = 3 and then Wide_Golden_Count = 12,
            "v144 wide synthetic family/golden coverage incomplete");
   Check_Rejections;
   Ada.Text_IO.Put_Line ("V144_STANDALONE_WIDE_FAMILIES=3");
   Ada.Text_IO.Put_Line ("V144_ADA_WIDE_GLOBAL_RANK_GOLDENS=12");
   Ada.Text_IO.Put_Line ("V144_ADA_EXACT_FAMILY_COUNT_BITS=332,713,427");
   Ada.Text_IO.Put_Line ("V144_ORIGINAL_CALENDAR_FCT_CALLS=0");
   Ada.Text_IO.Put_Line ("V144_PRODUCTION_ADA_PATCH_APPLIED=FALSE");
end Test_Legal_Month_Weave_Wide_V144;
