with Ada.Text_IO;
with Ada.Integer_Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers;
with Canonical_Full_Weave_GMP_V164;
with Canonical_Wide_Rank_GMP_V164;
with GNATCOLL.GMP.Integers;

procedure Issue29_V199_Real_Weave is
   package W renames Canonical_Full_Weave_GMP_V164;
   package P renames Canonical_Wide_Rank_GMP_V164;
   package G renames GNATCOLL.GMP.Integers;
   package Std renames Ada.Numerics.Big_Numbers.Big_Integers;
   use Ada.Text_IO;
   use type G.Big_Integer;
   use type W.Natural_Array;
   F : W.Family (45);
   Input : File_Type;
   L : W.Natural_Array (1 .. 45);
   Expected : W.Natural_Array (1 .. 4244);
   N, Rank : G.Big_Integer;
   Dir, Value : Integer;
begin
   Open (Input, In_File, "input/lengths.txt");
   for J in L'Range loop
      Ada.Integer_Text_IO.Get (Input, Value);
      L (J) := Natural (Value);
   end loop;
   Close (Input);
   Open (Input, In_File, "input/word.txt");
   for J in Expected'Range loop
      Ada.Integer_Text_IO.Get (Input, Value);
      Expected (J) := Natural (Value);
   end loop;
   Close (Input);
   W.Build (F, L);
   W.Count (F, N);
   Open (Input, In_File, "input/count.txt");
   if N /= G.Make (Get_Line (Input)) then
      raise Program_Error with "root count differs";
   end if;
   Close (Input);
   Put_Line ("V199_ROOT_COUNT_PASS");
   Open (Input, In_File, "input/ring.txt");
   declare
      First : constant Std.Big_Integer := Std.From_String (Get_Line (Input));
   begin
      Ada.Integer_Text_IO.Get (Input, Dir);
      P.Choose_Rank (First, Dir, N, Rank);
   end;
   Close (Input);
   Open (Input, In_File, "input/rank.txt");
   if Rank /= G.Make (Get_Line (Input)) then
      raise Program_Error with "rank differs";
   end if;
   Close (Input);
   Put_Line ("V199_SOURCE_RING_RANK_PASS");
   declare
      Word : constant W.Natural_Array := W.Unrank (F, Rank);
      Output : File_Type;
   begin
      if Word'Length /= Expected'Length then
         raise Program_Error with "length differs";
      end if;
      Create (Output, Out_File, "actual-word.txt");
      for J in Expected'Range loop
         declare
            Actual : constant Natural := Word (Word'First + J - 1);
         begin
            Ada.Integer_Text_IO.Put (Output, Actual, Width => 0);
            New_Line (Output);
            if Actual /= Expected (J) then
               Put_Line ("V199_FIRST_DIFFERENCE" & Natural'Image (J) &
                 " EXPECTED" & Natural'Image (Expected (J)) &
                 " ACTUAL" & Natural'Image (Actual));
               Close (Output);
               raise Program_Error with "weave differs";
            end if;
         end;
      end loop;
      Close (Output);
   end;
   Put_Line ("V199_FULL_WORD_PASS SYMBOLS=4244 ZERO_F=1");
end Issue29_V199_Real_Weave;
