with Ada.Numerics.Big_Numbers.Big_Integers;

package body Legal_Month_Weave_DP is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   Max_Months : constant Positive := 12;
   Max_Days   : constant Positive := 256;

   Zero : constant Big_Integer := To_Big_Integer (0);
   One  : constant Big_Integer := To_Big_Integer (1);

   type Big_Matrix is
     array (Natural range 0 .. Max_Months, Natural range 0 .. Max_Days)
       of Big_Integer;
   type Big_Row is array (Natural range 0 .. Max_Days) of Big_Integer;
   type Natural_Row is array (Natural range 0 .. Max_Months) of Natural;
   type Remaining_Row is array (Positive range 1 .. Max_Months) of Natural;

   type Context is record
      Months : Natural := 0;
      Days   : Natural := 0;
      H      : Big_Matrix := (others => (others => Zero));
   end record;

   type Candidate is record
      Label     : Natural := 0;
      Remaining : Remaining_Row := (others => 0);
      Opened    : Natural := 0;
      Closed    : Natural := 0;
   end record;

   type Candidate_Row is
     array (Positive range 1 .. Max_Months + 1) of Candidate;

   procedure Require (Condition : Boolean) is
   begin
      if not Condition then
         raise Constraint_Error with "invalid isolated month weaving request";
      end if;
   end Require;

   function B (N : Natural) return Big_Integer is
     (To_Big_Integer (Integer (N)));

   procedure Validate (Lengths : Month_Lengths;
                       M, T : out Natural) is
   begin
      M := Lengths'Length;
      T := 0;
      Require (M in 1 .. Max_Months and then Lengths'First = 1);
      for J in Lengths'Range loop
         Require (Lengths (J) <= Max_Days
                  and then T <= Max_Days - Lengths (J));
         T := T + Lengths (J);
      end loop;
   end Validate;

   function Binomial (N, K : Natural) return Big_Integer is
      Value : Big_Integer := One;
   begin
      if K > N then
         return Zero;
      end if;
      for I in 1 .. Natural'Min (K, N - K) loop
         Value := (Value * B (N - I + 1)) / B (I);
      end loop;
      return Value;
   end Binomial;

   function Build (Lengths : Month_Lengths) return Context is
      C      : Context;
      Prefix : Natural_Row := (others => 0);
   begin
      Validate (Lengths, C.Months, C.Days);
      for J in 1 .. C.Months loop
         Prefix (J) := Prefix (J - 1) + Lengths (J);
      end loop;
      for X in 0 .. C.Days loop
         C.H (C.Months, X) := One;
      end loop;

      --  The H recurrence is source-equivalent to Python's original
      --  MonthWeavingFamily._h, but uses incremental exact binomials.
      for I in reverse 0 .. C.Months - 1 loop
         declare
            N        : constant Positive := Lengths (I + 1);
            Weighted : Big_Row := (others => Zero);
            Running  : Big_Integer := Zero;
            Choose   : Big_Integer := One;
         begin
            if N = 1 then
               for X in 0 .. Prefix (I) loop
                  C.H (I, X) := C.H (I + 1, 0);
               end loop;
            else
               for Y in N - 1 .. Prefix (I + 1) - 1 loop
                  if Y > N - 1 then
                     Choose := (Choose * B (Y - 1)) / B (Y - N + 1);
                  end if;
                  Running := Running + Choose * C.H (I + 1, Y);
                  Weighted (Y) := Running;
               end loop;
               for X in 0 .. Prefix (I) loop
                  C.H (I, X) := Weighted (X + N - 1);
               end loop;
            end if;
         end;
      end loop;
      return C;
   end Build;

   function State_Count
     (C : Context; Remaining : Remaining_Row;
      Opened, Closed : Natural) return Big_Integer
   is
      Ways  : Big_Integer := One;
      Total : Natural := 0;
   begin
      Require (Closed <= Opened and then Opened <= C.Months);
      for J in Closed + 1 .. Opened loop
         if Remaining (J) = 0 then
            return Zero;
         end if;
         if Total > 0 then
            Ways := Ways *
              Binomial (Remaining (J) + Total - 1, Total);
         end if;
         Total := Total + Remaining (J);
      end loop;
      Require (Total <= C.Days);
      return Ways * C.H (Opened, Total);
   end State_Count;

   procedure Enumerate_Moves
     (C : Context; Remaining : Remaining_Row;
      Opened, Closed : Natural;
      Options : out Candidate_Row; Number : out Natural)
   is
      Next : Remaining_Row;
      After_Closed : Natural;
   begin
      Require (Closed <= Opened and then Opened <= C.Months);
      Number := 0;
      Options := (others => (others => <>));

      --  Exactly the Python source order: already opened month IDs first,
      --  ascending, followed by opening the next unopened month.
      for J in Closed + 1 .. Opened loop
         if Remaining (J) > 0
           and then not (Remaining (J) = 1 and then J /= Closed + 1)
         then
            Next := Remaining;
            Next (J) := Next (J) - 1;
            After_Closed := Closed;
            if Next (J) = 0 then
               After_Closed := Closed + 1;
            end if;
            Number := Number + 1;
            Options (Number) :=
              (Label => J, Remaining => Next,
               Opened => Opened, Closed => After_Closed);
         end if;
      end loop;

      if Opened < C.Months then
         declare
            J : constant Positive := Opened + 1;
         begin
            Next := Remaining;
            Require (Next (J) > 0);
            Next (J) := Next (J) - 1;
            After_Closed := Closed;
            if Next (J) = 0 then
               Require (J = Closed + 1);
               After_Closed := Closed + 1;
            end if;
            Number := Number + 1;
            Options (Number) :=
              (Label => J, Remaining => Next,
               Opened => Opened + 1, Closed => After_Closed);
         end;
      end if;
   end Enumerate_Moves;

   function Initial_Remaining (Lengths : Month_Lengths)
     return Remaining_Row
   is
      Result : Remaining_Row := (others => 0);
   begin
      for J in Lengths'Range loop
         Result (J) := Lengths (J);
      end loop;
      return Result;
   end Initial_Remaining;

   function Count (Lengths : Month_Lengths) return Big_Integer is
      C : constant Context := Build (Lengths);
   begin
      return C.H (0, 0);
   end Count;

   function Unrank
     (Lengths : Month_Lengths; Position : Big_Integer)
      return Month_Sequence
   is
      C         : constant Context := Build (Lengths);
      Remaining : Remaining_Row := Initial_Remaining (Lengths);
      Opened    : Natural := 0;
      Closed    : Natural := 0;
      R         : Big_Integer := Position;
      Result    : Month_Sequence (1 .. C.Days);
      Options   : Candidate_Row;
      Number    : Natural;
      Selected  : Boolean;
      Block     : Big_Integer;
   begin
      Require (R >= One and then R <= C.H (0, 0));
      for P in Result'Range loop
         Enumerate_Moves (C, Remaining, Opened, Closed, Options, Number);
         Selected := False;
         for J in 1 .. Number loop
            Block := State_Count
              (C, Options (J).Remaining,
               Options (J).Opened, Options (J).Closed);
            if R > Block then
               R := R - Block;
            else
               Result (P) := Options (J).Label;
               Remaining := Options (J).Remaining;
               Opened := Options (J).Opened;
               Closed := Options (J).Closed;
               Selected := True;
               exit;
            end if;
         end loop;
         Require (Selected);
      end loop;
      Require (Opened = C.Months and then Closed = C.Months
               and then R = One);
      for J in 1 .. C.Months loop
         Require (Remaining (J) = 0);
      end loop;
      return Result;
   end Unrank;

   function Rank
     (Lengths : Month_Lengths; Sequence : Month_Sequence)
      return Big_Integer
   is
      C         : constant Context := Build (Lengths);
      Remaining : Remaining_Row := Initial_Remaining (Lengths);
      Opened    : Natural := 0;
      Closed    : Natural := 0;
      R         : Big_Integer := One;
      Options   : Candidate_Row;
      Number    : Natural;
      Selected  : Boolean;
   begin
      Require (Sequence'First = 1 and then Sequence'Length = C.Days);
      for P in Sequence'Range loop
         Enumerate_Moves (C, Remaining, Opened, Closed, Options, Number);
         Selected := False;
         for J in 1 .. Number loop
            if Options (J).Label = Sequence (P) then
               Remaining := Options (J).Remaining;
               Opened := Options (J).Opened;
               Closed := Options (J).Closed;
               Selected := True;
               exit;
            else
               R := R + State_Count
                 (C, Options (J).Remaining,
                  Options (J).Opened, Options (J).Closed);
            end if;
         end loop;
         Require (Selected);
      end loop;
      Require (Opened = C.Months and then Closed = C.Months
               and then R >= One and then R <= C.H (0, 0));
      for J in 1 .. C.Months loop
         Require (Remaining (J) = 0);
      end loop;
      return R;
   end Rank;

end Legal_Month_Weave_DP;
