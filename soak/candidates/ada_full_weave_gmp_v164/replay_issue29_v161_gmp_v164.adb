with Ada.Command_Line;
with Ada.Text_IO;
with GNATCOLL.GMP.Integers;
with Canonical_Full_Weave_GMP_V164;

--  QA v164: REPLAY ONLY of already archived intermediate selector data v161.
--  NO Sauce, Calendar_Date, F(c,t), target date or native Soak invocation.
procedure Replay_Issue29_V161_GMP_V164 is
   package CW renames Canonical_Full_Weave_GMP_V164;
   package G renames GNATCOLL.GMP.Integers;

   File : Ada.Text_IO.File_Type;
begin
   if Ada.Command_Line.Argument_Count /= 1 then
      raise Constraint_Error with "expected a single pinned two-line selector file";
   end if;

   Ada.Text_IO.Open
     (File, Ada.Text_IO.In_File, Ada.Command_Line.Argument (1));
   declare
      Lengths_CSV : constant String := Ada.Text_IO.Get_Line (File);
      Rank_Hex : constant String := Ada.Text_IO.Get_Line (File);
      Lengths : CW.Natural_Array (1 .. 45) := (others => 0);
      Segment : Positive := 1;
      Segment_Start : Positive := Lengths_CSV'First;
   begin
      Ada.Text_IO.Close (File);
      for I in Lengths_CSV'Range loop
         if Lengths_CSV (I) = ',' then
            if I <= Segment_Start or Segment >= 45 then
               raise Constraint_Error with "invalid pinned length CSV separator";
            end if;
            Lengths (Segment) :=
              Natural'Value (Lengths_CSV (Segment_Start .. I - 1));
            Segment := Segment + 1;
            Segment_Start := I + 1;
         end if;
      end loop;
      if Segment /= 45 or Segment_Start > Lengths_CSV'Last then
         raise Constraint_Error with "not exactly 45 pinned month lengths";
      end if;
      Lengths (45) :=
        Natural'Value (Lengths_CSV (Segment_Start .. Lengths_CSV'Last));

      if Rank_Hex'Length < 1
        or else Rank_Hex'Length > 10_000
      then
         raise Constraint_Error with "pinned global rank hex invalid length";
      end if;

      declare
         F : CW.Family (45);
         Rank : constant G.Big_Integer := G.Make (Rank_Hex, Base => 16);
         Count : G.Big_Integer;
      begin
         CW.Build (F, Lengths);
         CW.Count (F, Count);

         declare
            Word : constant CW.Natural_Array := CW.Unrank (F, Rank);
         begin
            if Word'Length /= 4_244 then
               raise Program_Error with "pinned recorded length is not 4244";
            end if;
            Ada.Text_IO.Put_Line
              ("V164_PINNED_V161_COUNT_HEX=" & G.Image (Count, Base => 16));
            Ada.Text_IO.Put ("V164_PINNED_V161_WEAVE_CSV=");
            for P in Word'Range loop
               if P /= Word'First then
                  Ada.Text_IO.Put (",");
               end if;
               declare
                  N_Text : constant String := Natural'Image (Word (P));
               begin
                  Ada.Text_IO.Put (N_Text (N_Text'First + 1 .. N_Text'Last));
               end;
            end loop;
            Ada.Text_IO.New_Line;
            Ada.Text_IO.Put_Line
              ("V164_PINNED_V161_INTERMEDIATE_REPLAY_COMPLETE_NO_NEW_F");
         end;
      end;
   end;
end Replay_Issue29_V161_GMP_V164;
