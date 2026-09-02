with Ada.Numerics.Big_Numbers.Big_Integers;

package Stage01_Fixtures is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   Foundation : constant Big_Integer := To_Big_Integer (-15_055_671);
   Tablets    : constant Big_Integer := To_Big_Integer (-278_522);

   Stone_2_Wheat  : constant Big_Integer := To_Big_Integer (378);
   Stone_2_Barley : constant Big_Integer := To_Big_Integer (1_073);
   Stone_2_Salt   : constant Big_Integer := To_Big_Integer (2_375);
   Stone_2_Bitter : constant Big_Integer := To_Big_Integer (6_195);
   Stone_2_Red    : constant Big_Integer := To_Big_Integer (10_493);
end Stage01_Fixtures;
