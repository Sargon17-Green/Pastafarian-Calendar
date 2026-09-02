with Ada.Numerics.Big_Numbers.Big_Integers;

package Exact_Math is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   M : constant Big_Integer :=
     (To_Big_Integer (2) ** 127) - To_Big_Integer (1);

   function Regular_Mod (X, D : Big_Integer) return Big_Integer;
   function Save        (X : Big_Integer) return Big_Integer;
   function Square      (X : Big_Integer) return Big_Integer;
   function Ceil_Div    (A, B : Big_Integer) return Big_Integer;
   function Floor_Div   (A, B : Big_Integer) return Big_Integer;
   function Wrap_1      (Position, Size : Positive) return Positive;
   function To_Natural_Checked
     (X : Big_Integer; Maximum : Natural) return Natural;
   function Factorial (N : Natural) return Big_Integer;
   function Falling_Factorial (N, K : Natural) return Big_Integer;
end Exact_Math;
