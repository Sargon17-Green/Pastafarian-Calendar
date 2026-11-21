with Ada.Unchecked_Deallocation;

package body Canonical_Full_Weave_V163 is
   function B (N : Natural) return Big_Integer is (To_Big_Integer (Integer (N)));

   procedure Free_Row is new Ada.Unchecked_Deallocation (Big_Row, Big_Row_Access);

   overriding procedure Finalize (F : in out Family) is
   begin
      for I in F.H'Range loop
         if F.H (I) /= null then
            Free_Row (F.H (I));
         end if;
      end loop;
      F.Ready := False;
   end Finalize;

   function Binomial (N, K : Natural) return Big_Integer is
      R : Big_Integer := B (1);
   begin
      if K > N then
         return B (0);
      end if;
      declare
         Small : constant Natural := Natural'Min (K, N - K);
      begin
         for J in 1 .. Small loop
            --  At each step the quotient is an integer.
            R := (R * B (N - Small + J)) / B (J);
         end loop;
      end;
      return R;
   end Binomial;

   procedure Build (F : in out Family; Lengths : Natural_Array) is
   begin
      if F.Ready or else F.H (F.Month_Count) /= null then
         raise Program_Error with "full-family cache must not be built twice";
      end if;
      if Lengths'Length /= F.Month_Count
        or else F.Month_Count > 47
      then
         raise Constraint_Error with "invalid full-family month count";
      end if;

      for J in 1 .. F.Month_Count loop
         declare
            N : constant Natural := Lengths (Lengths'First + J - 1);
         begin
            if N < 2 or else N > 123 then
               raise Constraint_Error with "month lengths outside 2..123";
            end if;
            F.Lengths (J) := N;
            F.Prefix (J) := F.Prefix (J - 1) + N;
         end;
      end loop;

      if F.Prefix (F.Month_Count) > 5_778 then
         raise Constraint_Error with "year too long for canonical month family";
      end if;

      F.H (F.Month_Count) := new Big_Row'
        (0 .. F.Prefix (F.Month_Count) => B (1));

      --  This is the exact closed-form transition of the all-legal-weaves
      --  family: H[i][x] = sum_{y=n-1}^{x+n-1}
      --    C(y-1, n-2) * H[i+1][y].
      --  A running weighted prefix avoids a quadratic scan for each x.
      for I in reverse 0 .. F.Month_Count - 1 loop
         declare
            N : constant Natural := F.Lengths (I + 1);
            Max_Y : constant Natural := F.Prefix (I + 1) - 1;
            Weighted : Big_Integer := B (0);
            Coefficient : Big_Integer := B (1);
         begin
            F.H (I) := new Big_Row'(0 .. F.Prefix (I) => B (0));
            for Y in N - 1 .. Max_Y loop
               Weighted := Weighted + Coefficient * F.H (I + 1) (Y);
               F.H (I) (Y - N + 1) := Weighted;
               if Y < Max_Y then
                  --  C(Y, N-2) from C(Y-1, N-2), exact at every step.
                  Coefficient :=
                    (Coefficient * B (Y)) / B (Y - N + 2);
               end if;
            end loop;
         end;
      end loop;
      F.Ready := True;
   end Build;

   function Count (F : Family) return Big_Integer is
   begin
      if not F.Ready then
         raise Program_Error with "uninitialized full-family cache";
      end if;
      return F.H (0) (0);
   end Count;

   function Completion_Count
     (F : Family; Remaining : Natural_Array;
      Opened, Closed : Natural) return Big_Integer
   is
      Base_Count : Big_Integer := B (1);
      Base_Length : Natural := 0;
   begin
      if Opened > F.Month_Count or else Closed > Opened then
         raise Program_Error with "invalid opening/closing state";
      end if;
      for J in Closed + 1 .. Opened loop
         declare
            N : constant Natural := Remaining (J);
         begin
            if N = 0 then
               return B (0);
            end if;
            if Base_Length = 0 then
               Base_Length := N;
            else
               Base_Count :=
                 Base_Count * Binomial (N + Base_Length - 1, Base_Length);
               Base_Length := Base_Length + N;
            end if;
         end;
      end loop;

      if Base_Length > F.H (Opened)'Last then
         raise Program_Error with "state outside dynamic-programming table";
      end if;
      return Base_Count * F.H (Opened) (Base_Length);
   end Completion_Count;

   function Unrank (F : Family; Rank : Big_Integer) return Natural_Array is
      Remaining : Natural_Array (1 .. F.Month_Count) := F.Lengths;
      Output : Natural_Array (1 .. F.Prefix (F.Month_Count));
      R : Big_Integer := Rank;
      Opened : Natural := 0;
      Closed : Natural := 0;
   begin
      if not F.Ready then
         raise Program_Error with "uninitialized full-family cache";
      end if;
      if R < B (1) or else R > Count (F) then
         raise Constraint_Error with "full-family rank outside 1..Count";
      end if;

      for Position in Output'Range loop
         declare
            Chosen : Boolean := False;
         begin
            --  Existing open month IDs are smaller than the next unopened ID.
            --  The only legal month closure is Closed+1.
            for J in Closed + 1 .. Natural'Min (Opened + 1, F.Month_Count) loop
               if Remaining (J) > 0
                 and then (J = Opened + 1
                           or else Remaining (J) > 1
                           or else J = Closed + 1)
               then
                  declare
                     Next_Remaining : Natural_Array := Remaining;
                     Next_Opened : constant Natural :=
                       (if J = Opened + 1 then Opened + 1 else Opened);
                     Next_Closed : constant Natural :=
                       (if Remaining (J) = 1 then Closed + 1 else Closed);
                  begin
                     Next_Remaining (J) := Next_Remaining (J) - 1;
                     declare
                        Block : constant Big_Integer :=
                          Completion_Count
                            (F, Next_Remaining, Next_Opened, Next_Closed);
                     begin
                        if R > Block then
                           R := R - Block;
                        else
                           Output (Position) := J;
                           Remaining := Next_Remaining;
                           Opened := Next_Opened;
                           Closed := Next_Closed;
                           Chosen := True;
                           exit;
                        end if;
                     end;
                  end;
               end if;
            end loop;
            if not Chosen then
               raise Program_Error with "no legal full-family unranking transition";
            end if;
         end;
      end loop;
      if Opened /= F.Month_Count or else Closed /= F.Month_Count or else R /= B (1) then
         raise Program_Error with "incomplete full-family unranking state";
      end if;
      for J in Remaining'Range loop
         if Remaining (J) /= 0 then
            raise Program_Error with "nonzero remaining month occurrences";
         end if;
      end loop;
      return Output;
   end Unrank;
end Canonical_Full_Weave_V163;
