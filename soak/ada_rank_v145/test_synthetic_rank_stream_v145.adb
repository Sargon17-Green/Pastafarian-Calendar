with Ada.Numerics.Big_Numbers.Big_Integers;
with Ada.Text_IO;
with Synthetic_Rank_Stream_V145;

--  Original F(c,t) is never imported or called. Synthetic frozen fixtures.
procedure Test_Synthetic_Rank_Stream_V145 is
   use Ada.Numerics.Big_Numbers.Big_Integers;
   use Synthetic_Rank_Stream_V145;

   Zero : constant Big_Integer := To_Big_Integer (0);
   One  : constant Big_Integer := To_Big_Integer (1);
   Direct_Checked : Natural := 0;
   Bowl_Checked : Natural := 0;
   Rejected_Checked : Natural := 0;

   procedure Require (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         raise Program_Error with Message;
      end if;
   end Require;

   procedure Check_Direct
     (Name, First_Str : String; Direction : Integer;
      N_Str, Expected_Str : String)
   is
      S : constant Answer_Stream :=
        (First => From_String (First_Str), Direction_Step => Direction);
      N : constant Big_Integer := From_String (N_Str);
      Expect : constant Big_Integer := From_String (Expected_Str);
      Actual : constant Big_Integer := Choose_Rank (S, N);
   begin
      Require (Actual = Expect, "direct rank mismatch " & Name);
      Require (Actual >= One and then Actual <= N,
               "direct global rank out of range " & Name);
      Require (Answer_At (S, Zero) = S.First,
               "synthetic source answer stream first changed " & Name);
      Direct_Checked := Direct_Checked + 1;
   end Check_Direct;

   procedure Check_Bowl
     (Bowls : Bowl_Array; Order : Bowl_Order;
      Queried, Seal : Natural;
      Expected_First : String; Expected_Step : Integer;
      Expected_Short, Expected_Wide : String)
   is
      S : constant Answer_Stream := Ask_Bowl (Bowls, Order, Queried, Seal);
      N_Wide : constant Big_Integer :=
        (To_Big_Integer (2) ** 256) + To_Big_Integer (12345);
   begin
      Require (S.First = From_String (Expected_First),
               "synthetic Ask_Bowl first mismatch");
      Require (S.Direction_Step = Expected_Step,
               "synthetic Ask_Bowl direction mismatch");
      Require (Choose_Rank (S, To_Big_Integer (37)) =
               From_String (Expected_Short),
               "synthetic bowl short choice rank mismatch");
      Require (Choose_Rank (S, N_Wide) = From_String (Expected_Wide),
               "synthetic bowl wide choice rank mismatch");
      Bowl_Checked := Bowl_Checked + 1;
   end Check_Bowl;

   procedure Check_Rejections is
      Rejected : Boolean := False;
   begin
      begin
         declare
            Bad : constant Big_Integer := Choose_Rank
              ((First => One, Direction_Step => 1), Zero);
         begin
            if Bad > Zero then null; end if;
         end;
      exception when Constraint_Error => Rejected := True;
      end;
      Require (Rejected, "N=0 should reject"); Rejected_Checked := Rejected_Checked+1;
      Rejected := False;

      begin
         declare
            Bad : constant Big_Integer := Choose_Rank
              ((First => One, Direction_Step => 0), To_Big_Integer (7));
         begin
            if Bad > Zero then null; end if;
         end;
      exception when Constraint_Error => Rejected := True;
      end;
      Require (Rejected, "zero direction should reject"); Rejected_Checked := Rejected_Checked+1;
      Rejected := False;

      begin
         declare
            Bad : constant Big_Integer := Answer_At
              ((First => One, Direction_Step => 1), -One);
         begin
            if Bad > Zero then null; end if;
         end;
      exception when Constraint_Error => Rejected := True;
      end;
      Require (Rejected, "negative answer index should reject"); Rejected_Checked := Rejected_Checked+1;
      Rejected := False;

      begin
         declare
            Bad : constant Answer_Stream := Ask_Bowl
              ((others => One), (others => 1), 4, 32);
         begin
            if Bad.First > Zero then null; end if;
         end;
      exception when Constraint_Error => Rejected := True;
      end;
      Require (Rejected, "non-permutation bowl order should reject"); Rejected_Checked := Rejected_Checked+1;
      Rejected := False;

      begin
         declare
            Bad : constant Big_Integer := Choose_Rank
              ((First => One, Direction_Step => 1),
               To_Big_Integer (2) ** 1024);
         begin
            if Bad > Zero then null; end if;
         end;
      exception when Constraint_Error => Rejected := True;
      end;
      Require (Rejected, "large synthetic rank family must stop"); Rejected_Checked := Rejected_Checked+1;
   end Check_Rejections;

begin
   Check_Direct
     ("short_one", "1", 1,
      "1", "1");
   Check_Direct
     ("short_two_accepted", "5", 1,
      "2", "1");
   Check_Direct
     ("short_two_reject_plus", "170141183460469231731687303715884105727", 1,
      "2", "1");
   Check_Direct
     ("short_two_reject_minus", "170141183460469231731687303715884105727", -1,
      "2", "2");
   Check_Direct
     ("short_three_reject_plus", "170141183460469231731687303715884105727", 1,
      "3", "1");
   Check_Direct
     ("short_three_reject_minus", "170141183460469231731687303715884105727", -1,
      "3", "3");
   Check_Direct
     ("short_modulus", "170141183460469231731687303715884105727", 1,
      "170141183460469231731687303715884105727", "170141183460469231731687303715884105727");
   Check_Direct
     ("short_modulus_minus_one", "170141183460469231731687303715884105727", -1,
      "170141183460469231731687303715884105726", "170141183460469231731687303715884105726");
   Check_Direct
     ("short_37_first", "1", -1,
      "37", "1");
   Check_Direct
     ("short_37_last", "170141183460469231731687303715884105722", 1,
      "37", "1");
   Check_Direct
     ("wide_M_plus_1_low", "1", 1,
      "170141183460469231731687303715884105728", "170141183460469231731687303715884105728");
   Check_Direct
     ("wide_M_plus_1_high", "170141183460469231731687303715884105727", -1,
      "170141183460469231731687303715884105728", "2");
   Check_Direct
     ("wide_half_space_reject_plus", "170141183460469231731687303715884105726", 1,
      "14474011154664524427946373126085988481488606899744601273200510697273257099265", "1");
   Check_Direct
     ("wide_half_space_reject_minus", "1", -1,
      "14474011154664524427946373126085988481488606899744601273200510697273257099265", "14474011154664524427946373126085988481488606899744601273200510697273257099265");
   Check_Direct
     ("wide_space_minus_2_reject_plus", "170141183460469231731687303715884105726", 1,
      "28948022309329048855892746252171976962977213799489202546401021394546514198527", "1");
   Check_Direct
     ("wide_space_minus_2_reject_minus", "1", -1,
      "28948022309329048855892746252171976962977213799489202546401021394546514198527", "28948022309329048855892746252171976962807072616028733314669334090830630092803");
   Check_Direct
     ("wide_space_minus_1_accept_plus", "170141183460469231731687303715884105726", 1,
      "28948022309329048855892746252171976962977213799489202546401021394546514198528", "28948022309329048855892746252171976962977213799489202546401021394546514198528");
   Check_Direct
     ("wide_space_exact", "170141183460469231731687303715884105726", 1,
      "28948022309329048855892746252171976962977213799489202546401021394546514198529", "28948022309329048855892746252171976962977213799489202546401021394546514198528");
   Check_Direct
     ("wide_three_places_boundary", "1", 1,
      "28948022309329048855892746252171976962977213799489202546401021394546514198530", "170141183460469231731687303715884105726");
   Check_Direct
     ("wide_three_places_2_to_256", "13", -1,
      "115792089237316195423570985008687907853269984665640564039457584007913129652281", "57896044618658097711785492504343953925103721681676058934143606270513607843738");
   Check_Direct
     ("wide_three_places_2_to_256_plus", "170141183460469231731687303715884105722", 1,
      "115792089237316195423570985008687907853269984665640564039457584007913129652281", "57896044618658097711785492504343953402387470795249461746467287429388664070253");
   Check_Direct
     ("wide_three_places_hi", "170141183460469231731687303715884105724", 1,
      "4925250774549309901534880012517951725548123341880193686925858436774199290547709261477934266526216329006041303875582", "4925250774549309901534880012517951725519175319570864638069965690522027313584391765311524125516351933004063021465597");
   Check_Direct
     ("wide_six_places_713bits_plus", "170141183460469231731687303715884105718", 1,
      "21545516652742137885659094560277007014094191832363720128504958578969526904000843047377578132593002296225722240434905979752527594496752860623371529300590103961416596156942109074193054752294185849943217159109883972885", "1");
   Check_Direct
     ("wide_six_places_713bits_minus", "8", -1,
      "21545516652742137885659094560277007014094191832363720128504958578969526904000843047377578132593002296225722240434905979752527594496752860623371529300590103961416596156942109074193054752294185849943217159109883972885", "285152538601387201165073225356268207799960865733685109430135896431989640269829217119404970323400072914687088005899832731272138248200164030666501429390627718815956814345918919049629348323655684");
   Check_Direct
     ("wide_eight_places_900bits", "170141183460469231731687303715884105723", 1,
      "4226356249085321970818718279332132852150778608288972177023685672213391220453798875795338047101257503157395159946057029431058780476021484298004311827703516615267093471992040673349852141411411528424193863265689507233184226342012493910707175190136291811916308647181903987075", "8254602048994769474255309139320571976541634231815817280797249619947833895917546279025066287328577470299336783849579846753345866504519434440924616229735957840305878363227070650375146225434927375790892055225946450606548560119948319898633404127410514124513346448345006076");
   Check_Direct
     ("wide_eight_places_900bits_minus", "3", -1,
      "4226356249085321970818718279332132852150778608288972177023685672213391220453798875795338047101257503157395159946057029431058780476021484298004311827703516615267093471992040673349852141411411528424193863265689507233184226342012493910707175190136291811916308647181903987075", "4226356249085321970818718279332132852150778608288972177023685672213391220453798875795338047101257503157395159946057029431058780476021484298004311827703516615267093471992040673349852141411411528424193863265689507233184226342012493910707175190136291811916308647181903987075");
   Check_Bowl
     (Bowl_Array'(1 => From_String ("1"), 2 => From_String ("2"), 3 => From_String ("3"), 4 => From_String ("4"), 5 => From_String ("5"), 6 => From_String ("6")),
      Bowl_Order'(1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6),
      4, 32, "48016", -1,
      "27", "28948022309329048855892746252171968794498995862361387108093569994950450068228");
   Check_Bowl
     (Bowl_Array'(1 => From_String ("13"), 2 => From_String ("17"), 3 => From_String ("19"), 4 => From_String ("23"), 5 => From_String ("29"), 6 => From_String ("31")),
      Bowl_Order'(1 => 6, 2 => 5, 3 => 4, 4 => 3, 5 => 2, 6 => 1),
      4, 32, "59129", 1,
      "3", "57896044618658097711785492504343943866016673131814140493326835980013326592940");
   Check_Bowl
     (Bowl_Array'(1 => From_String ("1"), 2 => From_String ("170141183460469231731687303715884105727"), 3 => From_String ("170141183460469231731687303715884105726"), 4 => From_String ("17"), 5 => From_String ("170141183460469231731687303715884105720"), 6 => From_String ("19")),
      Bowl_Order'(1 => 3, 2 => 6, 3 => 2, 4 => 4, 5 => 1, 6 => 5),
      4, 32, "53111", 1,
      "16", "115792089237316195423570985008687898816561307529738259074349821746160458257219");
   Check_Bowl
     (Bowl_Array'(1 => From_String ("0"), 2 => From_String ("0"), 3 => From_String ("0"), 4 => From_String ("0"), 5 => From_String ("0"), 6 => From_String ("0")),
      Bowl_Order'(1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6, 6 => 1),
      1, 0, "32761", -1,
      "16", "57896044618658097711785492504343948353320245718229658184847784182740812427427");
   Check_Bowl
     (Bowl_Array'(1 => From_String ("1"), 2 => From_String ("170141183460469231731687303715884105727"), 3 => From_String ("2"), 4 => From_String ("170141183460469231731687303715884105725"), 5 => From_String ("3"), 6 => From_String ("170141183460469231731687303715884105724")),
      Bowl_Order'(1 => 2, 2 => 4, 3 => 6, 4 => 1, 5 => 3, 6 => 5),
      6, 33, "44733", -1,
      "37", "57896044618658097711785492504343946316389997329492015893087384096176261715198");
   Check_Bowl
     (Bowl_Array'(1 => From_String ("170141183460469231731687303715884105627"), 2 => From_String ("170141183460469231731687303715884105628"), 3 => From_String ("12345"), 4 => From_String ("987654321"), 5 => From_String ("10"), 6 => From_String ("20")),
      Bowl_Order'(1 => 5, 2 => 1, 3 => 6, 4 => 3, 5 => 2, 6 => 4),
      2, 31, "176790136259", 1,
      "29", "115792089237316195423570984978608624845685829680797580624082740780734111153108");
   Require (Direct_Checked = 26 and then Bowl_Checked = 6,
            "v145 exact synthetic fixture coverage incomplete");
   Check_Rejections;
   Require (Rejected_Checked = 5, "v145 input rejection coverage incomplete");
   Ada.Text_IO.Put_Line ("V145_ADA_SHORT_WIDE_DIRECT_GOLDENS=26");
   Ada.Text_IO.Put_Line ("V145_ADA_SYNTHETIC_ASK_BOWL_GOLDENS=6");
   Ada.Text_IO.Put_Line ("V145_ADA_REJECTION_CHECKS=5");
   Ada.Text_IO.Put_Line ("V145_ORIGINAL_CALENDAR_FCT_CALLS=0");
   Ada.Text_IO.Put_Line ("V145_PRODUCTION_ADA_PATCH_APPLIED=FALSE");
end Test_Synthetic_Rank_Stream_V145;
