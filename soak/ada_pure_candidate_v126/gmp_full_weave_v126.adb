with Interfaces.C;
with System;
with Ada.Unchecked_Deallocation;

package body GMP_Full_Weave_V126 is
   package C renames Interfaces.C;
   use type System.Address;

   -- GMP mpz_t is an array of one __mpz_struct. These three fields have
   -- exactly the C ABI layout: int _mp_alloc, int _mp_size, mp_limb_t *_mp_d.
   -- Linux x86_64 is the only CI target for this experimental binding.
   type MPZ_Object is record
      Allocated : C.int;
      Used      : C.int;
      Digits    : System.Address;
   end record;
   pragma Convention (C, MPZ_Object);

   type MPZ_Vector is array (Natural range <>) of aliased MPZ_Object;
   type Vector_Access is access MPZ_Vector;
   procedure Release is new Ada.Unchecked_Deallocation
     (Object => MPZ_Vector, Name => Vector_Access);

   procedure Init (X : access MPZ_Object)
     with Import, Convention => C, External_Name => "__gmpz_init";
   procedure Clear (X : access MPZ_Object)
     with Import, Convention => C, External_Name => "__gmpz_clear";
   procedure Set_UI (X : access MPZ_Object; V : C.unsigned_long)
     with Import, Convention => C, External_Name => "__gmpz_set_ui";
   procedure Set (X, Y : access MPZ_Object)
     with Import, Convention => C, External_Name => "__gmpz_set";
   procedure Add (R, X, Y : access MPZ_Object)
     with Import, Convention => C, External_Name => "__gmpz_add";
   procedure Multiply (R, X, Y : access MPZ_Object)
     with Import, Convention => C, External_Name => "__gmpz_mul";
   procedure Multiply_UI
     (R, X : access MPZ_Object; V : C.unsigned_long)
     with Import, Convention => C, External_Name => "__gmpz_mul_ui";
   function Is_Divisible_UI
     (X : access MPZ_Object; V : C.unsigned_long) return C.int
     with Import, Convention => C,
          External_Name => "__gmpz_divisible_ui_p";
   procedure Divide_Exact_UI
     (R, X : access MPZ_Object; V : C.unsigned_long)
     with Import, Convention => C, External_Name => "__gmpz_divexact_ui";
   function Size_In_Base
     (X : access MPZ_Object; Base : C.int) return C.size_t
     with Import, Convention => C, External_Name => "__gmpz_sizeinbase";
   function Get_String
     (Buffer : System.Address; Base : C.int; X : access MPZ_Object)
      return System.Address
     with Import, Convention => C, External_Name => "__gmpz_get_str";

   procedure Destroy (V : in out Vector_Access) is
   begin
      if V /= null then
         for I in V.all'Range loop
            Clear (V (I)'Access);
         end loop;
         Release (V);
      end if;
   end Destroy;

   function Decimal (X : access MPZ_Object) return String is
      -- GMP guarantees sizeinbase + 2 bytes suffice for the signed result
      -- and the terminating NUL; all results here are nonnegative.
      Buffer : aliased C.char_array (0 .. Size_In_Base (X, 10) + 1);
      Returned : constant System.Address :=
        Get_String (Buffer'Address, 10, X);
   begin
      if Returned /= Buffer'Address then
         raise Program_Error with "GMP decimal output buffer mismatch";
      end if;
      return C.To_Ada (Buffer, Trim_Nul => True);
   end Decimal;

   function Count_Decimal (Lengths : Natural_Array) return String is
      M : constant Natural := Lengths'Length;
   begin
      if M = 0 or else M > 47 or else Lengths'First /= 1 then
         raise Constraint_Error with "expected 1 .. 47 one-based months";
      end if;

      declare
         Prefix  : array (Natural range 0 .. M) of Natural :=
           (others => 0);
         Prior   : Vector_Access := null;
         Current : Vector_Access := null;
      begin
         for J in 1 .. M loop
            if Lengths (J) < 1 or else Lengths (J) > 123 then
               raise Constraint_Error with "invalid month length";
            end if;
            if Prefix (J - 1) > 5_778 - Lengths (J) then
               raise Constraint_Error with "more than 5778 days";
            end if;
            Prefix (J) := Prefix (J - 1) + Lengths (J);
         end loop;

         -- Base row H[m,x] = 1, all x. Retain only two rows at a time.
         Prior := new MPZ_Vector (0 .. Prefix (M));
         for X in Prior.all'Range loop
            Init (Prior (X)'Access);
            Set_UI (Prior (X)'Access, 1);
         end loop;

         for J in reverse 0 .. M - 1 loop
            Current := new MPZ_Vector (0 .. Prefix (J));
            for X in Current.all'Range loop
               Init (Current (X)'Access);
            end loop;
            declare
               N        : constant Natural := Lengths (J + 1);
               Binomial : aliased MPZ_Object;
               Product  : aliased MPZ_Object;
            begin
               Init (Binomial'Access);
               Init (Product'Access);
               Set_UI (Binomial'Access, 1);

               for X in Current.all'Range loop
                  if N = 1 then
                     Set (Current (X)'Access, Prior (0)'Access);
                  else
                     -- B(x)=C(x+n-2,n-2), B(0)=1, and
                     -- B(x)=B(x-1)*(x+n-2)/x for x>=1.
                     if X > 0 then
                        Multiply_UI
                          (Binomial'Access, Binomial'Access,
                           C.unsigned_long (X + N - 2));
                        if Is_Divisible_UI
                             (Binomial'Access, C.unsigned_long (X)) /= 1
                        then
                           raise Program_Error with
                             "binomial division was not exact";
                        end if;
                        Divide_Exact_UI
                          (Binomial'Access, Binomial'Access,
                           C.unsigned_long (X));
                     end if;
                     Multiply
                       (Product'Access, Binomial'Access,
                        Prior (X + N - 1)'Access);
                     if X = 0 then
                        Set (Current (X)'Access, Product'Access);
                     else
                        Add
                          (Current (X)'Access, Current (X - 1)'Access,
                           Product'Access);
                     end if;
                  end if;
               end loop;
               Clear (Product'Access);
               Clear (Binomial'Access);
            end;
            Destroy (Prior);
            Prior := Current;
            Current := null;
         end loop;

         declare
            Answer : constant String := Decimal (Prior (0)'Access);
         begin
            Destroy (Prior);
            return Answer;
         end;
      end;
   end Count_Decimal;
end GMP_Full_Weave_V126;
