with Ada.Unchecked_Deallocation;
with GNATCOLL.GMP;

package body Canonical_Full_Weave_GMP_V164 is
   procedure Free_Row is new Ada.Unchecked_Deallocation (Big_Row, Big_Row_Access);

   procedure Set_N (To : out G.Big_Integer; Value : Natural) is
   begin
      G.Set_UL (To, GNATCOLL.GMP.Unsigned_Long (Value));
   end Set_N;

   overriding procedure Finalize (F : in out Family) is
   begin
      for I in F.H'Range loop
         if F.H (I) /= null then
            Free_Row (F.H (I));
         end if;
      end loop;
      F.Ready := False;
   end Finalize;

   procedure Binomial (N, K : Natural; Result : out G.Big_Integer) is
   begin
      if K > N then
         Set_N (Result, 0);
         return;
      end if;
      Set_N (Result, 1);
      declare
         Small : constant Natural := Natural'Min (K, N - K);
      begin
         for J in 1 .. Small loop
            G.Multiply (Result, GNATCOLL.GMP.Long (N - Small + J));
            G.Divide (Result, Result, GNATCOLL.GMP.Unsigned_Long (J));
         end loop;
      end;
   end Binomial;

   procedure Build (F : in out Family; Lengths : Natural_Array) is
   begin
      if F.Ready or else F.H (F.Month_Count) /= null then
         raise Program_Error with "v164 full-family GMP cache already built";
      end if;
      if F.Month_Count > 47 or else Lengths'Length /= F.Month_Count then
         raise Constraint_Error with "invalid GMP family month count";
      end if;
      for J in 1 .. F.Month_Count loop
         declare
            N : constant Natural := Lengths (Lengths'First + J - 1);
         begin
            if N < 2 or else N > 123 then
               raise Constraint_Error with "GMP full-family month lengths outside 2..123";
            end if;
            F.Lengths (J) := N;
            F.Prefix (J) := F.Prefix (J - 1) + N;
         end;
      end loop;
      if F.Prefix (F.Month_Count) > 5_778 then
         raise Constraint_Error with "GMP full-family year too long";
      end if;

      F.H (F.Month_Count) :=
        new Big_Row (0 .. F.Prefix (F.Month_Count));
      for Y in F.H (F.Month_Count)'Range loop
         Set_N (F.H (F.Month_Count) (Y), 1);
      end loop;

      --  H[i][x] = sum_{y=n-1}^{x+n-1} C(y-1,n-2) H[i+1][y].
      --  GMP procedural operations bypass the bounded GNAT Big_Integer.
      for I in reverse 0 .. F.Month_Count - 1 loop
         declare
            N : constant Natural := F.Lengths (I + 1);
            Max_Y : constant Natural := F.Prefix (I + 1) - 1;
            Weighted : G.Big_Integer;
            Coefficient : G.Big_Integer;
         begin
            F.H (I) := new Big_Row (0 .. F.Prefix (I));
            Set_N (Weighted, 0);
            Set_N (Coefficient, 1);
            for Y in N - 1 .. Max_Y loop
               declare
                  Product : G.Big_Integer :=
                    Coefficient * F.H (I + 1) (Y);
               begin
                  G.Add (Weighted, Product);
               end;
               G.Set (F.H (I) (Y - N + 1), Weighted);
               if Y < Max_Y then
                  G.Multiply (Coefficient, GNATCOLL.GMP.Long (Y));
                  G.Divide
                    (Coefficient, Coefficient,
                     GNATCOLL.GMP.Unsigned_Long (Y - N + 2));
               end if;
            end loop;
         end;
      end loop;
      F.Ready := True;
   end Build;

   procedure Count (F : Family; Result : out G.Big_Integer) is
   begin
      if not F.Ready then
         raise Program_Error with "v164 GMP family not built";
      end if;
      G.Set (Result, F.H (0) (0));
   end Count;

   procedure Completion_Count
     (F : Family; Remaining : Natural_Array;
      Opened, Closed : Natural; Result : out G.Big_Integer)
   is
      Base_Length : Natural := 0;
   begin
      Set_N (Result, 1);
      if Opened > F.Month_Count or else Closed > Opened then
         raise Program_Error with "invalid GMP open/close state";
      end if;
      for J in Closed + 1 .. Opened loop
         declare
            N : constant Natural := Remaining (J);
         begin
            if N = 0 then
               Set_N (Result, 0);
               return;
            end if;
            if Base_Length = 0 then
               Base_Length := N;
            else
               declare
                  Coefficient : G.Big_Integer;
               begin
                  Binomial (N + Base_Length - 1, Base_Length, Coefficient);
                  G.Multiply (Result, Coefficient);
               end;
               Base_Length := Base_Length + N;
            end if;
         end;
      end loop;
      if Base_Length > F.H (Opened)'Last then
         raise Program_Error with "GMP dynamic-programming state out of bounds";
      end if;
      G.Multiply (Result, F.H (Opened) (Base_Length));
   end Completion_Count;

   function Unrank (F : Family; Rank : G.Big_Integer) return Natural_Array is
      Remaining : Natural_Array (1 .. F.Month_Count) := F.Lengths;
      Output : Natural_Array (1 .. F.Prefix (F.Month_Count));
      R : G.Big_Integer;
      Total : G.Big_Integer;
      Opened : Natural := 0;
      Closed : Natural := 0;
   begin
      if not F.Ready then
         raise Program_Error with "v164 GMP family not built";
      end if;
      Count (F, Total);
      if Rank < GNATCOLL.GMP.Long (1) or else Rank > Total then
         raise Constraint_Error with "GMP full-family rank out of range";
      end if;
      G.Set (R, Rank);

      for Position in Output'Range loop
         declare
            Chosen : Boolean := False;
         begin
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
                     Block : G.Big_Integer;
                  begin
                     Next_Remaining (J) := Next_Remaining (J) - 1;
                     Completion_Count
                       (F, Next_Remaining, Next_Opened, Next_Closed, Block);
                     if R > Block then
                        G.Subtract (R, Block);
                     else
                        Output (Position) := J;
                        Remaining := Next_Remaining;
                        Opened := Next_Opened;
                        Closed := Next_Closed;
                        Chosen := True;
                        exit;
                     end if;
                  end;
               end if;
            end loop;
            if not Chosen then
               raise Program_Error with "no legal GMP full-family unrank transition";
            end if;
         end;
      end loop;

      if Opened /= F.Month_Count or else Closed /= F.Month_Count
        or else R /= GNATCOLL.GMP.Long (1)
      then
         raise Program_Error with "GMP full-family end state invalid";
      end if;
      for J in Remaining'Range loop
         if Remaining (J) /= 0 then
            raise Program_Error with "GMP full-family residual occurrences";
         end if;
      end loop;
      return Output;
   end Unrank;
end Canonical_Full_Weave_GMP_V164;
