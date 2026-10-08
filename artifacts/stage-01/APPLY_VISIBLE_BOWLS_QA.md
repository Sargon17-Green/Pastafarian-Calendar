# `Stage 1` — §8.2 visible drop -> bowls QA

Күн: 2026-10-07

`reference/apply_visible_to_bowls.b98` Appendix A §8.2 функциясынын түз Befunge reference'и.

## Киргизүү

- алты баштапкы кесе;
- андан кийин 46 жазуу: `drop` жана ошол drop үчүн беш таш.

## Чыгыш

- 46-drop иштетүүдөн кийинки алты кесе;
- `orderAtDrop46` алты идентификатору.

## Эсептик текшерүү

Үч көз карандысыз синтетикалык толук 46-drop учур түзүлдү. Ар биринде алты баштапкы кесе, 46 drop жана 46×5 таш мааниси `1..M` аралыгында болду.

Befunge control-flow/Funge-space модели Appendix Aдагы түз §8.2 формуласы менен салыштырылды.

```text
FULL_CASES=3
DROPS_PER_CASE=46
FINAL_BOWL_VALUES=18
ORDER_VALUES=18
DIFFERENCES=0
```

QA учурунда candidate'те эки ката табылып, репозиторийге жазылганга чейин оңдолду:

1. visible drop timeline'га сактоо кадамы жетишпей калган;
2. scratch x=10..13 даректери `10` сыяктуу текст менен туура эмес коддолгон; Befunge'де бул ондук 10 эмес, эки өзүнчө digit push. Даректер Befunge бүтүн сан expression'дери менен кайра коддолду.

Бутактагы `apply_visible_to_bowls.b98` — ушул эки оңдоодон кийинки, 3/3 толук учурду өткөн нуска.

Бул native Befunge PASS эмес.
