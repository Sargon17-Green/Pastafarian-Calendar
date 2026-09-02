with Ada.Numerics.Big_Numbers.Big_Integers;

package body Exact_Math is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   function Regular_Mod (X, D : Big_Integer) return Big_Integer is
   begin
      if D < To_Big_Integer (1) then
         raise Constraint_Error with "భాజకం కనీసం ఒకటి కావాలి";
      end if;
      return X mod D;
   end Regular_Mod;

   function Save (X : Big_Integer) return Big_Integer is
   begin
      return To_Big_Integer (1) + Regular_Mod (X - To_Big_Integer (1), M);
   end Save;

   function Square (X : Big_Integer) return Big_Integer is
   begin
      return X * X;
   end Square;

   function Floor_Div (A, B : Big_Integer) return Big_Integer is
   begin
      if B < To_Big_Integer (1) then
         raise Constraint_Error with "ధన భాజకం అవసరం";
      end if;
      return (A - Regular_Mod (A, B)) / B;
   end Floor_Div;

   function Ceil_Div (A, B : Big_Integer) return Big_Integer is
   begin
      if A < To_Big_Integer (0) or else B < To_Big_Integer (1) then
         raise Constraint_Error with "శూన్యం లేదా ధన లబ్ధి మరియు ధన భాజకం అవసరం";
      end if;
      return Floor_Div (A + B - To_Big_Integer (1), B);
   end Ceil_Div;

   function Wrap_1 (Position, Size : Positive) return Positive is
      R : constant Integer := Integer (Position - 1) mod Integer (Size);
   begin
      return Positive (R + 1);
   end Wrap_1;

   function To_Natural_Checked
     (X : Big_Integer; Maximum : Natural) return Natural
   is
      N : Natural := 0;
      Y : Big_Integer := X;
   begin
      if Y < To_Big_Integer (0) or else Y > To_Big_Integer (Integer (Maximum)) then
         raise Constraint_Error with "పరిమిత సహజ సంఖ్య పరిధి దాటింది";
      end if;
      while Y > To_Big_Integer (0) loop
         Y := Y - To_Big_Integer (1);
         N := N + 1;
      end loop;
      return N;
   end To_Natural_Checked;

   function Factorial (N : Natural) return Big_Integer is
      R : Big_Integer := To_Big_Integer (1);
   begin
      for I in 2 .. N loop
         R := R * To_Big_Integer (I);
      end loop;
      return R;
   end Factorial;

   function Falling_Factorial (N, K : Natural) return Big_Integer is
      R : Big_Integer := To_Big_Integer (1);
   begin
      if K > N then
         return To_Big_Integer (0);
      end if;
      if K = 0 then
         return R;
      end if;
      for J in 0 .. K - 1 loop
         R := R * To_Big_Integer (N - J);
      end loop;
      return R;
   end Falling_Factorial;

end Exact_Math;
