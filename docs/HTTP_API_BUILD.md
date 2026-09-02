# Aedificatio cicatricis HTTP

Cicatrix ut superpositio super ramum `Celeritas-per-Sepulcra` destinatur. Vetus modus aedificationis rami non removetur neque monstrum historicum reficitur.

## Dependentiae additivae

- C++20;
- Boost.Multiprecision (iam adest);
- Boost.Asio + Boost.Beast headers pro ministro HTTP;
- pthreads in POSIX.

`BOOST_ERROR_CODE_HEADER_ONLY` in ministro definitur, ita bibliotheca separata `boost_system` in toolchain probato non requiritur.

## Aedificatio commendata

Ex radice repository:

```sh
./build_http_api.sh
```

Scriptum `clang++` eligit, si adest; alioquin `g++`. Cum Clang adhibetur et `ld.lld` praesto est, linker `lld` automatice eligitur. Compilatio probata localiter cum Clang + lld realem `src/monster.cpp` coniunxit et ministrum operantem produxit.

Implicitum output est:

```text
pastafari-http
```

Exemplum cursus:

```sh
./pastafari-http 127.0.0.1 8080
```

Variabiles utiles:

```text
CXX                         compilator explicitus
OUTPUT                      via binarii output
PASTAFARI_HTTP_MONSTER_OPT  optimizatio monstri, valor implicitus -O2
PASTAFARI_HTTP_API_OPT      optimizatio strati API, valor implicitus -O2
PASTAFARI_HTTP_SERVER_OPT   optimizatio unitatis translationis Beast, valor implicitus -O0
PASTAFARI_HTTP_LINKER_FLAGS vexilla linker additiva
PASTAFARI_HTTP_MONSTER_OBJECT objectum monster.o iam probatum, ad iterationem localem tantum
```

`src/monster.cpp` admonitiones historicas suas retinet; cicatrix HTTP eas in errores compilationis non mutat. Translation units novi strati cum `-Werror` compilantur.

`PASTAFARI_HTTP_MONSTER_OBJECT` solum iterationem localem accelerat. CI obiectum praeparatum non praebet: `src/monster.cpp` ibi de novo compilatur.

## Probationes strati HTTP

```sh
tests/run_http_api_tests.sh
```

Probationes valore implicito `-O0` utuntur, quia optimizatio earum semanticae probationis nihil addit et compilationem formarum genericam inutiliter auget. Emendatio explicita:

```sh
PASTAFARI_HTTP_TEST_OPT=-O2 tests/run_http_api_tests.sh
```

## Probatio realis comprobata

In clone reali rami comprobata sunt:

- link contra verum `src/monster.cpp`;
- `/v1/health`;
- witness Foundation per socket HTTP;
- vocatio moderna directa `calendarDateSpaghetti(739861,739861)`;
- petitio moderna implicita per Kisurra et transitum inferiorem Veneris;
- `language=la`;
- reiectio `422 LANGUAGE_NOT_SUPPORTED` pro lingua nondum addita.

Latentia invocationis frigidae machinae non est stabilis. In una probatione moderna vocatio directa circiter 65.39 s et petitio HTTP frigida circiter 64.70 s postulaverunt; in probationibus posterioribus invocationes frigidae eiusdem diei 150–180 s excedere potuerunt. Eadem variatio in vocatione directa sine HTTP observata est, ideo strato presentationis aut Veneris non attribuitur. Nulla promissio latentiae v1 datur. Postquam `L0 Pair Tomb` eandem par `(c,t)` calefecit, repetitio statim reddi potest.

## TLS et parallelismus

Terminatio TLS publica extra processum (e.g. reverse proxy) fieri debet; monstrum officium TLS non accipit.

Unus processus/worker initio petitiones serialiter tractat. Hoc consulto contentionem cum cache/graveyard globalibus Celeritas vitat. Parallelismus fit pluribus processibus; unusquisque processum suum et cache calidum habet. Non fit hash per `calculationDay`, quia dies computationis implicitus plerisque petitionibus idem est et unum worker oneraret.

## CORS

Origo navigatoris implicite admissa est `https://bwtbdyqtmsprytgydym-cpu.github.io`. Allowlist ad distributionem mutatur per `PASTAFARI_CORS_ORIGINS`, originibus exactis commate separatis:

```sh
PASTAFARI_CORS_ORIGINS='https://calendar.example,https://admin.example' \
  ./pastafari-http 0.0.0.0 8080
```

Wildcard `*` non adhibetur. Si variabile definitur, valorem implicitum substituit. Petitiones sine `Origin` non impediuntur.
