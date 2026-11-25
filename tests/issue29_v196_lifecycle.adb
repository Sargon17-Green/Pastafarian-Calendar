with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;
with Issue29_V196_Hooks;

procedure Issue29_V196_Lifecycle is
   package G renames GNATCOLL.GMP.Integers;
   package W renames Canonical_Full_Weave_GMP_V164;
   package H renames Issue29_V196_Hooks;
   use type G.Big_Integer;
   use type W.Natural_Array;
   use Ada.Text_IO;

   Checks : Natural := 0;

   procedure Check (OK : Boolean; Label_Text : String) is
   begin
      if not OK then
         Put_Line ("V196_CHECK_FAILED " & Label_Text);
         raise Program_Error;
      end if;
      Checks := Checks + 1;
   end Check;

   procedure Expect_Unbuilt (F : in W.Family; Label_Text : String) is
      Raised : Boolean := False;
      C : G.Big_Integer;
   begin
      begin
         W.Count (F, C);
      exception
         when Program_Error => Raised := True;
      end;
      Check (Raised, Label_Text & " Count must reject unbuilt Family");
      Raised := False;
      begin
         declare
            Ignored : constant W.Natural_Array := W.Unrank (F, G.Make ("1"));
         begin
            Check (Ignored'Length = 0, "unreachable unbuilt Unrank result");
         end;
      exception
         when Program_Error => Raised := True;
      end;
      Check (Raised, Label_Text & " Unrank must reject unbuilt Family");
   end Expect_Unbuilt;

   procedure Expect_Build_CE
     (F : in out W.Family; Lengths : W.Natural_Array; Label_Text : String)
   is
      Raised : Boolean := False;
   begin
      begin
         W.Build (F, Lengths);
      exception
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, Label_Text & " must raise Constraint_Error");
   end Expect_Build_CE;

   procedure Expect_Build_PE
     (F : in out W.Family; Lengths : W.Natural_Array; Label_Text : String)
   is
      Raised : Boolean := False;
   begin
      begin
         W.Build (F, Lengths);
      exception
         when Program_Error => Raised := True;
      end;
      Check (Raised, Label_Text & " must raise Program_Error");
   end Expect_Build_PE;

   procedure Expect_Unrank_CE
     (F : in W.Family; Rank : G.Big_Integer; Label_Text : String)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Ignored : constant W.Natural_Array := W.Unrank (F, Rank);
         begin
            Check (Ignored'Length = 0, "unreachable invalid-rank result");
         end;
      exception
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, Label_Text & " must raise Constraint_Error");
   end Expect_Unrank_CE;

begin
   --  A fresh object is unusable; all pre-allocation validation failures
   --  leave it retryable, including a late invalid month and a null array.
   H.Reset;
   declare
      F : W.Family (2);
      Empty : W.Natural_Array (2 .. 1);
   begin
      Expect_Unbuilt (F, "fresh");
      Expect_Build_CE (F, (1 => 2), "wrong array length");
      Expect_Unbuilt (F, "after wrong array length");
      Expect_Build_CE (F, Empty, "null array");
      Expect_Unbuilt (F, "after null array");
      Expect_Build_CE (F, (1, 124), "late invalid month");
      Expect_Unbuilt (F, "after late invalid month");
      Expect_Build_CE (F, (1, 2), "first invalid month");
      Expect_Unbuilt (F, "after first invalid month");

      W.Build (F, (2, 2));
      declare
         C : G.Big_Integer;
         First : constant W.Natural_Array := W.Unrank (F, G.Make ("1"));
         Last  : constant W.Natural_Array := W.Unrank (F, G.Make ("2"));
      begin
         W.Count (F, C);
         Check (C = G.Make ("2"), "two-month exact Count");
         Check (First = (1, 1, 2, 2), "rank 1 exact word");
         Check (Last = (1, 2, 1, 2), "rank 2 exact word");
      end;
      Expect_Build_PE (F, (2, 2), "second Build");
      Expect_Unrank_CE (F, G.Make ("0"), "rank zero");
      Expect_Unrank_CE (F, G.Make ("3"), "Count plus one");
      declare
         C : G.Big_Integer;
      begin
         W.Count (F, C);
         Check (C = G.Make ("2"), "Count stable after rejected second Build");
         Check (W.Unrank (F, G.Make ("1")) = (1, 1, 2, 2),
                "rank 1 stable after rejected second Build");
         Check (W.Unrank (F, G.Make ("2")) = (1, 2, 1, 2),
                "rank 2 stable after rejected second Build");
      end;
   end;
   Check (H.Allocation_Count = 3, "successful two-month Build allocated 3 rows");
   Check (H.Free_Count = 3, "successful Family finalized all 3 rows");

   --  Month-count and total-year bounds fail before any GMP row allocation.
   H.Reset;
   declare
      F : W.Family (48);
      Too_Many : W.Natural_Array (1 .. 48) := (others => 2);
   begin
      Expect_Build_CE (F, Too_Many, "48-month family");
      Expect_Unbuilt (F, "after 48-month rejection");
   end;
   Check (H.Allocation_Count = 0 and H.Free_Count = 0,
          "48-month rejection allocates and frees no rows");

   --  47*123 exceeds the 5778-day limit; same Family must be retryable.
   H.Reset;
   declare
      F : W.Family (47);
      Too_Long : W.Natural_Array (1 .. 47) := (others => 123);
      Legal : W.Natural_Array (1 .. 47) := (others => 2);
      C : G.Big_Integer;
      First : W.Natural_Array (1 .. 94);
      type Position_Array is array (1 .. 47) of Natural;
      Occurrences : Position_Array := (others => 0);
      First_Position : Position_Array := (others => 0);
      Last_Position : Position_Array := (others => 0);
   begin
      Expect_Build_CE (F, Too_Long, "total length 5781");
      Expect_Unbuilt (F, "after overlong year rejection");
      W.Build (F, Legal);
      W.Count (F, C);
      Check (C > G.Make ("0"), "47-month legal family has positive Count");
      First := W.Unrank (F, G.Make ("1"));
      for P in First'Range loop
         declare
            J : constant Natural := First (P);
         begin
            Check (J in 1 .. 47, "47-month Unrank symbol range");
            Occurrences (J) := Occurrences (J) + 1;
            if First_Position (J) = 0 then
               First_Position (J) := P;
            end if;
            Last_Position (J) := P;
         end;
      end loop;
      for J in 1 .. 47 loop
         Check (Occurrences (J) = 2, "47-month occurrence multiplicity");
         if J > 1 then
            Check (First_Position (J - 1) < First_Position (J),
                   "47-month first-occurrence order");
            Check (Last_Position (J - 1) < Last_Position (J),
                   "47-month last-occurrence order");
         end if;
      end loop;
   end;
   Check (H.Allocation_Count = 48, "47-month Build allocated 48 rows");
   Check (H.Free_Count = 48, "47-month Family finalized all 48 rows");

   --  Inject immediately after terminal-row allocation. The object is
   --  intentionally non-retryable, but Count/Unrank stay unavailable and
   --  Finalize must release the one allocated row exactly once.
   H.Reset;
   declare
      F : W.Family (2);
      Raised : Boolean := False;
   begin
      H.Arm (H.After_Terminal_Row);
      begin
         W.Build (F, (2, 2));
      exception
         when H.Injected_Failure => Raised := True;
      end;
      Check (Raised, "terminal-row failure injection reached");
      Expect_Unbuilt (F, "after terminal-row allocation failure");
      Expect_Build_PE (F, (2, 2), "retry after terminal-row allocation failure");
   end;
   Check (H.Allocation_Count = 1, "terminal injection allocated exactly one row");
   Check (H.Free_Count = 1, "terminal injection freed its row exactly once");

   --  Inject immediately after the first lower-row allocation. Finalize
   --  must release both live rows exactly once; no false Ready state.
   H.Reset;
   declare
      F : W.Family (2);
      Raised : Boolean := False;
   begin
      H.Arm (H.After_First_Lower_Row);
      begin
         W.Build (F, (2, 2));
      exception
         when H.Injected_Failure => Raised := True;
      end;
      Check (Raised, "first lower-row failure injection reached");
      Expect_Unbuilt (F, "after lower-row allocation failure");
      Expect_Build_PE (F, (2, 2), "retry after lower-row allocation failure");
   end;
   Check (H.Allocation_Count = 2, "lower-row injection allocated exactly two rows");
   Check (H.Free_Count = 2, "lower-row injection freed both rows exactly once");

   Put_Line ("V196_ASSERTIONS=" & Natural'Image (Checks));
   Put_Line ("V196_LIFECYCLE_CONTRACT_PASS_ZERO_F");
end Issue29_V196_Lifecycle;
