with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Unchecked_Deallocation;

package body Pure_Full_Weave_V122 is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   function B (X : Natural) return Big_Integer is
      (To_Big_Integer (Integer (X)));

   type Big_Vector is array (Natural range <>) of Big_Integer;
   type Vector_Access is access Big_Vector;
   type Table is array (Natural range <>) of Vector_Access;

   procedure Free is new Ada.Unchecked_Deallocation
     (Object => Big_Vector, Name => Vector_Access);

   function Count (Lengths : Natural_Array) return Big_Integer is
      M : constant Natural := Lengths'Length;
   begin
      if M = 0 or else M > 47 or else Lengths'First /= 1 then
         raise Constraint_Error with "expected 1 .. 47 1-based month lengths";
      end if;

      declare
         Prefix : array (Natural range 0 .. M) of Natural := (others => 0);
         H : Table (0 .. M) := (others => null);
         Result : Big_Integer := B (0);
      begin
         for J in 1 .. M loop
            if Lengths (J) < 1 or else Lengths (J) > 123 then
               raise Constraint_Error with "month length outside 1 .. 123";
            end if;
            if Prefix (J - 1) > 5_778 - Lengths (J) then
               raise Constraint_Error with "total exceeds maximal 5778 days";
            end if;
            Prefix (J) := Prefix (J - 1) + Lengths (J);
         end loop;

         H (M) := new Big_Vector (0 .. Prefix (M));
         for X in H (M).all'Range loop
            H (M) (X) := B (1);
         end loop;

         -- H[j,0] = H[j+1,n-1] for n >= 2;
         -- H[j,x] = H[j,x-1] + C(x+n-2,n-2)*H[j+1,x+n-1].
         -- C(x+n-2,n-2) is updated EXACTLY via multiplication then division.
         for J in reverse 0 .. M - 1 loop
            declare
               N : constant Positive := Positive (Lengths (J + 1));
               Binomial : Big_Integer := B (1);
            begin
               H (J) := new Big_Vector (0 .. Prefix (J));
               for X in 0 .. Prefix (J) loop
                  if N = 1 then
                     H (J) (X) := H (J + 1) (0);
                  else
                     if X > 0 then
                        Binomial :=
                          (Binomial * B (X + N - 2)) / B (X);
                     end if;
                     if X = 0 then
                        H (J) (X) :=
                          Binomial * H (J + 1) (X + N - 1);
                     else
                        H (J) (X) :=
                          H (J) (X - 1)
                          + Binomial * H (J + 1) (X + N - 1);
                     end if;
                  end if;
               end loop;
            end;
         end loop;
         Result := H (0) (0);
         for J in H'Range loop
            if H (J) /= null then
               Free (H (J));
            end if;
         end loop;
         return Result;
      end;
   end Count;

end Pure_Full_Weave_V122;
