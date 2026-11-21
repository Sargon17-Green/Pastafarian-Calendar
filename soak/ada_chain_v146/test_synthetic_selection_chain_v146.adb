with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Legal_Month_Weave_DP;
with Synthetic_Rank_Stream_V145;

--  v146 ONLY SYNTHETIC bowls, ranks, month counts and label sequences.
--  This program does NOT import or call Normative_Oracle, Calendar_Date,
--  original F(c,t), nor any original date-converter input.
procedure Test_Synthetic_Selection_Chain_V146 is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Legal_Month_Weave_DP;
   use Synthetic_Rank_Stream_V145;

   Alphabet : constant String := "123456789ABC";
   Checked, Wide_Checked : Natural := 0;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         raise Program_Error with Message;
      end if;
   end Require;

   function Labels_As_Text (Sequence : Month_Sequence) return String is
      Result : String (1 .. Sequence'Length);
   begin
      for I in Sequence'Range loop
         Require (Sequence (I) in Alphabet'Range,
                  "out of range synthetic month label");
         Result (I) := Alphabet (Sequence (I));
      end loop;
      return Result;
   end Labels_As_Text;

   procedure Check
     (Case_Id : String;
      Lengths : Month_Lengths;
      Bowls : Bowl_Array;
      Order : Bowl_Order;
      Queried : Positive;
      Seal : Natural;
      Expected_Count, Expected_First : String;
      Expected_Direction : Integer;
      Expected_Rank, Expected_Text : String)
   is
      N : constant Big_Integer := Count (Lengths);
      Stream : constant Answer_Stream :=
        Ask_Bowl (Bowls, Order, Queried, Seal);
      Global_Rank : constant Big_Integer := Choose_Rank (Stream, N);
      Output_Labels : constant Month_Sequence :=
        Unrank (Lengths, Global_Rank);
   begin
      Require (N = From_String (Expected_Count),
               "source-independent family count differs in " & Case_Id);
      Require (Stream.First = From_String (Expected_First)
               and then Stream.Direction_Step = Expected_Direction,
               "source-independent Ask_Bowl differs in " & Case_Id);
      Require (Global_Rank = From_String (Expected_Rank),
               "source-independent global rank differs in " & Case_Id);
      Require (Labels_As_Text (Output_Labels) = Expected_Text,
               "FULL-SEQUENCE label mismatch in " & Case_Id);
      Require (Rank (Lengths, Output_Labels) = Global_Rank,
               "inverse rank mismatch in " & Case_Id);
      if N > Synthetic_Rank_Stream_V145.M then
         Wide_Checked := Wide_Checked + 1;
      end if;
      Checked := Checked + 1;
   end Check;

begin
   -- V146_FIXTURE_BEGIN two4_b1
   Check
     (Case_Id => "two4_b1",
      Lengths => Month_Lengths'(1 => 4, 2 => 4),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("2"), 3 => From_String ("3"), 4 => From_String ("4"), 5 => From_String ("5"), 6 => From_String ("6")),
      Order => Bowl_Order'(1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6),
      Queried => 4, Seal => 32,
      Expected_Count => "20",
      Expected_First => "48016",
      Expected_Direction => -1,
      Expected_Rank => "16",
      Expected_Text => "12122112");
   -- V146_FIXTURE_END two4_b1

   -- V146_FIXTURE_BEGIN two4_b2
   Check
     (Case_Id => "two4_b2",
      Lengths => Month_Lengths'(1 => 4, 2 => 4),
      Bowls => Bowl_Array'(1 => From_String ("13"), 2 => From_String ("17"), 3 => From_String ("19"), 4 => From_String ("23"), 5 => From_String ("29"), 6 => From_String ("31")),
      Order => Bowl_Order'(1 => 6, 2 => 5, 3 => 4, 4 => 3, 5 => 2, 6 => 1),
      Queried => 4, Seal => 32,
      Expected_Count => "20",
      Expected_First => "59129",
      Expected_Direction => 1,
      Expected_Rank => "9",
      Expected_Text => "11221212");
   -- V146_FIXTURE_END two4_b2

   -- V146_FIXTURE_BEGIN two4_b3
   Check
     (Case_Id => "two4_b3",
      Lengths => Month_Lengths'(1 => 4, 2 => 4),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("170141183460469231731687303715884105727"), 3 => From_String ("170141183460469231731687303715884105726"), 4 => From_String ("17"), 5 => From_String ("170141183460469231731687303715884105720"), 6 => From_String ("19")),
      Order => Bowl_Order'(1 => 3, 2 => 6, 3 => 2, 4 => 4, 5 => 1, 6 => 5),
      Queried => 4, Seal => 32,
      Expected_Count => "20",
      Expected_First => "53111",
      Expected_Direction => 1,
      Expected_Rank => "11",
      Expected_Text => "12111222");
   -- V146_FIXTURE_END two4_b3

   -- V146_FIXTURE_BEGIN two4_b4
   Check
     (Case_Id => "two4_b4",
      Lengths => Month_Lengths'(1 => 4, 2 => 4),
      Bowls => Bowl_Array'(1 => From_String ("0"), 2 => From_String ("0"), 3 => From_String ("0"), 4 => From_String ("0"), 5 => From_String ("0"), 6 => From_String ("0")),
      Order => Bowl_Order'(1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6, 6 => 1),
      Queried => 1, Seal => 0,
      Expected_Count => "20",
      Expected_First => "32761",
      Expected_Direction => -1,
      Expected_Rank => "1",
      Expected_Text => "11112222");
   -- V146_FIXTURE_END two4_b4

   -- V146_FIXTURE_BEGIN two4_b5
   Check
     (Case_Id => "two4_b5",
      Lengths => Month_Lengths'(1 => 4, 2 => 4),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("170141183460469231731687303715884105727"), 3 => From_String ("2"), 4 => From_String ("170141183460469231731687303715884105725"), 5 => From_String ("3"), 6 => From_String ("170141183460469231731687303715884105724")),
      Order => Bowl_Order'(1 => 2, 2 => 4, 3 => 6, 4 => 1, 5 => 3, 6 => 5),
      Queried => 6, Seal => 33,
      Expected_Count => "20",
      Expected_First => "44733",
      Expected_Direction => -1,
      Expected_Rank => "13",
      Expected_Text => "12112212");
   -- V146_FIXTURE_END two4_b5

   -- V146_FIXTURE_BEGIN two4_b6
   Check
     (Case_Id => "two4_b6",
      Lengths => Month_Lengths'(1 => 4, 2 => 4),
      Bowls => Bowl_Array'(1 => From_String ("170141183460469231731687303715884105627"), 2 => From_String ("170141183460469231731687303715884105628"), 3 => From_String ("12345"), 4 => From_String ("987654321"), 5 => From_String ("10"), 6 => From_String ("20")),
      Order => Bowl_Order'(1 => 5, 2 => 1, 3 => 6, 4 => 3, 5 => 2, 6 => 4),
      Queried => 2, Seal => 31,
      Expected_Count => "20",
      Expected_First => "176790136259",
      Expected_Direction => 1,
      Expected_Rank => "19",
      Expected_Text => "12212112");
   -- V146_FIXTURE_END two4_b6

   -- V146_FIXTURE_BEGIN three454_b1
   Check
     (Case_Id => "three454_b1",
      Lengths => Month_Lengths'(1 => 4, 2 => 5, 3 => 4),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("2"), 3 => From_String ("3"), 4 => From_String ("4"), 5 => From_String ("5"), 6 => From_String ("6")),
      Order => Bowl_Order'(1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6),
      Queried => 4, Seal => 32,
      Expected_Count => "3499",
      Expected_First => "48016",
      Expected_Direction => -1,
      Expected_Rank => "2529",
      Expected_Text => "1223112332123");
   -- V146_FIXTURE_END three454_b1

   -- V146_FIXTURE_BEGIN three454_b2
   Check
     (Case_Id => "three454_b2",
      Lengths => Month_Lengths'(1 => 4, 2 => 5, 3 => 4),
      Bowls => Bowl_Array'(1 => From_String ("13"), 2 => From_String ("17"), 3 => From_String ("19"), 4 => From_String ("23"), 5 => From_String ("29"), 6 => From_String ("31")),
      Order => Bowl_Order'(1 => 6, 2 => 5, 3 => 4, 4 => 3, 5 => 2, 6 => 1),
      Queried => 4, Seal => 32,
      Expected_Count => "3499",
      Expected_First => "59129",
      Expected_Direction => 1,
      Expected_Rank => "3145",
      Expected_Text => "1232123213123");
   -- V146_FIXTURE_END three454_b2

   -- V146_FIXTURE_BEGIN three454_b3
   Check
     (Case_Id => "three454_b3",
      Lengths => Month_Lengths'(1 => 4, 2 => 5, 3 => 4),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("170141183460469231731687303715884105727"), 3 => From_String ("170141183460469231731687303715884105726"), 4 => From_String ("17"), 5 => From_String ("170141183460469231731687303715884105720"), 6 => From_String ("19")),
      Order => Bowl_Order'(1 => 3, 2 => 6, 3 => 2, 4 => 4, 5 => 1, 6 => 5),
      Queried => 4, Seal => 32,
      Expected_Count => "3499",
      Expected_First => "53111",
      Expected_Direction => 1,
      Expected_Rank => "626",
      Expected_Text => "1122213323123");
   -- V146_FIXTURE_END three454_b3

   -- V146_FIXTURE_BEGIN three454_b4
   Check
     (Case_Id => "three454_b4",
      Lengths => Month_Lengths'(1 => 4, 2 => 5, 3 => 4),
      Bowls => Bowl_Array'(1 => From_String ("0"), 2 => From_String ("0"), 3 => From_String ("0"), 4 => From_String ("0"), 5 => From_String ("0"), 6 => From_String ("0")),
      Order => Bowl_Order'(1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6, 6 => 1),
      Queried => 1, Seal => 0,
      Expected_Count => "3499",
      Expected_First => "32761",
      Expected_Direction => -1,
      Expected_Rank => "1270",
      Expected_Text => "1211322133223");
   -- V146_FIXTURE_END three454_b4

   -- V146_FIXTURE_BEGIN three454_b5
   Check
     (Case_Id => "three454_b5",
      Lengths => Month_Lengths'(1 => 4, 2 => 5, 3 => 4),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("170141183460469231731687303715884105727"), 3 => From_String ("2"), 4 => From_String ("170141183460469231731687303715884105725"), 5 => From_String ("3"), 6 => From_String ("170141183460469231731687303715884105724")),
      Order => Bowl_Order'(1 => 2, 2 => 4, 3 => 6, 4 => 1, 5 => 3, 6 => 5),
      Queried => 6, Seal => 33,
      Expected_Count => "3499",
      Expected_First => "44733",
      Expected_Direction => -1,
      Expected_Rank => "2745",
      Expected_Text => "1223313221123");
   -- V146_FIXTURE_END three454_b5

   -- V146_FIXTURE_BEGIN three454_b6
   Check
     (Case_Id => "three454_b6",
      Lengths => Month_Lengths'(1 => 4, 2 => 5, 3 => 4),
      Bowls => Bowl_Array'(1 => From_String ("170141183460469231731687303715884105627"), 2 => From_String ("170141183460469231731687303715884105628"), 3 => From_String ("12345"), 4 => From_String ("987654321"), 5 => From_String ("10"), 6 => From_String ("20")),
      Order => Bowl_Order'(1 => 5, 2 => 1, 3 => 6, 4 => 3, 5 => 2, 6 => 4),
      Queried => 2, Seal => 31,
      Expected_Count => "3499",
      Expected_First => "176790136259",
      Expected_Direction => 1,
      Expected_Rank => "1662",
      Expected_Text => "1213112223323");
   -- V146_FIXTURE_END three454_b6

   -- V146_FIXTURE_BEGIN eight16_b1
   Check
     (Case_Id => "eight16_b1",
      Lengths => Month_Lengths'(1 => 16, 2 => 16, 3 => 16, 4 => 16, 5 => 16, 6 => 16, 7 => 16, 8 => 16),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("2"), 3 => From_String ("3"), 4 => From_String ("4"), 5 => From_String ("5"), 6 => From_String ("6")),
      Order => Bowl_Order'(1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6),
      Queried => 4, Seal => 32,
      Expected_Count => "8484570857678108456252429355893789531769120343894823957866334278987787485159718203651318043348194800",
      Expected_First => "48016",
      Expected_Direction => -1,
      Expected_Rank => "1389881395137815622717978425805533129931594124937546051552717474416976245666397071",
      Expected_Text => "1111111111111111232454677643524463238843737552532738683786582267" &
        "2752674548685327445828342558447328733366577665426824673868545678");
   -- V146_FIXTURE_END eight16_b1

   -- V146_FIXTURE_BEGIN eight16_b2
   Check
     (Case_Id => "eight16_b2",
      Lengths => Month_Lengths'(1 => 16, 2 => 16, 3 => 16, 4 => 16, 5 => 16, 6 => 16, 7 => 16, 8 => 16),
      Bowls => Bowl_Array'(1 => From_String ("13"), 2 => From_String ("17"), 3 => From_String ("19"), 4 => From_String ("23"), 5 => From_String ("29"), 6 => From_String ("31")),
      Order => Bowl_Order'(1 => 6, 2 => 5, 3 => 4, 4 => 3, 5 => 2, 6 => 1),
      Queried => 4, Seal => 32,
      Expected_Count => "8484570857678108456252429355893789531769120343894823957866334278987787485159718203651318043348194800",
      Expected_First => "59129",
      Expected_Direction => 1,
      Expected_Rank => "1711696559150626658848938085890928997830902930000630631771755333640951895846610682",
      Expected_Text => "1111111111111111233344567242748286267342465575545782468777536325" &
        "5477833822645862433672468765334368678528547833252523847864566788");
   -- V146_FIXTURE_END eight16_b2

   -- V146_FIXTURE_BEGIN eight16_b3
   Check
     (Case_Id => "eight16_b3",
      Lengths => Month_Lengths'(1 => 16, 2 => 16, 3 => 16, 4 => 16, 5 => 16, 6 => 16, 7 => 16, 8 => 16),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("170141183460469231731687303715884105727"), 3 => From_String ("170141183460469231731687303715884105726"), 4 => From_String ("17"), 5 => From_String ("170141183460469231731687303715884105720"), 6 => From_String ("19")),
      Order => Bowl_Order'(1 => 3, 2 => 6, 3 => 2, 4 => 4, 5 => 1, 6 => 5),
      Queried => 4, Seal => 32,
      Expected_Count => "8484570857678108456252429355893789531769120343894823957866334278987787485159718203651318043348194800",
      Expected_First => "53111",
      Expected_Direction => 1,
      Expected_Rank => "1537487360893084442834175538945358040466682147713239507010952692694808782851592056",
      Expected_Text => "1111111111111111232456752633744432537528447257354628867336434575" &
        "2747827242838653235848686386682466585835223526487458736774567678");
   -- V146_FIXTURE_END eight16_b3

   -- V146_FIXTURE_BEGIN eight16_b4
   Check
     (Case_Id => "eight16_b4",
      Lengths => Month_Lengths'(1 => 16, 2 => 16, 3 => 16, 4 => 16, 5 => 16, 6 => 16, 7 => 16, 8 => 16),
      Bowls => Bowl_Array'(1 => From_String ("0"), 2 => From_String ("0"), 3 => From_String ("0"), 4 => From_String ("0"), 5 => From_String ("0"), 6 => From_String ("0")),
      Order => Bowl_Order'(1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6, 6 => 1),
      Queried => 1, Seal => 0,
      Expected_Count => "8484570857678108456252429355893789531769120343894823957866334278987787485159718203651318043348194800",
      Expected_First => "32761",
      Expected_Direction => -1,
      Expected_Rank => "948279314809000982421334581728649621358781224672648808577303003224983359534956536",
      Expected_Text => "1111111111111111232324433564627328853667337484438736362822765688" &
        "6247764832276528452557544847238624754653685787585352375474685678");
   -- V146_FIXTURE_END eight16_b4

   -- V146_FIXTURE_BEGIN eight16_b5
   Check
     (Case_Id => "eight16_b5",
      Lengths => Month_Lengths'(1 => 16, 2 => 16, 3 => 16, 4 => 16, 5 => 16, 6 => 16, 7 => 16, 8 => 16),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("170141183460469231731687303715884105727"), 3 => From_String ("2"), 4 => From_String ("170141183460469231731687303715884105725"), 5 => From_String ("3"), 6 => From_String ("170141183460469231731687303715884105724")),
      Order => Bowl_Order'(1 => 2, 2 => 4, 3 => 6, 4 => 1, 5 => 3, 6 => 5),
      Queried => 6, Seal => 33,
      Expected_Count => "8484570857678108456252429355893789531769120343894823957866334278987787485159718203651318043348194800",
      Expected_First => "44733",
      Expected_Direction => -1,
      Expected_Rank => "1294845037896288355324082539859652529561581358528522279105107791760580792033521340",
      Expected_Text => "1111111111111111232452645478244388474756463436373366488576737878" &
        "2424585252683354245285228663736557723633856672522483775478656788");
   -- V146_FIXTURE_END eight16_b5

   -- V146_FIXTURE_BEGIN eight16_b6
   Check
     (Case_Id => "eight16_b6",
      Lengths => Month_Lengths'(1 => 16, 2 => 16, 3 => 16, 4 => 16, 5 => 16, 6 => 16, 7 => 16, 8 => 16),
      Bowls => Bowl_Array'(1 => From_String ("170141183460469231731687303715884105627"), 2 => From_String ("170141183460469231731687303715884105628"), 3 => From_String ("12345"), 4 => From_String ("987654321"), 5 => From_String ("10"), 6 => From_String ("20")),
      Order => Bowl_Order'(1 => 5, 2 => 1, 3 => 6, 4 => 3, 5 => 2, 6 => 4),
      Queried => 2, Seal => 31,
      Expected_Count => "8484570857678108456252429355893789531769120343894823957866334278987787485159718203651318043348194800",
      Expected_First => "176790136259",
      Expected_Direction => 1,
      Expected_Rank => "5117724808523802416409475713867088128268401885894092309194897589896964934140272083953092",
      Expected_Text => "1111111111112314553236575248338638477743246662667625562448488835" &
        "1837674862531247252857635388274465381486432757827574322634556778");
   -- V146_FIXTURE_END eight16_b6

   -- V146_FIXTURE_BEGIN eight32_b1
   Check
     (Case_Id => "eight32_b1",
      Lengths => Month_Lengths'(1 => 32, 2 => 32, 3 => 32, 4 => 32, 5 => 32, 6 => 32, 7 => 32, 8 => 32),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("2"), 3 => From_String ("3"), 4 => From_String ("4"), 5 => From_String ("5"), 6 => From_String ("6")),
      Order => Bowl_Order'(1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6),
      Queried => 4, Seal => 32,
      Expected_Count => "26254089435165697729528393257871603255707257609737749025501387135406164344323199990591639256125823042318635882820638131218736213447130931322662579357911091228956700002794085172789952584178523338265523391407270930400",
      Expected_First => "48016",
      Expected_Direction => -1,
      Expected_Rank => "6845086689126299763967582774677218328217945518090214670571776262846352994024735889818157137718041863780760932921949844772620190474208187849033163685223415033728860550406322834099801539084900368388",
      Expected_Text => "1111111111111111111234521637347264364584667852512214635878373828" &
        "5237416774746635725462854282375675257474853374862371235361836122" &
        "2272555427876771626557586775374312743431535336348845148827724844" &
        "2558563466763238462534834612686568281578886832344236746885456788");
   -- V146_FIXTURE_END eight32_b1

   -- V146_FIXTURE_BEGIN eight32_b2
   Check
     (Case_Id => "eight32_b2",
      Lengths => Month_Lengths'(1 => 32, 2 => 32, 3 => 32, 4 => 32, 5 => 32, 6 => 32, 7 => 32, 8 => 32),
      Bowls => Bowl_Array'(1 => From_String ("13"), 2 => From_String ("17"), 3 => From_String ("19"), 4 => From_String ("23"), 5 => From_String ("29"), 6 => From_String ("31")),
      Order => Bowl_Order'(1 => 6, 2 => 5, 3 => 4, 4 => 3, 5 => 2, 6 => 1),
      Queried => 4, Seal => 32,
      Expected_Count => "26254089435165697729528393257871603255707257609737749025501387135406164344323199990591639256125823042318635882820638131218736213447130931322662579357911091228956700002794085172789952584178523338265523391407270930400",
      Expected_First => "59129",
      Expected_Direction => 1,
      Expected_Rank => "8430962532557914683247137517496103965892765726654464679232259545348018489327306418359167179058095433274933332979280285470141815384602030459045126511478033827567885989570872271366189584580031283198",
      Expected_Text => "1111111111111111111234563455344354678863264841655222123175672243" &
        "1473347872161623438457837773664633624586866725286124446484517345" &
        "2425284673287776623873725388782813851555287718435844528155468318" &
        "2576723833877763726226373764685658235285554437746852623456456878");
   -- V146_FIXTURE_END eight32_b2

   -- V146_FIXTURE_BEGIN eight32_b3
   Check
     (Case_Id => "eight32_b3",
      Lengths => Month_Lengths'(1 => 32, 2 => 32, 3 => 32, 4 => 32, 5 => 32, 6 => 32, 7 => 32, 8 => 32),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("170141183460469231731687303715884105727"), 3 => From_String ("170141183460469231731687303715884105726"), 4 => From_String ("17"), 5 => From_String ("170141183460469231731687303715884105720"), 6 => From_String ("19")),
      Order => Bowl_Order'(1 => 3, 2 => 6, 3 => 2, 4 => 4, 5 => 1, 6 => 5),
      Queried => 4, Seal => 32,
      Expected_Count => "26254089435165697729528393257871603255707257609737749025501387135406164344323199990591639256125823042318635882820638131218736213447130931322662579357911091228956700002794085172789952584178523338265523391407270930400",
      Expected_First => "53111",
      Expected_Direction => 1,
      Expected_Rank => "7572938543906340594941432182399092928625204987540631014624019273060386748692709752122351542587595314240734476383948785289999932562034808206746654839005270144944813827342982813868319125639964655614",
      Expected_Text => "1111111111111111111234542665725142832777135348558728474726375338" &
        "6446233521425627865472813578452466464833667288754356852728633545" &
        "5616732235145728841747747486232843672133267545243438236676446573" &
        "8128566277872873654562727638118348388861765324845535516823845678");
   -- V146_FIXTURE_END eight32_b3

   -- V146_FIXTURE_BEGIN eight32_b4
   Check
     (Case_Id => "eight32_b4",
      Lengths => Month_Lengths'(1 => 32, 2 => 32, 3 => 32, 4 => 32, 5 => 32, 6 => 32, 7 => 32, 8 => 32),
      Bowls => Bowl_Array'(1 => From_String ("0"), 2 => From_String ("0"), 3 => From_String ("0"), 4 => From_String ("0"), 5 => From_String ("0"), 6 => From_String ("0")),
      Order => Bowl_Order'(1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6, 6 => 1),
      Queried => 1, Seal => 0,
      Expected_Count => "26254089435165697729528393257871603255707257609737749025501387135406164344323199990591639256125823042318635882820638131218736213447130931322662579357911091228956700002794085172789952584178523338265523391407270930400",
      Expected_First => "32761",
      Expected_Direction => -1,
      Expected_Rank => "4670085700944218887080986748272282573230135768143133820854477267540965456075122705464115506884296547086393442499586595312988348922486191262324425672001080374636975233891458481469357230156565970948",
      Expected_Text => "1111111111111111111234152641764474325772226225248457248528884786" &
        "8356277125468276871648345313486526333276383845876475775376424485" &
        "2846282631332384752336571225251226558676782483724374365165655577" &
        "6848435336465843357836156233744443161155626378278377568475886788");
   -- V146_FIXTURE_END eight32_b4

   -- V146_FIXTURE_BEGIN eight32_b5
   Check
     (Case_Id => "eight32_b5",
      Lengths => Month_Lengths'(1 => 32, 2 => 32, 3 => 32, 4 => 32, 5 => 32, 6 => 32, 7 => 32, 8 => 32),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("170141183460469231731687303715884105727"), 3 => From_String ("2"), 4 => From_String ("170141183460469231731687303715884105725"), 5 => From_String ("3"), 6 => From_String ("170141183460469231731687303715884105724")),
      Order => Bowl_Order'(1 => 2, 2 => 4, 3 => 6, 4 => 1, 5 => 3, 6 => 5),
      Queried => 6, Seal => 33,
      Expected_Count => "26254089435165697729528393257871603255707257609737749025501387135406164344323199990591639256125823042318635882820638131218736213447130931322662579357911091228956700002794085172789952584178523338265523391407270930400",
      Expected_First => "44733",
      Expected_Direction => -1,
      Expected_Rank => "6377008797012122673255115075254904065115685314283183111763392611480401680547936146505517434405869731712087811253210510260920987864289910904151827277658097125777457109297289751852292613079543316484",
      Expected_Text => "1111111111111111111234452316773766333325238227724667745847683716" &
        "5873572144888452262633814586586443267175862842725535335127756488" &
        "5514732553665554373328265442842444413165561754432423183776838258" &
        "5282635662368352477887541768866466576473228874883714726273485678");
   -- V146_FIXTURE_END eight32_b5

   -- V146_FIXTURE_BEGIN eight32_b6
   Check
     (Case_Id => "eight32_b6",
      Lengths => Month_Lengths'(1 => 32, 2 => 32, 3 => 32, 4 => 32, 5 => 32, 6 => 32, 7 => 32, 8 => 32),
      Bowls => Bowl_Array'(1 => From_String ("170141183460469231731687303715884105627"), 2 => From_String ("170141183460469231731687303715884105628"), 3 => From_String ("12345"), 4 => From_String ("987654321"), 5 => From_String ("10"), 6 => From_String ("20")),
      Order => Bowl_Order'(1 => 5, 2 => 1, 3 => 6, 4 => 3, 5 => 2, 6 => 4),
      Queried => 2, Seal => 31,
      Expected_Count => "26254089435165697729528393257871603255707257609737749025501387135406164344323199990591639256125823042318635882820638131218736213447130931322662579357911091228956700002794085172789952584178523338265523391407270930400",
      Expected_First => "176790136259",
      Expected_Direction => 1,
      Expected_Rank => "25206078077539805367398743933553781588990866443595647129054468027756823010335953563007233117759694347847875442637963274189872103333088453161967170038409992580592114087963166345242888721916217537478000638",
      Expected_Text => "1111111111111232452562443756486674437546681734772536332535773132" &
        "5428287265284167715627886882236258412487854465331158411732863346" &
        "8848252371873344231327458476488572471852683246181736723516571536" &
        "6132157565587676864365487772332224886361285544685454233745656778");
   -- V146_FIXTURE_END eight32_b6

   -- V146_FIXTURE_BEGIN twelve12_b1
   Check
     (Case_Id => "twelve12_b1",
      Lengths => Month_Lengths'(1 => 12, 2 => 12, 3 => 12, 4 => 12, 5 => 12, 6 => 12, 7 => 12, 8 => 12, 9 => 12, 10 => 12, 11 => 12, 12 => 12),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("2"), 3 => From_String ("3"), 4 => From_String ("4"), 5 => From_String ("5"), 6 => From_String ("6")),
      Order => Bowl_Order'(1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6),
      Queried => 4, Seal => 32,
      Expected_Count => "300023061462656623377368054467125768149585357472311800429674901748375323502606423930061133993742830823476708866723045193185973392",
      Expected_First => "48016",
      Expected_Direction => -1,
      Expected_Rank => "236471140187661466992492659161011898248406379285489674919402293692208389467708211187016126056009415862655031327340888067",
      Expected_Text => "111111112234456374896355A28856B697954B38856BC5CA725B4CA6536A2A6B" &
        "C369862785CC9742374C9AC61471B238743A274873B7B129C2918849AB23953B" &
        "45C967A8A9ABABCC");
   -- V146_FIXTURE_END twelve12_b1

   -- V146_FIXTURE_BEGIN twelve12_b2
   Check
     (Case_Id => "twelve12_b2",
      Lengths => Month_Lengths'(1 => 12, 2 => 12, 3 => 12, 4 => 12, 5 => 12, 6 => 12, 7 => 12, 8 => 12, 9 => 12, 10 => 12, 11 => 12, 12 => 12),
      Bowls => Bowl_Array'(1 => From_String ("13"), 2 => From_String ("17"), 3 => From_String ("19"), 4 => From_String ("23"), 5 => From_String ("29"), 6 => From_String ("31")),
      Order => Bowl_Order'(1 => 6, 2 => 5, 3 => 4, 4 => 3, 5 => 2, 6 => 1),
      Queried => 4, Seal => 32,
      Expected_Count => "300023061462656623377368054467125768149585357472311800429674901748375323502606423930061133993742830823476708866723045193185973392",
      Expected_First => "59129",
      Expected_Direction => 1,
      Expected_Rank => "291235003549875243787658990020199003485097777887868359560461873310786107247207499270452361745733453084097180235313709055",
      Expected_Text => "111111112234565378594677272186A7A13326B863C48813252A5CB6C8C2AA59" &
        "9C526454C2349CC77474958A487B78A66B929AB591BAB8378349632C3453BC9B" &
        "4656B7ACA989BABC");
   -- V146_FIXTURE_END twelve12_b2

   -- V146_FIXTURE_BEGIN twelve12_b3
   Check
     (Case_Id => "twelve12_b3",
      Lengths => Month_Lengths'(1 => 12, 2 => 12, 3 => 12, 4 => 12, 5 => 12, 6 => 12, 7 => 12, 8 => 12, 9 => 12, 10 => 12, 11 => 12, 12 => 12),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("170141183460469231731687303715884105727"), 3 => From_String ("170141183460469231731687303715884105726"), 4 => From_String ("17"), 5 => From_String ("170141183460469231731687303715884105720"), 6 => From_String ("19")),
      Order => Bowl_Order'(1 => 3, 2 => 6, 3 => 2, 4 => 4, 5 => 1, 6 => 5),
      Queried => 4, Seal => 32,
      Expected_Count => "300023061462656623377368054467125768149585357472311800429674901748375323502606423930061133993742830823476708866723045193185973392",
      Expected_First => "53111",
      Expected_Direction => 1,
      Expected_Rank => "261594844388637496800222082104865970000574962418175811736527294691333404959327164152590762205017880575192680555595431935",
      Expected_Text => "11111111223454555126746233587988A8A9243831939BB9BCC432753C962455" &
        "AB12B857366C774468B47616624B93485A78CA29B2A657B3293A8867CB49576A" &
        "97CCCB8AACCA9ABC");
   -- V146_FIXTURE_END twelve12_b3

   -- V146_FIXTURE_BEGIN twelve12_b4
   Check
     (Case_Id => "twelve12_b4",
      Lengths => Month_Lengths'(1 => 12, 2 => 12, 3 => 12, 4 => 12, 5 => 12, 6 => 12, 7 => 12, 8 => 12, 9 => 12, 10 => 12, 11 => 12, 12 => 12),
      Bowls => Bowl_Array'(1 => From_String ("0"), 2 => From_String ("0"), 3 => From_String ("0"), 4 => From_String ("0"), 5 => From_String ("0"), 6 => From_String ("0")),
      Order => Bowl_Order'(1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6, 6 => 1),
      Queried => 1, Seal => 0,
      Expected_Count => "300023061462656623377368054467125768149585357472311800429674901748375323502606423930061133993742830823476708866723045193185973392",
      Expected_First => "32761",
      Expected_Direction => -1,
      Expected_Rank => "161336439621911744444578064570050544674728155624778505585051679395141095781830093502905341577176571292475878350587428867",
      Expected_Text => "111111112223451561786983AAAB8445C8BBCB5BA63A883758C6562876742639" &
        "BA9A7C91B9429B265355969C3A327C93CA7B7B819844586CC4429A27CB6524A3" &
        "237344C567789ABC");
   -- V146_FIXTURE_END twelve12_b4

   -- V146_FIXTURE_BEGIN twelve12_b5
   Check
     (Case_Id => "twelve12_b5",
      Lengths => Month_Lengths'(1 => 12, 2 => 12, 3 => 12, 4 => 12, 5 => 12, 6 => 12, 7 => 12, 8 => 12, 9 => 12, 10 => 12, 11 => 12, 12 => 12),
      Bowls => Bowl_Array'(1 => From_String ("1"), 2 => From_String ("170141183460469231731687303715884105727"), 3 => From_String ("2"), 4 => From_String ("170141183460469231731687303715884105725"), 5 => From_String ("3"), 6 => From_String ("170141183460469231731687303715884105724")),
      Order => Bowl_Order'(1 => 2, 2 => 4, 3 => 6, 4 => 1, 5 => 3, 6 => 5),
      Queried => 6, Seal => 33,
      Expected_Count => "300023061462656623377368054467125768149585357472311800429674901748375323502606423930061133993742830823476708866723045193185973392",
      Expected_First => "44733",
      Expected_Direction => -1,
      Expected_Rank => "220301541894816082585753648079915462733336853996855471777830804558332812596470068915175044086556237971871802273084473347",
      Expected_Text => "1111111122343356224472857958652ABAC425B5CA997373B7C97BA88298369A" &
        "AA2584A333A354217837C94A6189C58B8C79126B4C1C852BC666B666537444A4" &
        "95C9B6BB7789CABC");
   -- V146_FIXTURE_END twelve12_b5

   -- V146_FIXTURE_BEGIN twelve12_b6
   Check
     (Case_Id => "twelve12_b6",
      Lengths => Month_Lengths'(1 => 12, 2 => 12, 3 => 12, 4 => 12, 5 => 12, 6 => 12, 7 => 12, 8 => 12, 9 => 12, 10 => 12, 11 => 12, 12 => 12),
      Bowls => Bowl_Array'(1 => From_String ("170141183460469231731687303715884105627"), 2 => From_String ("170141183460469231731687303715884105628"), 3 => From_String ("12345"), 4 => From_String ("987654321"), 5 => From_String ("10"), 6 => From_String ("20")),
      Order => Bowl_Order'(1 => 5, 2 => 1, 3 => 6, 4 => 3, 5 => 2, 6 => 4),
      Queried => 2, Seal => 31,
      Expected_Count => "300023061462656623377368054467125768149585357472311800429674901748375323502606423930061133993742830823476708866723045193185973392",
      Expected_First => "176790136259",
      Expected_Direction => 1,
      Expected_Rank => "870735755552168288355867930457334071273390525332357932265103962955574233993367451543989769533165773523638213738498698044768255",
      Expected_Text => "111233221143542677819A2B7C9A4AB535591C47BC38261C756669C4235CBC92" &
        "AC76A6139A61B92A6443869273C35BAA18B5B5824BA4747389865128CB75934A" &
        "B94C858876789ABC");
   -- V146_FIXTURE_END twelve12_b6
   Require (Checked = 30 and then Wide_Checked = 18,
            "v146 full-label chain coverage incomplete");
   Ada.Text_IO.Put_Line ("V146_SYNTHETIC_FULL_SELECTION_CHAINS=30");
   Ada.Text_IO.Put_Line ("V146_WIDE_GLOBAL_RANK_CHAIN_CASES=18");
   Ada.Text_IO.Put_Line ("V146_FULL_SEQUENCES_COMPARED_EXACTLY=30");
   Ada.Text_IO.Put_Line ("V146_ORIGINAL_CALENDAR_FCT_CALLS=0");
   Ada.Text_IO.Put_Line ("V146_PRODUCTION_ADA_PATCH_APPLIED=FALSE");
end Test_Synthetic_Selection_Chain_V146;
