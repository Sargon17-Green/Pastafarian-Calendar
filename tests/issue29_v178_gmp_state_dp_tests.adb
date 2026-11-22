with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

-- v178: native production GMP Count/Unrank ONLY; NO full calendar F(c,t).
procedure Issue29_V178_GMP_State_DP_Tests is
   package G renames GNATCOLL.GMP.Integers;
   package Full renames Canonical_Full_Weave_GMP_V164;
   use type G.Big_Integer;
   use Ada.Text_IO;
   Ref : File_Type;
   Assertions : Natural := 0;
   Cases : Natural := 0;
   Samples : Natural := 0;
   procedure Require (B : Boolean; Label : String) is
   begin
      Assertions := Assertions + 1;
      if not B then
         Put_Line ("FAILED_CHECK=" & Label);
         raise Program_Error with "v178 independent state-DP mismatch";
      end if;
   end Require;
   function Nat return Natural is
   begin
      return Natural'Value
        (Ada.Strings.Fixed.Trim (Get_Line (Ref), Ada.Strings.Both));
   end Nat;
   function Valid (Lengths, Weave : Full.Natural_Array) return Boolean is
      M : constant Natural := Lengths'Length;
      Count : Full.Natural_Array (1 .. M) := (others => 0);
      First : Full.Natural_Array (1 .. M) := (others => 0);
      Last : Full.Natural_Array (1 .. M) := (others => 0);
      Sum : Natural := 0;
   begin
      for J in Lengths'Range loop
         Sum := Sum + Lengths (J);
      end loop;
      if Sum /= Weave'Length then
         return False;
      end if;
      for K in Weave'Range loop
         declare
            J : constant Natural := Weave (K);
            P : constant Natural := K - Weave'First + 1;
         begin
            if J not in 1 .. M then
               return False;
            end if;
            Count (J) := Count (J) + 1;
            if First (J) = 0 then
               First (J) := P;
            end if;
            Last (J) := P;
         end;
      end loop;
      for J in 1 .. M loop
         if Count (J) /= Lengths (Lengths'First + J - 1) then
            return False;
         end if;
         if J > 1 and then
           (First (J - 1) >= First (J)
            or else Last (J - 1) >= Last (J))
         then
            return False;
         end if;
      end loop;
      return True;
   end Valid;

   function Is_Less
     (Left, Right : Full.Natural_Array) return Boolean
   is
   begin
      if Left'Length /= Right'Length then
         return False;
      end if;
      for K in 0 .. Left'Length - 1 loop
         if Left (Left'First + K) < Right (Right'First + K) then
            return True;
         elsif Left (Left'First + K) > Right (Right'First + K) then
            return False;
         end if;
      end loop;
      return False;
   end Is_Less;


   procedure One_Case is
      M : constant Natural := Nat;
   begin
      Require (M in 1 .. 47, "month count");
      declare
         L : Full.Natural_Array (1 .. M);
         D : Natural := 0;
      begin
         for J in L'Range loop
            L (J) := Nat;
            Require (L (J) in 2 .. 123, "month length");
            D := D + L (J);
         end loop;
         Require (D <= 5_778, "year length");
         declare
            F : Full.Family (Positive (M));
            Expected : G.Big_Integer;
            Actual_Count : G.Big_Integer;
            NS : Natural;
            Previous_Rank : G.Big_Integer;
            Previous : Full.Natural_Array (1 .. D) := (others => 0);
         begin
            G.Set (Expected, G.Make (Get_Line (Ref)));
            NS := Nat;
            Require (NS in 1 .. 7, "sample count");
            Full.Build (F, L);
            Full.Count (F, Actual_Count);
            Require (Expected = Actual_Count, "independent DP count");
            G.Set (Previous_Rank, G.Make ("0"));
            for S in 1 .. NS loop
               declare
                  R : G.Big_Integer;
               begin
                  G.Set (R, G.Make (Get_Line (Ref)));
                  Require (R > Previous_Rank and then R <= Actual_Count,
                           "strictly increasing sample ranks");
                  declare
                     Seq : constant Full.Natural_Array := Full.Unrank (F, R);
                  begin
                     Require (Seq'Length = D, "weave length");
                     for K in 1 .. D loop
                        declare
                           T : constant Natural := Nat;
                        begin
                           Require (T in 1 .. M, "oracle token bounds");
                           Require (Seq (Seq'First + K - 1) = T,
                                    "independent DP unrank exact token");
                        end;
                     end loop;
                     Require (Valid (L, Seq), "normative first/last rules");
                     if S > 1 then
                        Require (Is_Less (Previous, Seq), "lex order");
                     end if;
                     Previous := Seq;
                  end;
                  G.Set (Previous_Rank, R);
                  Samples := Samples + 1;
               end;
            end loop;
            declare
               Rejected : Boolean := False;
            begin
               begin
                  declare
                     Ignored : constant Full.Natural_Array :=
                        Full.Unrank (F, G.Make ("0"));
                  begin
                     if Ignored'Length = 0 then null; end if;
                  end;
               exception
                  when Constraint_Error => Rejected := True;
               end;
               Require (Rejected, "reject zero rank");
            end;
            declare
               Rejected : Boolean := False;
               Above : G.Big_Integer;
            begin
               G.Set (Above, Actual_Count);
               G.Add (Above, G.Make ("1"));
               begin
                  declare
                     Ignored : constant Full.Natural_Array :=
                        Full.Unrank (F, Above);
                  begin
                     if Ignored'Length = 0 then null; end if;
                  end;
               exception
                  when Constraint_Error => Rejected := True;
               end;
               Require (Rejected, "reject rank count+1");
            end;
         end;
         Cases := Cases + 1;
      end;
   end One_Case;
   N : Natural;
begin
   Open (Ref, In_File, "evidence/v178-reference.dat");
   N := Nat;
   Require (N = 15, "fifteen independent test families");
   for I in 1 .. N loop
      One_Case;
   end loop;
   Require (End_Of_File (Ref), "complete reference consumption");
   Close (Ref);
   Require (Cases = 15 and Samples >= 70 and Assertions > 2_000,
            "substantive witness totals");
   Put_Line ("V178_FAMILIES=" & Natural'Image (Cases));
   Put_Line ("V178_SAMPLES=" & Natural'Image (Samples));
   Put_Line ("V178_ASSERTIONS=" & Natural'Image (Assertions));
end Issue29_V178_GMP_State_DP_Tests;
