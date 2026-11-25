with Ada.Strings.Fixed;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

procedure Issue29_V198_Small_Oracle is
   package G renames GNATCOLL.GMP.Integers;
   package W renames Canonical_Full_Weave_GMP_V164;
   use type G.Big_Integer;
   use type W.Natural_Array;
   use Ada.Text_IO;

   Checks : Natural := 0;
   Families : Natural := 0;
   Words : Natural := 0;
   Rank_Comparisons : Natural := 0;

   procedure Check (OK : Boolean; Label_Text : String) is
   begin
      if not OK then
         Put_Line ("V198_CHECK_FAILED " & Label_Text);
         raise Program_Error;
      end if;
      Checks := Checks + 1;
   end Check;

   function Encode (A : W.Natural_Array) return String is
      Result : String (1 .. A'Length);
   begin
      for I in A'Range loop
         if A (I) not in 1 .. 4 then
            raise Program_Error with "unexpected month index in v198 small oracle";
         end if;
         Result (I - A'First + 1) :=
           Character'Val (Character'Pos ('0') + A (I));
      end loop;
      return Result;
   end Encode;

   procedure Expect_Rank_CE
     (F : in W.Family; Rank : G.Big_Integer; Label_Text : String)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Ignored : constant W.Natural_Array := W.Unrank (F, Rank);
         begin
            Check (Ignored'Length = 0, "unreachable invalid rank result");
         end;
      exception
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, Label_Text & " invalid rank must raise Constraint_Error");
   end Expect_Rank_CE;

   procedure Check_Family
     (Lengths : W.Natural_Array; Expected : String; Label_Text : String)
   is
      M : constant Positive := Lengths'Length;
      F_One : W.Family (M);
      F_Offset : W.Family (M);
      F_Max : W.Family (M);
      One : W.Natural_Array (1 .. M);
      Offset : W.Natural_Array (7 .. 6 + M);
      Max_Bound : W.Natural_Array (Positive'Last - M + 1 .. Positive'Last);
      C_One, C_Offset, C_Max : G.Big_Integer;
      Expected_Count : Natural := 1;
      Word_Start : Natural := Expected'First;
      Days : Natural := 0;
   begin
      Check (M in 1 .. 4, Label_Text & " month count");
      for I in Lengths'Range loop
         Check (Lengths (I) in 2 .. 3, Label_Text & " month length");
      end loop;
      for P in Expected'Range loop
         if Expected (P) = ';' then
            Expected_Count := Expected_Count + 1;
         end if;
      end loop;
      Check (Expected_Count in 1 .. 1_266, Label_Text & " oracle word count");

      for I in 1 .. M loop
         One (I) := Lengths (Lengths'First + I - 1);
         Offset (6 + I) := One (I);
         Max_Bound (Positive'Last - M + I) := One (I);
         Days := Days + One (I);
      end loop;
      Check (Days <= 12, Label_Text & " day bound");

      W.Build (F_One, One);
      W.Build (F_Offset, Offset);
      W.Build (F_Max, Max_Bound);
      W.Count (F_One, C_One);
      W.Count (F_Offset, C_Offset);
      W.Count (F_Max, C_Max);
      Check (C_One = G.Make (Natural'Image (Expected_Count)),
             Label_Text & " exact Count");
      Check (C_Offset = C_One, Label_Text & " offset Count");
      Check (C_Max = C_One, Label_Text & " Positive'Last Count");

      for Rank in 1 .. Expected_Count loop
         declare
            Separator : constant Natural :=
              Ada.Strings.Fixed.Index (Expected, ";", From => Word_Start);
            Word_End : constant Natural :=
              (if Rank = Expected_Count then Expected'Last else Separator - 1);
            Word : constant String := Expected (Word_Start .. Word_End);
            R : constant G.Big_Integer := G.Make (Natural'Image (Rank));
            A_One : constant W.Natural_Array := W.Unrank (F_One, R);
            A_Offset : constant W.Natural_Array := W.Unrank (F_Offset, R);
            A_Max : constant W.Natural_Array := W.Unrank (F_Max, R);
         begin
            Check (Encode (A_One) = Word,
                   Label_Text & " exact lexicographic rank" & Natural'Image (Rank));
            Check (Encode (A_Offset) = Word,
                   Label_Text & " shifted lower-bound rank" & Natural'Image (Rank));
            Check (Encode (A_Max) = Word,
                   Label_Text & " Positive'Last lower-bound rank" & Natural'Image (Rank));
            Words := Words + 1;
            Rank_Comparisons := Rank_Comparisons + 3;
            if Rank < Expected_Count then
               Word_Start := Separator + 1;
            end if;
         end;
      end loop;

      Expect_Rank_CE (F_One, G.Make ("0"), Label_Text & " standard");
      Expect_Rank_CE
        (F_One, G.Make (Natural'Image (Expected_Count + 1)), Label_Text & " standard");
      Expect_Rank_CE (F_Offset, G.Make ("0"), Label_Text & " offset");
      Expect_Rank_CE
        (F_Offset, G.Make (Natural'Image (Expected_Count + 1)), Label_Text & " offset");
      Expect_Rank_CE (F_Max, G.Make ("0"), Label_Text & " maximum-bound");
      Expect_Rank_CE
        (F_Max, G.Make (Natural'Image (Expected_Count + 1)), Label_Text & " maximum-bound");
      Families := Families + 1;
   end Check_Family;

   File : File_Type;
begin
   Open (File, In_File, "qa/issue29/v198_families.txt");
   while not End_Of_File (File) loop
      declare
         Line : constant String := Get_Line (File);
      begin
         if Line'Length > 0 and then Line (Line'First) /= '#' then
            declare
               Separator : constant Natural :=
                 Ada.Strings.Fixed.Index (Line, "|");
               Left : constant String := Line (Line'First .. Separator - 1);
               Expected : constant String := Line (Separator + 1 .. Line'Last);
               M : Natural := 1;
               Start : Natural := Left'First;
            begin
               for P in Left'Range loop
                  if Left (P) = ',' then
                     M := M + 1;
                  end if;
               end loop;
               declare
                  Lengths : W.Natural_Array (1 .. M);
               begin
                  for I in 1 .. M loop
                     declare
                        Comma : constant Natural :=
                          Ada.Strings.Fixed.Index (Left, ",", From => Start);
                        Finish : constant Natural :=
                          (if I = M then Left'Last else Comma - 1);
                     begin
                        Lengths (I) := Natural'Value (Left (Start .. Finish));
                        if I < M then
                           Start := Comma + 1;
                        end if;
                     end;
                  end loop;
                  Check_Family (Lengths, Expected, Left);
               end;
            end;
         end if;
      end;
   end loop;
   Close (File);
   Check (Families = 30, "all 30 length vectors processed");
   Check (Words = 3_424, "all 3,424 exact words processed");
   Check (Rank_Comparisons = 10_272, "all three-bound rank comparisons processed");
   Check (Checks > 10_000, "substantive assertion total");
   Put_Line ("V198_FAMILIES=" & Natural'Image (Families));
   Put_Line ("V198_EXACT_WORDS=" & Natural'Image (Words));
   Put_Line ("V198_NATIVE_RANK_COMPARISONS=" & Natural'Image (Rank_Comparisons));
   Put_Line ("V198_ASSERTIONS=" & Natural'Image (Checks));
   Put_Line ("V198_EXHAUSTIVE_1_TO_4_MONTH_ORACLE_PASS_ZERO_F");
end Issue29_V198_Small_Oracle;
