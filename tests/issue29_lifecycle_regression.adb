with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;
with Issue29_Lifecycle_Probe;

procedure Issue29_Lifecycle_Regression is
   package G renames GNATCOLL.GMP.Integers;
   package W renames Canonical_Full_Weave_GMP_V164;
   package P renames Issue29_Lifecycle_Probe;
   use Ada.Text_IO;
   use type G.Big_Integer;

   Assertion_Failure : exception;
   Checks : Natural := 0;

   procedure Check (Condition : Boolean; Label_Text : String) is
   begin
      if not Condition then
         Put_Line ("LIFECYCLE_CHECK_FAILED " & Label_Text);
         raise Assertion_Failure with Label_Text;
      end if;
      Checks := Checks + 1;
   end Check;

   procedure Check_Unbuilt
     (F : W.Family; Label_Text : String) is
      C : G.Big_Integer;
      Raised : Boolean := False;
   begin
      begin
         W.Count (F, C);
         Check (False, Label_Text & ": Count returned before Build");
      exception
         when Program_Error =>
            Raised := True;
      end;
      Check (Raised, Label_Text & ": Count must raise Program_Error");

      Raised := False;
      begin
         declare
            R : constant G.Big_Integer := G.Make ("1");
            Actual : constant W.Natural_Array := W.Unrank (F, R);
         begin
            Check
              (Actual'Length = Natural'Last,
               Label_Text & ": Unrank unexpectedly returned");
         end;
      exception
         when Program_Error =>
            Raised := True;
      end;
      Check (Raised, Label_Text & ": Unrank must raise Program_Error");
   end Check_Unbuilt;

   procedure Check_Word
     (F : W.Family; Rank : Natural; Expected : String;
      Label_Text : String) is
      Actual : constant W.Natural_Array :=
        W.Unrank (F, G.Make (Natural'Image (Rank)));
      Expected_Value : Natural;
   begin
      Check
        (Actual'Length = Expected'Length,
         Label_Text & ": word length at rank" & Natural'Image (Rank));
      for Offset in 1 .. Expected'Length loop
         Expected_Value :=
           Natural
             (Character'Pos (Expected (Expected'First + Offset - 1)) -
              Character'Pos ('0'));
         Check
           (Actual (Actual'First + Offset - 1) = Expected_Value,
            Label_Text & ": word value at rank" & Natural'Image (Rank) &
              " position" & Natural'Image (Offset));
      end loop;
   end Check_Word;

   procedure Check_Fixture
     (Lengths : W.Natural_Array; Encoded_Words : String;
      Label_Text : String) is
      Rank : Natural := 0;
      Start_At : Integer := Encoded_Words'First;
      C : G.Big_Integer;
   begin
      P.Reset (P.No_Injection);
      declare
         F : W.Family (Lengths'Length);
      begin
         W.Build (F, Lengths);
         W.Count (F, C);

         for Position in Encoded_Words'Range loop
            if Encoded_Words (Position) = ';' then
               Rank := Rank + 1;
               Check_Word
                 (F, Rank, Encoded_Words (Start_At .. Position - 1),
                  Label_Text);
               Start_At := Position + 1;
            end if;
         end loop;

         if Start_At <= Encoded_Words'Last then
            Rank := Rank + 1;
            Check_Word
              (F, Rank, Encoded_Words (Start_At .. Encoded_Words'Last),
               Label_Text);
         end if;

         Check
           (C = G.Make (Natural'Image (Rank)),
            Label_Text & ": exact Count");
      end;
      Check
        (P.Allocation_Count = Lengths'Length + 1,
         Label_Text & ": successful allocation count");
      Check
        (P.Free_Count = Lengths'Length + 1,
         Label_Text & ": every successful allocation freed once");
   end Check_Fixture;

   procedure Expect_Constraint_Error
     (F : in out W.Family; Bad_Lengths : W.Natural_Array;
      Label_Text : String) is
      Raised : Boolean := False;
   begin
      begin
         W.Build (F, Bad_Lengths);
      exception
         when Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, Label_Text & ": Build must raise Constraint_Error");
   end Expect_Constraint_Error;

   procedure Check_47_Month_First_Word (F : W.Family) is
      Actual : constant W.Natural_Array :=
        W.Unrank (F, G.Make ("1"));
   begin
      Check (Actual'Length = 94, "47x2 lex-first word length");
      for Month in 1 .. 47 loop
         Check
           (Actual (2 * Month - 1) = Month and then
            Actual (2 * Month) = Month,
            "47x2 lex-first word month" & Natural'Image (Month));
      end loop;
   end Check_47_Month_First_Word;

   procedure Test_Preallocation_Retry
     (Label_Text : String; Month_Count : Positive;
      Bad_Lengths : W.Natural_Array; Good_Lengths : W.Natural_Array) is
      C : G.Big_Integer;
   begin
      P.Reset (P.No_Injection);
      declare
         F : W.Family (Month_Count);
      begin
         Expect_Constraint_Error (F, Bad_Lengths, Label_Text);
         Check
           (P.Allocation_Count = 0,
            Label_Text & ": rejection must precede all allocations");

         W.Build (F, Good_Lengths);
         W.Count (F, C);
         Check (C > G.Make ("0"), Label_Text & ": retry Count positive");

         if Month_Count = 2 then
            Check (C = G.Make ("2"), Label_Text & ": retry exact Count");
            Check_Word (F, 1, "1122", Label_Text & ": retry rank 1");
            Check_Word (F, 2, "1212", Label_Text & ": retry rank 2");
         elsif Month_Count = 47 then
            Check_47_Month_First_Word (F);
         else
            Check (False, Label_Text & ": unsupported retry fixture size");
         end if;
      end;
      Check
        (P.Allocation_Count = Month_Count + 1,
         Label_Text & ": retry allocations");
      Check
        (P.Free_Count = Month_Count + 1,
         Label_Text & ": retry finalization balance");
   end Test_Preallocation_Retry;

   procedure Test_Fresh_Unbuilt is
   begin
      P.Reset (P.No_Injection);
      declare
         F : W.Family (2);
      begin
         Check_Unbuilt (F, "fresh Family");
      end;
      Check (P.Allocation_Count = 0, "fresh Family allocates nothing");
      Check (P.Free_Count = 0, "fresh Family frees nothing");
   end Test_Fresh_Unbuilt;

   procedure Test_Double_Build is
      C : G.Big_Integer;
      Raised : Boolean := False;
   begin
      P.Reset (P.No_Injection);
      declare
         F : W.Family (2);
      begin
         W.Build (F, (1 => 2, 2 => 2));
         W.Count (F, C);
         Check (C = G.Make ("2"), "double-build initial Count");
         Check_Word (F, 1, "1122", "double-build initial rank 1");
         Check_Word (F, 2, "1212", "double-build initial rank 2");

         begin
            W.Build (F, (1 => 3, 2 => 2));
         exception
            when Program_Error =>
               Raised := True;
         end;
         Check (Raised, "second Build must raise Program_Error");

         W.Count (F, C);
         Check (C = G.Make ("2"), "Count unchanged after rejected second Build");
         Check_Word (F, 1, "1122", "stable rank 1 after rejected second Build");
         Check_Word (F, 2, "1212", "stable rank 2 after rejected second Build");
      end;
      Check (P.Allocation_Count = 3, "double-build allocation count");
      Check (P.Free_Count = 3, "double-build finalization balance");
   end Test_Double_Build;

   procedure Test_Partial_Allocation_Failure
     (Mode : P.Injection_Mode; Expected_Allocations : Natural;
      Label_Text : String) is
      Raised : Boolean := False;
   begin
      P.Reset (Mode);
      declare
         F : W.Family (2);
      begin
         begin
            W.Build (F, (1 => 2, 2 => 2));
         exception
            when P.Injected_Failure =>
               Raised := True;
         end;
         Check (Raised, Label_Text & ": injection was observed");
         Check
           (P.Allocation_Count = Expected_Allocations,
            Label_Text & ": exact partial allocation count");

         Check_Unbuilt (F, Label_Text & ": partial Family");

         Raised := False;
         begin
            W.Build (F, (1 => 2, 2 => 2));
         exception
            when Program_Error =>
               Raised := True;
         end;
         Check
           (Raised,
            Label_Text & ": retry after allocation must raise Program_Error");
      end;
      Check
        (P.Allocation_Count = Expected_Allocations,
         Label_Text & ": allocations unchanged through finalization");
      Check
        (P.Free_Count = Expected_Allocations,
         Label_Text & ": every partial allocation freed exactly once");
   end Test_Partial_Allocation_Failure;

   procedure Test_Before_Terminal_Retry is
      Raised : Boolean := False;
      C : G.Big_Integer;
   begin
      P.Reset (P.Raise_Before_Terminal);
      declare
         F : W.Family (2);
      begin
         begin
            W.Build (F, (1 => 2, 2 => 2));
         exception
            when P.Injected_Failure =>
               Raised := True;
         end;
         Check (Raised, "pre-terminal injection was observed");
         Check (P.Allocation_Count = 0, "pre-terminal injection allocates nothing");
         Check_Unbuilt (F, "pre-terminal injected Family");

         P.Set_Mode (P.No_Injection);
         W.Build (F, (1 => 2, 2 => 2));
         W.Count (F, C);
         Check (C = G.Make ("2"), "pre-terminal retry exact Count");
         Check_Word (F, 1, "1122", "pre-terminal retry rank 1");
         Check_Word (F, 2, "1212", "pre-terminal retry rank 2");
      end;
      Check (P.Allocation_Count = 3, "pre-terminal retry allocations");
      Check (P.Free_Count = 3, "pre-terminal retry finalization balance");
   end Test_Before_Terminal_Retry;

   Wrong_Length : constant W.Natural_Array := (1 => 2);
   Late_Invalid : constant W.Natural_Array := (1 => 2, 2 => 124);
   Null_Lengths : constant W.Natural_Array (2 .. 1) := (others => 0);
   Too_Long : constant W.Natural_Array (1 .. 47) := (others => 123);
   Valid_Two : constant W.Natural_Array (1 .. 2) := (others => 2);
   Valid_47 : constant W.Natural_Array (1 .. 47) := (others => 2);
begin
   Test_Fresh_Unbuilt;

   Check_Fixture ((1 => 2), "11", "one month");
   Check_Fixture ((1 => 2, 2 => 2), "1122;1212", "two months 2x2");
   Check_Fixture ((1 => 2, 2 => 3), "11222;12122;12212", "two months 2x3");
   Check_Fixture ((1 => 3, 2 => 2), "11122;11212;12112", "two months 3x2");
   Check_Fixture
     ((1 => 3, 2 => 3),
      "111222;112122;112212;121122;121212;122112",
      "two months 3x3");
   Check_Fixture
     ((1 => 2, 2 => 2, 3 => 2),
      "112233;112323;121233;121323;123123",
      "three months 2x2x2");

   Test_Preallocation_Retry
     ("wrong length count", 2, Wrong_Length, Valid_Two);
   Test_Preallocation_Retry
     ("late invalid month length", 2, Late_Invalid, Valid_Two);
   Test_Preallocation_Retry
     ("null length range", 2, Null_Lengths, Valid_Two);
   Test_Preallocation_Retry
     ("total exceeds 5778", 47, Too_Long, Valid_47);

   Test_Double_Build;
   Test_Before_Terminal_Retry;
   Test_Partial_Allocation_Failure
     (P.Raise_After_Terminal, 1, "after terminal allocation");
   Test_Partial_Allocation_Failure
     (P.Raise_After_First_Lower_Row, 2, "after first lower row allocation");

   Put_Line ("ISSUE29_LIFECYCLE_ASSERTIONS=" & Natural'Image (Checks));
   Put_Line ("ISSUE29_LIFECYCLE_CONTRACT_PASS");
end Issue29_Lifecycle_Regression;
