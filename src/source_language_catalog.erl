-module(source_language_catalog).
-export([
    version/0,
    cutlet_count/0,
    month_count/0,
    cutlet_name/1,
    month_name/1,
    cutlet_entries/0,
    month_entries/0,
    validate/0
]).

version() -> <<"1.0.0">>.
cutlet_count() -> 17.
month_count() -> 47.

cutlet_entries() ->
    [
        {1, <<"ערד"/utf8>>},
        {2, <<"פֿוקס"/utf8>>},
        {3, <<"ניר"/utf8>>},
        {4, <<"לאַגאַש"/utf8>>},
        {5, <<"געדאַנק"/utf8>>},
        {6, <<"פֿיר טיילן פֿון נײַן"/utf8>>},
        {7, <<"פּאַלגוראַש"/utf8>>},
        {8, <<"ראָר"/utf8>>},
        {9, <<"קנויל"/utf8>>},
        {10, <<"סקאָרפּיאָן"/utf8>>},
        {11, <<"אַש"/utf8>>},
        {12, <<"ווייץ"/utf8>>},
        {13, <<"טײַך"/utf8>>},
        {14, <<"געלעכטער"/utf8>>},
        {15, <<"אַכאַד"/utf8>>},
        {16, <<"האָרן"/utf8>>},
        {17, <<"דער ליידיקער קרוג"/utf8>>}
    ].

month_entries() ->
    [
        {1, <<"ליים"/utf8>>},
        {2, <<"מילגרוים"/utf8>>},
        {3, <<"עלנבויגן"/utf8>>},
        {4, <<"אייפערזוכט"/utf8>>},
        {5, <<"ערידו"/utf8>>},
        {6, <<"ציינפּאַסטע"/utf8>>},
        {7, <<"דרײַ טיילן פֿון פינף"/utf8>>},
        {8, <<"כאַרשומאַב"/utf8>>},
        {9, <<"טיגער"/utf8>>},
        {10, <<"צין"/utf8>>},
        {11, <<"נעפּל"/utf8>>},
        {12, <<"ווײַרויך"/utf8>>},
        {13, <<"שפּינדל"/utf8>>},
        {14, <<"ריפּ"/utf8>>},
        {15, <<"באָקסער"/utf8>>},
        {16, <<"אורוק"/utf8>>},
        {17, <<"שאַנד"/utf8>>},
        {18, <<"קעמל"/utf8>>},
        {19, <<"קופּער"/utf8>>},
        {20, <<"ברונעם"/utf8>>},
        {21, <<"געלכל"/utf8>>},
        {22, <<"שטערן"/utf8>>},
        {23, <<"האָניק"/utf8>>},
        {24, <<"מילץ"/utf8>>},
        {25, <<"קאַלכשטיין"/utf8>>},
        {26, <<"פֿרייד"/utf8>>},
        {27, <<"פֿײַג"/utf8>>},
        {28, <<"נינווע"/utf8>>},
        {29, <<"זשאַבע"/utf8>>},
        {30, <<"פּעך"/utf8>>},
        {31, <<"ליכט"/utf8>>},
        {32, <<"די פֿאַרמאַכטע טיר"/utf8>>},
        {33, <<"סעסאַם"/utf8>>},
        {34, <<"נאַקן"/utf8>>},
        {35, <<"זילבער"/utf8>>},
        {36, <<"ליליע"/utf8>>},
        {37, <<"שטורעם"/utf8>>},
        {38, <<"אייזל"/utf8>>},
        {39, <<"מעל"/utf8>>},
        {40, <<"באַדויערונג"/utf8>>},
        {41, <<"בבֿל"/utf8>>},
        {42, <<"צונג"/utf8>>},
        {43, <<"פֿלאַקס"/utf8>>},
        {44, <<"זאַלץ"/utf8>>},
        {45, <<"באַרנע"/utf8>>},
        {46, <<"בויגן"/utf8>>},
        {47, <<"זאַמד"/utf8>>}
    ].

cutlet_name(Index) -> lookup(Index, cutlet_entries()).
month_name(Index) -> lookup(Index, month_entries()).

lookup(Index, Entries) when is_integer(Index) ->
    case lists:keyfind(Index, 1, Entries) of
        {Index, Name} -> Name;
        false -> erlang:error({unknown_canonical_index, Index})
    end.

validate() ->
    Cutlets = cutlet_entries(),
    Months = month_entries(),
    true = indexes_are_exact(Cutlets, cutlet_count()),
    true = indexes_are_exact(Months, month_count()),
    true = names_are_unique(Cutlets),
    true = names_are_unique(Months),
    ok.

indexes_are_exact(Entries, Count) ->
    [I || {I, _} <- Entries] =:= lists:seq(1, Count).

names_are_unique(Entries) ->
    Names = [N || {_, N} <- Entries],
    length(Names) =:= length(lists:usort(Names)).
