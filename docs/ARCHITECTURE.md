# Arkitektura hanggang Stage 22

```text
46 drop rounds:
    current bowls
    -> Patch 09 current-bowl pours
    -> Patch 10 snapshot/pending bowl update
    -> write current drop order to ONE general order memory

after drop 46:
    capture bowls-after-46
    but DO NOT latch drop-46 order separately

12 post-stir rounds:
    savedStirSum = SAVE(sum(old bowls 1..6) + 149*stir)
    order = patchedOrderFromDrop(savedStirSum)
    compute six bowls from old snapshot into pending
    write stir order to THE SAME general order memory

query:
    return last general order memory
    -> therefore returns stir-12 order, not drop-46 order
```

Kabuuang order-memory writes: 46 + 12 = 58.

Wala pang `orderAt46Latch`; iyon ang susunod na patch. Wala ring Patch 12 next-bowl logic.
