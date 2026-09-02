with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Strings.Wide_Wide_Unbounded;
with Ada.Wide_Wide_Text_IO;
with Exact_Math;
with Monster_Bootstrap;
with Normative_Oracle;
with Source_Language_Catalog;
with Stage01_Catalog_Fixtures;
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
   Assert_True
     (Source_Language_Catalog.Catalog_Version = "1.0.0-stage01-frozen",
      "మూల భాష కేటలాగ్ స్థిర సంచిక గుర్తింపు");

   for I in Source_Language_Catalog.Cutlet_Canonical_Index loop
      Assert_True (Length (Source_Language_Catalog.Cutlet_Name (I)) > 0,
                   "ఖాళీ కాని కట్లెట్ పేరు");
      Assert_True
        (Source_Language_Catalog.Cutlet_Name (I) = Stage01_Catalog_Fixtures.Cutlets (I),
         "కట్లెట్ canonicalIndex కు స్థిరమైన తెలుగు పేరు");
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
      Assert_True
        (Source_Language_Catalog.Month_Name (I) = Stage01_Catalog_Fixtures.Months (I),
         "నెల canonicalIndex కు స్థిరమైన తెలుగు పేరు");
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
      First_Context : Monster_Bootstrap.Monster_Context :=
        Monster_Bootstrap.New_Context (Foundation_Day, Foundation_Day);
      Second_Context : Monster_Bootstrap.Monster_Context :=
        Monster_Bootstrap.New_Context (Foundation_Day + B (1), Foundation_Day - B (1));
   begin
      Monster_Bootstrap.Execute_Bootstrap (First_Context);
      Assert_True (Second_Context.Status = Monster_Bootstrap.New_State,
                   "ఒక అమలు పిలుపు మరొక సందర్భం స్థితిని మార్చదు");
      Assert_True (Second_Context.Commit_Token = 0,
                   "వేరే సందర్భం అంగీకార గుర్తు స్వతంత్రంగా ఉంటుంది");
      Assert_True (Second_Context.Metrics.Dispatch_Count = 0,
                   "వేరే సందర్భం కొలమానాలు స్వతంత్రంగా ఉంటాయి");

      Monster_Bootstrap.Execute_Bootstrap (Second_Context);
      Assert_True (First_Context.Status = Monster_Bootstrap.Completed,
                   "రెండవ అమలు పిలుపు మొదటి సందర్భాన్ని తిరిగి మార్చదు");
      Assert_True (First_Context.Commit_Token = 1,
                   "మొదటి సందర్భం అంగీకరించిన స్థితి నిలిచివుంటుంది");
      Assert_True (First_Context.Metrics.Dispatch_Count = 4,
                   "మొదటి సందర్భం కొలమానాలకు పంచుకున్న మార్పు లేదు");
   end;

   declare
      Failed_Context : Monster_Bootstrap.Monster_Context :=
        Monster_Bootstrap.New_Context (Foundation_Day, Foundation_Day);
      Failure_Observed : Boolean := False;
   begin
      Failed_Context.Phase := Monster_Bootstrap.Boot_Failed;
      begin
         Monster_Bootstrap.Execute_Bootstrap (Failed_Context);
      exception
         when Program_Error =>
            Failure_Observed := True;
      end;
      Assert_True (Failure_Observed, "విఫల సందర్భం స్పష్టమైన దోషాన్ని ఇస్తుంది");

      declare
         Fresh_Context : Monster_Bootstrap.Monster_Context :=
           Monster_Bootstrap.New_Context (Foundation_Day, Foundation_Day);
      begin
         Monster_Bootstrap.Execute_Bootstrap (Fresh_Context);
         Assert_True (Fresh_Context.Status = Monster_Bootstrap.Completed,
                      "విఫల అమలు పిలుపు తరువాత కొత్త సందర్భం పరిశుభ్రంగా ఉంటుంది");
         Assert_True (Fresh_Context.Metrics.Error_Count = 0,
                      "విఫల అమలు పిలుపు దోష స్థితి కొత్త సందర్భానికి లీక్ కాదు");
      end;
   end;

   declare
      Original : constant Unbounded_Wide_Wide_String :=
        Source_Language_Catalog.Cutlet_Name (1);
      Local_Copy : Unbounded_Wide_Wide_String := Original;
      Original_Month : constant Unbounded_Wide_Wide_String :=
        Source_Language_Catalog.Month_Name (1);
      Local_Month_Copy : Unbounded_Wide_Wide_String := Original_Month;
   begin
      Append (Local_Copy, " పరీక్ష");
      Append (Local_Month_Copy, " పరీక్ష");
      Assert_True
        (Source_Language_Catalog.Cutlet_Name (1) = Original,
         "కేటలాగ్ నుండి వచ్చిన స్థానిక ప్రతిని మార్చినా స్థిర కేటలాగ్ మారదు");
      Assert_True
        (Source_Language_Catalog.Month_Name (1) = Original_Month,
         "నెల పేరు స్థానిక ప్రతిని మార్చినా స్థిర కేటలాగ్ మారదు");
   end;

   declare
      First_Table  : Stone_Table := Build_Stones;
      Second_Table : constant Stone_Table := Build_Stones;
      Third_Table  : constant Stone_Table := Build_Stones;
   begin
      First_Table (1).Wheat := B (999);
      Assert_True (Second_Table (1).Wheat = B (17),
                   "నార్మేటివ్ సూచిక స్థానిక పట్టికలు పంచుకున్న మార్పు స్థితి కావు");
      Assert_True (Third_Table (1).Wheat = B (17),
                   "గత పిలుపు మార్పు వల్ల కొత్త రాయి పట్టిక మారదు");
   end;

   declare
      R1 : constant Sauce_Result := Sauce (Foundation_Day, Foundation_Day);
      Interleaved : constant Sauce_Result :=
        Sauce (Foundation_Day + B (1), Foundation_Day - B (1));
      R2 : constant Sauce_Result := Sauce (Foundation_Day, Foundation_Day);
   begin
      Assert_True (Interleaved.Bowls (1) >= B (1),
                   "మధ్యలో వేరే నార్మేటివ్ పిలుపు పూర్తవుతుంది");
      Assert_True (R1.Bowls = R2.Bowls, "రసం పునరావృత నిర్ణయాత్మకత");
      Assert_True (R1.Order_At_Drop_46 = R2.Order_At_Drop_46,
                   "మధ్య పిలుపు తరువాత 46వ చుక్క క్రమం మారదు");
   end;

   Ada.Wide_Wide_Text_IO.Put_Line ("Stage 1 పరీక్షలు అన్నీ విజయవంతమయ్యాయి");
end Stage01_Tests;
