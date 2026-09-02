with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Strings.Wide_Wide_Unbounded;
with Ada.Wide_Wide_Text_IO;
with Exact_Math;
with Monster_Bootstrap;
with Normative_Oracle;
with Source_Language_Catalog;
with Stage01_Fixtures;

procedure Stage01_Tests is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Ada.Strings.Wide_Wide_Unbounded;
   use Exact_Math;
   use Normative_Oracle;
   use type Monster_Bootstrap.Monster_Status;

   procedure Assert_True (Condition : Boolean; Message : Wide_Wide_String) is
   begin
      if not Condition then
         Ada.Wide_Wide_Text_IO.Put_Line ("విఫలం: " & Message);
         raise Program_Error;
      end if;
   end Assert_True;

   function B (N : Integer) return Big_Integer is (To_Big_Integer (N));

begin
   Ada.Wide_Wide_Text_IO.Put_Line ("Stage 1 పరీక్షలు ప్రారంభమయ్యాయి");

   Assert_True (Stage01_Fixtures.Tablets - Stage01_Fixtures.Foundation = B (14_777_149),
                "మూల దిన స్థిరాంకాల మధ్య దూరం");

   Assert_True (Save (B (1)) = B (1), "SAVE ఒకటి");
   Assert_True (Save (M - B (1)) = M - B (1), "SAVE గరిష్ఠానికి ముందు");
   Assert_True (Save (M) = M, "SAVE M");
   Assert_True (Save (M + B (1)) = B (1), "SAVE M తర్వాత ఒకటి");
   Assert_True (Save (B (2) * M) = M, "SAVE రెండు M");

   Assert_True (Day_Count (Foundation_Day) = B (1), "స్థాపన దిన గణన");
   Assert_True (Day_Count (Foundation_Day - B (1)) = B (2), "స్థాపనకు ముందు దిన గణన");
   Assert_True (Day_Count (Foundation_Day + B (1)) = B (3), "స్థాపనకు తర్వాత దిన గణన");

   declare
      C : constant Work_Counts := Compute_Work_Counts (Foundation_Day, Foundation_Day);
   begin
      Assert_True (C.Distance = B (1), "అదే దినానికి దూరం ఒకటి");
      Assert_True (C.Direction = 2, "అదే దినానికి దిశ రెండు");
   end;

   declare
      S : constant Stone_Table := Build_Stones;
   begin
      Assert_True (S (1).Wheat = B (17) and then S (1).Red = B (101),
                   "మొదటి రాయి వరుస");
      Assert_True (S (2).Wheat = Stage01_Fixtures.Stone_2_Wheat, "రెండవ గోధుమ రాయి");
      Assert_True (S (2).Barley = Stage01_Fixtures.Stone_2_Barley, "రెండవ యవ రాయి");
      Assert_True (S (2).Salt = Stage01_Fixtures.Stone_2_Salt, "రెండవ ఉప్పు రాయి");
      Assert_True (S (2).Bitter = Stage01_Fixtures.Stone_2_Bitter, "రెండవ చేదు రాయి");
      Assert_True (S (2).Red = Stage01_Fixtures.Stone_2_Red, "రెండవ ఎరుపు రాయి");
   end;

   declare
      O1   : constant Bowl_Order := Bowl_Order_From_Number (1);
      O720 : constant Bowl_Order := Bowl_Order_From_Number (720);
   begin
      Assert_True (O1 = (1, 2, 3, 4, 5, 6), "మొదటి కుండల క్రమం");
      Assert_True (O720 = (6, 5, 4, 3, 2, 1), "720వ కుండల క్రమం");
   end;

   declare
      S : constant Answer_Stream := (First => B (1), Direction_Step => 1);
   begin
      Assert_True (Choose_Rank (S, B (10)) = B (1), "చిన్న ఎంపిక మొదటి స్థానం");
      Assert_True (Choose_Rank ((First => M, Direction_Step => 1), M) = M,
                   "చిన్న ఎంపిక M సరిహద్దు");
      Assert_True (Choose_Rank (S, M + B (1)) = M + B (1),
                   "విస్తృత ఎంపిక M తర్వాత సరిహద్దు");
   end;

   Assert_True (Source_Language_Catalog.Cutlet_Count = 17, "కట్లెట్ పేరు సంఖ్య");
   Assert_True (Source_Language_Catalog.Month_Count = 47, "నెల పేరు సంఖ్య");

   for I in Source_Language_Catalog.Cutlet_Canonical_Index loop
      Assert_True (Length (Source_Language_Catalog.Cutlet_Name (I)) > 0,
                   "ఖాళీ కాని కట్లెట్ పేరు");
      for J in Source_Language_Catalog.Cutlet_Canonical_Index loop
         if I < J then
            Assert_True
              (Source_Language_Catalog.Cutlet_Name (I) /= Source_Language_Catalog.Cutlet_Name (J),
               "కట్లెట్ పేర్లు వేర్వేరు");
         end if;
      end loop;
   end loop;

   for I in Source_Language_Catalog.Month_Canonical_Index loop
      Assert_True (Length (Source_Language_Catalog.Month_Name (I)) > 0,
                   "ఖాళీ కాని నెల పేరు");
      for J in Source_Language_Catalog.Month_Canonical_Index loop
         if I < J then
            Assert_True
              (Source_Language_Catalog.Month_Name (I) /= Source_Language_Catalog.Month_Name (J),
               "నెల పేర్లు వేర్వేరు");
         end if;
      end loop;
   end loop;

   declare
      Context : Monster_Bootstrap.Monster_Context :=
        Monster_Bootstrap.New_Context (Foundation_Day, Foundation_Day);
   begin
      Monster_Bootstrap.Execute_Bootstrap (Context);
      Assert_True (Context.Status = Monster_Bootstrap.Completed, "ప్రాథమిక సందర్భం పూర్తి స్థితి");
      Assert_True (Context.Commit_Token = 1, "ప్రాథమిక commit టోకెన్");
      Assert_True (Context.Metrics.Dispatch_Count = 4, "ప్రాథమిక పంపిణీ లెక్క");
   end;

   declare
      R1 : constant Sauce_Result := Sauce (Foundation_Day, Foundation_Day);
      R2 : constant Sauce_Result := Sauce (Foundation_Day, Foundation_Day);
   begin
      Assert_True (R1.Bowls = R2.Bowls, "రసం పునరావృత నిర్ణయాత్మకత");
      Assert_True (R1.Order_At_Drop_46 = R2.Order_At_Drop_46,
                   "46వ చుక్క క్రమం పునరావృత నిర్ణయాత్మకత");
   end;

   Ada.Wide_Wide_Text_IO.Put_Line ("Stage 1 పరీక్షలు అన్నీ విజయవంతమయ్యాయి");
end Stage01_Tests;
