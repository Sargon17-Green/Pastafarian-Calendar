with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;
with Canonical_Wide_Rank_GMP_V164;

procedure Issue29_V175_GMP_Wide_Rank_Tests is
   package Std renames Ada.Numerics.Big_Numbers.Big_Integers;
   package G renames GNATCOLL.GMP.Integers;
   package Full renames Canonical_Full_Weave_GMP_V164;
   package Wide renames Canonical_Wide_Rank_GMP_V164;

   use type Std.Big_Integer;
   use type G.Big_Integer;

   One_Std : constant Std.Big_Integer := Std.To_Big_Integer (1);
   M_Std : constant Std.Big_Integer :=
     (Std.To_Big_Integer (2) ** 127) - One_Std;
   M_GMP : constant G.Big_Integer := G.Make (Std.To_String (M_Std));
   One_GMP : constant G.Big_Integer := G.Make ("1");

   Large_Lengths : constant Full.Natural_Array (1 .. 45) :=
     (others => 94);
   Large_Family : Full.Family (45);
   Total : G.Big_Integer;
   Assertions : Natural := 0;

   function Answer_At
     (First : Std.Big_Integer; Step : Integer; K : Natural)
      return Std.Big_Integer
   is
   begin
      return One_Std +
        ((First - One_Std
          + Std.To_Big_Integer (Step) * Std.To_Big_Integer (Integer (K)))
         mod M_Std);
   end Answer_At;

   procedure Require (Condition : Boolean; Label : String) is
   begin
      Assertions := Assertions + 1;
      if not Condition then
         Ada.Text_IO.Put_Line ("CHECK=" & Label);
         raise Program_Error with "v175 GMP wide-rank composition assertion failed";
      end if;
   end Require;

   function Is_Normatively_Valid
     (Lengths, Weave : Full.Natural_Array) return Boolean
   is
      M : constant Natural := Lengths'Length;
      Counts : Full.Natural_Array (1 .. Lengths'Length) := (others => 0);
      First_Position : Full.Natural_Array (1 .. Lengths'Length) := (others => 0);
      Last_Position : Full.Natural_Array (1 .. Lengths'Length) := (others => 0);
   begin
      if Weave'Length /= Lengths'Length * 94 then
         return False;
      end if;

      for P in Weave'Range loop
         declare
            J : constant Natural := Weave (P);
            Position : constant Natural := P - Weave'First + 1;
         begin
            if J not in 1 .. M then
               return False;
            end if;
            Counts (J) := Counts (J) + 1;
            if First_Position (J) = 0 then
               First_Position (J) := Position;
            end if;
            Last_Position (J) := Position;
         end;
      end loop;

      for J in 1 .. M loop
         if Counts (J) /= Lengths (Lengths'First + J - 1)
           or else First_Position (J) = 0
           or else Last_Position (J) = 0
         then
            return False;
         end if;
         if J > 1
           and then
             (First_Position (J - 1) >= First_Position (J)
              or else Last_Position (J - 1) >= Last_Position (J))
         then
            return False;
         end if;
      end loop;
      return True;
   end Is_Normatively_Valid;

   --  Independent expression of the mixed-radix stream definition.
   --  This computes the initial candidate with GMP arithmetic operators,
   --  then applies the exact first-accepted boundary rule; it does not call
   --  Canonical_Wide_Rank_GMP_V164.
   procedure Reference_Rank
     (First : Std.Big_Integer;
      Step : Integer;
      N : G.Big_Integer;
      Result : out G.Big_Integer;
      Places : out Natural;
      Rejected : out Boolean)
   is
      Space : G.Big_Integer := M_GMP;
      Weight : G.Big_Integer := One_GMP;
      Wide_Value : G.Big_Integer := One_GMP;
      Quotient : G.Big_Integer;
      Limit : G.Big_Integer;
      Temp : G.Big_Integer;
   begin
      Places := 1;
      while Space < N loop
         G.Multiply (Space, M_GMP);
         Places := Places + 1;
         if Places > 10_000 then
            raise Constraint_Error with "reference rank space exceeds safety cap";
         end if;
      end loop;

      for J in 0 .. Places - 1 loop
         declare
            Digit : constant Std.Big_Integer :=
              Answer_At (First, Step, J) - One_Std;
            Product : G.Big_Integer := G.Make (Std.To_String (Digit)) * Weight;
         begin
            G.Add (Wide_Value, Product);
         end;
         G.Multiply (Weight, M_GMP);
      end loop;

      G.Set (Quotient, Space / N);
      G.Set (Limit, Quotient * N);
      Rejected := Wide_Value > Limit;

      if Rejected then
         if Step = -1 then
            G.Set (Wide_Value, Limit);
         else
            G.Set (Wide_Value, One_GMP);
         end if;
      end if;

      G.Set (Temp, Wide_Value);
      G.Subtract (Temp, One_GMP);
      G.Get_Mod (Result, Temp, N);
      G.Add (Result, One_GMP);
   end Reference_Rank;

   procedure Check_Stream
     (First : Std.Big_Integer;
      Step : Integer;
      Expected_Rejection : Boolean;
      Label : String)
   is
      Expected : G.Big_Integer;
      Actual : G.Big_Integer;
      Places : Natural;
      Rejected : Boolean;
   begin
      Reference_Rank
        (First, Step, Total, Expected, Places, Rejected);
      Require (Places = 179, Label & ":179-place family");
      Require
        (Rejected = Expected_Rejection,
         Label & ":selected acceptance/rejection path");

      Wide.Choose_Rank (First, Step, Total, Actual);
      Require
        (Actual = Expected,
         Label & ":production GMP rank equals independent expression");
      Require
        (Actual >= One_GMP and then Actual <= Total,
         Label & ":rank remains inside exact global family");

      declare
         Selected_Weave : constant Full.Natural_Array :=
           Full.Unrank (Large_Family, Actual);
      begin
         Require
           (Is_Normatively_Valid (Large_Lengths, Selected_Weave),
            Label & ":selected rank unpacks to a normative 45-month weave");
      end;
   end Check_Stream;

begin
   Full.Build (Large_Family, Large_Lengths);
   Full.Count (Large_Family, Total);
   Require (Total > One_GMP, "45-month GMP family has a positive nontrivial count");

   --  The (45 x 94) family has 22,659 bits and requires 179 radix-M places.
   --  These streams exercise both rejection endpoints and accepted interiors.
   Check_Stream (One_Std, -1, True, "first answer, descending");
   Check_Stream (One_Std, 1, False, "first answer, ascending");
   Check_Stream (M_Std, -1, True, "maximum answer, descending");
   Check_Stream (M_Std, 1, False, "maximum answer, ascending");
   Check_Stream
     (M_Std / Std.To_Big_Integer (2), -1, False,
      "middle answer, descending");
   Check_Stream
     (M_Std / Std.To_Big_Integer (2), 1, False,
      "middle answer, ascending");

   if Assertions /= 31 then
      raise Program_Error with "v175 expected exactly 31 GMP wide-rank assertions";
   end if;

   Ada.Text_IO.Put_Line ("ISSUE29_V175_GMP_WIDE_RANK_PLACES= 179");
   Ada.Text_IO.Put_Line ("ISSUE29_V175_GMP_WIDE_RANK_CASES= 6");
   Ada.Text_IO.Put_Line
     ("ISSUE29_V175_GMP_WIDE_RANK_ASSERTIONS=" & Natural'Image (Assertions));
end Issue29_V175_GMP_Wide_Rank_Tests;
