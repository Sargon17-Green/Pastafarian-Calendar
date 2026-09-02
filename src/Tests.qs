namespace Pastafari.Tests {
    import Std.Diagnostics.Fact;
    import Pastafari.ExactMath.*;
    import Pastafari.SourceLanguageCatalog.*;
    import Pastafari.MonsterInfrastructure.*;

    @Test()
    operation TestExactArithmetic() : Unit {
        Fact(M() == 170141183460469231731687303715884105727L, "大きな法 M が一致しません。");
        Fact(Save(1L) == 1L, "SAVE(1) が一致しません。");
        Fact(Save(M()-1L) == M()-1L, "SAVE(M-1) が一致しません。");
        Fact(Save(M()) == M(), "SAVE(M) は M でなければなりません。");
        Fact(Save(M()+1L) == 1L, "SAVE(M+1) が一致しません。");
        Fact(Save(2L*M()) == M(), "SAVE(2M) は M でなければなりません。");
        Fact(RegularMod(-1L,7L) == 6L, "ユークリッド剰余が一致しません。");
        Fact(FloorDiv(-8L,7L) == -2L, "床除算が一致しません。");
    }

    @Test()
    operation TestSourceLanguageCatalog() : Unit {
        let cutlets = CutletNames();
        let months = MonthNames();
        Fact(Length(cutlets) == 17, "カツレツ名は17件でなければなりません。");
        Fact(Length(months) == 47, "月名は47件でなければなりません。");
        for i in 1..17 {
            Fact(cutlets[i-1].CanonicalIndex == i, "カツレツ名の canonicalIndex が連続していません。");
        }
        for i in 1..47 {
            Fact(months[i-1].CanonicalIndex == i, "月名の canonicalIndex が連続していません。");
        }
        Fact(ResolveCutlet(1) == "青銅", "第1カツレツ名が一致しません。");
        Fact(ResolveCutlet(6) == "九分の四", "分数形式のカツレツ名が一致しません。");
        Fact(ResolveCutlet(7) == "パルグラシュ", "造語の転写が一致しません。");
        Fact(ResolveCutlet(12) == "小麦", "小麦の翻訳が一致しません。");
        Fact(ResolveCutlet(15) == "アッカド", "アッカドの表記が一致しません。");
        Fact(ResolveMonth(7) == "五分の三", "分数形式の月名が一致しません。");
        Fact(ResolveMonth(8) == "カルシュマブ", "造語の月名転写が一致しません。");
        Fact(ResolveMonth(28) == "ニネヴェ", "ニネヴェの表記が一致しません。");
        Fact(ResolveMonth(41) == "バビロン", "バビロンの表記が一致しません。");
        Fact(ResolveMonth(47) == "砂", "最後の月名が一致しません。");
    }

    @Test()
    operation TestNeutralMonsterInfrastructure() : Unit {
        let initial = NewBaseMonsterContext(-15055671L,-15055671L);
        let result = BaseDispatcher(initial);
        Fact(result.Accepted, "Bootstrap ディスパッチャが入力を受理しませんでした。");
        Fact(result.Context.Phase == 1, "Bootstrap フェーズ遷移が一致しません。");
        Fact(result.Context.StatusCode == 1, "Bootstrap 状態コードが一致しません。");
        Fact(result.Context.CommitToken == 1, "Bootstrap commit token が一致しません。");
        Fact(result.Context.MetricTicks == 1, "メトリクスは意味論から独立した1回の記録でなければなりません。");
        Fact(result.Context.LogTicks == 1, "ログは意味論から独立した1回の記録でなければなりません。");
    }

    @Test()
    operation TestCoreAndOracleHelpers() : Unit {
        let foundation = Pastafari.CanonicalCore.FoundationDay();
        Fact(foundation == -15055671L, "基礎の日が一致しません。");
        Fact(Pastafari.CanonicalCore.TabletsDay() == -278522L, "石板の日が一致しません。");
        Fact(Pastafari.CanonicalCore.TabletsDay()-foundation == 14777149L, "二つの基準日の距離が一致しません。");
        Fact(Pastafari.CanonicalCore.DayCount(foundation) == 1L, "基礎の日の通し番号が一致しません。");
        Fact(Pastafari.CanonicalCore.DayCount(foundation+1L) == 3L, "基礎の日の翌日の通し番号が一致しません。");
        Fact(Pastafari.CanonicalCore.DayCount(foundation-1L) == 2L, "基礎の日の前日の通し番号が一致しません。");

        let same = Pastafari.CanonicalCore.WorkCountsFor(foundation,foundation);
        Fact(same.Distance == 1L and same.Direction == 2L, "同日入力の距離または方向が一致しません。");
        let forward = Pastafari.CanonicalCore.WorkCountsFor(foundation,foundation+2L);
        Fact(forward.Distance == 3L and forward.Direction == 3L, "未来方向の距離または方向が一致しません。");
        let backward = Pastafari.CanonicalCore.WorkCountsFor(foundation,foundation-2L);
        Fact(backward.Distance == 3L and backward.Direction == 1L, "過去方向の距離または方向が一致しません。");

        Fact(Pastafari.NormativeOracle.DayCount(foundation) == Pastafari.CanonicalCore.DayCount(foundation), "oracle と production の dayCount が一致しません。");
        Fact(Pastafari.NormativeOracle.WorkCountsFor(foundation,foundation+2L).Distance == forward.Distance, "oracle と production の距離が一致しません。");
    }

    @Test()
    operation TestPermutationAndSelection() : Unit {
        Fact(Pastafari.CanonicalCore.PermutationUnrank1(1L) == [1,2,3,4,5,6], "順列順位1が一致しません。");
        Fact(Pastafari.CanonicalCore.PermutationUnrank1(720L) == [6,5,4,3,2,1], "順列順位720が一致しません。");
        Fact(Pastafari.NormativeOracle.PermutationUnrank1(1L) == [1,2,3,4,5,6], "oracle の順列順位1が一致しません。");
        let stream = Pastafari.CanonicalCore.AnswerStream(1L,1);
        Fact(Pastafari.CanonicalCore.ChooseRankShort(stream,1L) == 1L, "N=1 の短い選択が一致しません。");
        Fact(Pastafari.CanonicalCore.ChooseRankShort(stream,M()) == 1L, "N=M の短い選択が一致しません。");
    }

    @Test()
    operation TestOrderedFamiliesSmallFixtures() : Unit {
        Fact(Pastafari.CanonicalCore.CountBoundedCompositions(7,2,3,4) == 2L, "小さい有界合成の個数が一致しません。");
        Fact(Pastafari.CanonicalCore.UnrankBoundedComposition(7,2,3,4,1L) == [3,4], "有界合成の第1要素が一致しません。");
        Fact(Pastafari.CanonicalCore.UnrankBoundedComposition(7,2,3,4,2L) == [4,3], "有界合成の第2要素が一致しません。");
        Fact(Pastafari.CanonicalCore.UnrankDistinctNameIndices(5,3,1L) == [1,2,3], "重複なし名称の第1順位が一致しません。");
        Fact(Pastafari.CanonicalCore.CountCutletPartitions(5,2,0,-1,false) == 4L, "正の合成の個数が一致しません。");
        Fact(Pastafari.CanonicalCore.CountCutletPartitions(5,2,0,2,false) == 1L, "必須境界付き合成の個数が一致しません。");
        Fact(Pastafari.CanonicalCore.UnrankCutletPartition(5,2,2,1L) == [2,3], "必須境界付き合成の unrank が一致しません。");
    }

    @Test()
    operation TestWeavingSmallFixtures() : Unit {
        Fact(Pastafari.CanonicalCore.CountWeavings([1,1],[1,1],0,0) == 1L, "[1,1] の織り数が一致しません。");
        Fact(Pastafari.CanonicalCore.UnrankWeaving([1,1],1L) == [1,2], "[1,1] の織り順が一致しません。");
        Fact(Pastafari.CanonicalCore.CountWeavings([2,2],[2,2],0,0) == 2L, "[2,2] の織り数が一致しません。");
        Fact(Pastafari.CanonicalCore.UnrankWeaving([2,2],1L) == [1,1,2,2], "[2,2] の第1織り順が一致しません。");
        Fact(Pastafari.CanonicalCore.UnrankWeaving([2,2],2L) == [1,2,1,2], "[2,2] の第2織り順が一致しません。");
        Fact(Pastafari.NormativeOracle.CountWeavings([2,2],[2,2],0,0) == 2L, "oracle の小さい織り数が一致しません。");
    }

    @Test()
    operation TestSauceLocalDifferential() : Unit {
        let foundation = -15055671L;
        let p = Pastafari.CanonicalCore.Sauce(foundation,foundation);
        let o = Pastafari.NormativeOracle.Sauce(foundation,foundation);
        Fact(Length(p.Bowls) == 6 and Length(o.Bowls) == 6, "最終鉢数が6ではありません。");
        Fact(Length(p.OrderAt46) == 6 and Length(o.OrderAt46) == 6, "第46滴の順序長が6ではありません。");
        Fact(p.Bowls == o.Bowls, "sauce の鉢が oracle と一致しません。");
        Fact(p.OrderAt46 == o.OrderAt46, "第46滴の順序が oracle と一致しません。");
    }
}
