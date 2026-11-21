with GNATCOLL.GMP;

package body Canonical_Wide_Rank_GMP_V164 is
   use Std;
   use G;

   M : constant Std.Big_Integer :=
     (Std.To_Big_Integer (2) ** 127) - Std.To_Big_Integer (1);

   function GMP_Of (X : Std.Big_Integer) return G.Big_Integer is
     (G.Make (Std.To_String (X)));

   function Answer_At
     (First : Std.Big_Integer; Step : Integer; K : Natural)
      return Std.Big_Integer
   is
      One : constant Std.Big_Integer := Std.To_Big_Integer (1);
   begin
      return One + ((First - One +
        Std.To_Big_Integer (Step) * Std.To_Big_Integer (Integer (K))) mod M);
   end Answer_At;

   procedure Choose_Rank
     (First : Std.Big_Integer; Step : Integer;
      N : G.Big_Integer; Result : out G.Big_Integer)
   is
      M_GMP : constant G.Big_Integer := GMP_Of (M);
      One : constant G.Big_Integer := G.Make ("1");
      X : G.Big_Integer;
      Limit : G.Big_Integer;
      Quotient : G.Big_Integer;
      Temp : G.Big_Integer;
   begin
      if Step not in -1 .. 1 or else Step = 0 then
         raise Constraint_Error with "unsupported fixed/reversed stream";
      end if;
      if First < Std.To_Big_Integer (1) or else First > M then
         raise Constraint_Error with "invalid first stream answer";
      end if;
      if N < One then
         raise Constraint_Error with "global rank family size must be positive";
      end if;

      if N <= M_GMP then
         --  Standard bounded short picker, but expressed in GMP for uniformity.
         --  The first accepted cyclic answer is either the current First,
         --  the limit (moving -1), or 1 (moving +1 and wrapping).
         G.Set (X, GMP_Of (First));
         G.Set (Quotient, M_GMP / N);
         G.Set (Limit, Quotient * N);
         if X > Limit then
            if Step = -1 then
               G.Set (X, Limit);
            else
               G.Set (X, One);
            end if;
         end if;
      else
         declare
            Space : G.Big_Integer := GMP_Of (M);
            Weight : G.Big_Integer := G.Make ("1");
            Wide : G.Big_Integer := G.Make ("1");
            Places : Positive := 1;
         begin
            while Space < N loop
               G.Multiply (Space, M_GMP);
               Places := Places + 1;
               if Places > 10_000 then
                  raise Constraint_Error with "unreasonably large GMP rank space";
               end if;
            end loop;
            for J in 0 .. Places - 1 loop
               declare
                  Digit : constant Std.Big_Integer :=
                    Answer_At (First, Step, J) - Std.To_Big_Integer (1);
                  Product : G.Big_Integer :=
                    GMP_Of (Digit) * Weight;
               begin
                  G.Add (Wide, Product);
               end;
               G.Multiply (Weight, M_GMP);
            end loop;
            G.Set (Quotient, Space / N);
            G.Set (Limit, Quotient * N);
            if Wide > Limit then
               if Step = -1 then
                  G.Set (Wide, Limit);
               else
                  G.Set (Wide, One);
               end if;
            end if;
            G.Set (X, Wide);
         end;
      end if;

      G.Set (Temp, X);
      G.Subtract (Temp, One);
      G.Get_Mod (Result, Temp, N);
      G.Add (Result, One);
      if Result < One or else Result > N then
         raise Program_Error with "GMP rank is outside the canonical family";
      end if;
   end Choose_Rank;
end Canonical_Wide_Rank_GMP_V164;
