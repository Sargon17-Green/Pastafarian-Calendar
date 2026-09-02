:- module(source_language_catalog,
    [ source_language_catalog_version/1,
      cutlet_source_name/2,
      month_source_name/2,
      cutlet_source_names/1,
      month_source_names/1,
      canonical_cutlet_indices/1,
      canonical_month_indices/1
    ]).

source_language_catalog_version('1.0.0').

cutlet_source_name(1,  'bronce').
cutlet_source_name(2,  'raposo').
cutlet_source_name(3,  'ril').
cutlet_source_name(4,  'Lagash').
cutlet_source_name(5,  'pensamento').
cutlet_source_name(6,  'catro partes de nove').
cutlet_source_name(7,  'Palgurash').
cutlet_source_name(8,  'xunco').
cutlet_source_name(9,  'acio').
cutlet_source_name(10, 'escorpión').
cutlet_source_name(11, 'cinza').
cutlet_source_name(12, 'trigo').
cutlet_source_name(13, 'río').
cutlet_source_name(14, 'risa').
cutlet_source_name(15, 'Acad').
cutlet_source_name(16, 'corno').
cutlet_source_name(17, 'o cántaro baleiro').

month_source_name(1,  'barro').
month_source_name(2,  'granada').
month_source_name(3,  'cóbado').
month_source_name(4,  'envexa').
month_source_name(5,  'Eridu').
month_source_name(6,  'pasta de dentes').
month_source_name(7,  'tres partes de cinco').
month_source_name(8,  'Karshumab').
month_source_name(9,  'tigre').
month_source_name(10, 'estaño').
month_source_name(11, 'néboa').
month_source_name(12, 'incenso').
month_source_name(13, 'fuso').
month_source_name(14, 'costela').
month_source_name(15, 'alfarroba').
month_source_name(16, 'Uruk').
month_source_name(17, 'vergoña').
month_source_name(18, 'camelo').
month_source_name(19, 'cobre').
month_source_name(20, 'pozo').
month_source_name(21, 'xema').
month_source_name(22, 'estrela').
month_source_name(23, 'mel').
month_source_name(24, 'bazo').
month_source_name(25, 'pedra calcaria').
month_source_name(26, 'alegría').
month_source_name(27, 'figo').
month_source_name(28, 'Nínive').
month_source_name(29, 'ra').
month_source_name(30, 'alcatrán').
month_source_name(31, 'vela').
month_source_name(32, 'a porta pechada').
month_source_name(33, 'sésamo').
month_source_name(34, 'caluga').
month_source_name(35, 'prata').
month_source_name(36, 'lirio').
month_source_name(37, 'treboada').
month_source_name(38, 'burro').
month_source_name(39, 'fariña').
month_source_name(40, 'arrepentimento').
month_source_name(41, 'Babilonia').
month_source_name(42, 'lingua').
month_source_name(43, 'liño').
month_source_name(44, 'sal').
month_source_name(45, 'pera').
month_source_name(46, 'arco').
month_source_name(47, 'area').

canonical_cutlet_indices([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]).
canonical_month_indices([
    1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,
    25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
]).

cutlet_source_names(Names) :-
    canonical_cutlet_indices(Indices),
    names_from_indices(cutlet, Indices, Names).

month_source_names(Names) :-
    canonical_month_indices(Indices),
    names_from_indices(month, Indices, Names).

names_from_indices(_, [], []).
names_from_indices(cutlet, [I|Is], [Name|Names]) :-
    cutlet_source_name(I, Name),
    names_from_indices(cutlet, Is, Names).
names_from_indices(month, [I|Is], [Name|Names]) :-
    month_source_name(I, Name),
    names_from_indices(month, Is, Names).
