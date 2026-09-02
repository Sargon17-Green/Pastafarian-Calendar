# Bootstrap архитектур

Stage 1 нь ирээдүйн түүхэн алдааг урьдчилан бүтээхгүй. Одоогийн production суурь дөрвөн саармаг үүрэгтэй:

1. Нэг invocation-д харьяалагдах `monster_context` үүсгэх.
2. `base_dispatch`-аар bootstrap үе шатыг дамжуулах.
3. `validate_bootstrap_context`-оор хамгийн суурь invariant шалгах.
4. Metric, log, validation code хадгалах талбаруудыг норматив тооцоонд буцааж уншихгүй байх.

Semantic state нь invocation хооронд хуваалцахгүй. Stage 1-д global mutable semantic cache байхгүй. Oracle нь `test/` дотор тусдаа бөгөөд production модуль түүн рүү хамаарахгүй.

Энэ суурь зориуд жижиг боловч дараагийн DISCOVERY/PATCH шат бүрт зөвхөн тухайн түүхэн давхаргыг нэмж өсгөх боломжтой.
