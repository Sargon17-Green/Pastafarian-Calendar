# Povijest razvoja špagetnog čudovišta

## Etapa 1 — početno postavljanje

Odabrani su Oz kao jedini programski jezik i hrvatski kao jedini ljudski izvorni jezik ove implementacijske linije.

Iz ugrađenoga normativnog dodatka izgrađen je zaseban hrvatski `SourceLanguageCatalog` s 17 naziva kotleta i 47 naziva mjeseci. Semantički poredak čuva se isključivo preko nepromjenjivoga `canonicalIndex`.

Proizvodni sloj dobio je samo neutralni kontekst jedne invokacije, osnovnu validaciju, osnovni usmjerivač, omatanje pogreške kroz eksplicitne Oz iznimke te prazne promatračke spremnike. Nisu uvedene buduće povijesne pogreške, zastavice ni popravci.

Čisti normativni referentni algoritam nalazi se samo u testnom stablu i nije dostupan proizvodnoj funkciji `CalendarDateSpaghetti`.

Lokalno izvršavanje još nije dokazano jer u raspoloživom okruženju nema Oz/Mozart izvršnoga okruženja. Zbog toga ova etapa još nije označena kao dovršena, iako je predajni paket izvornih datoteka pripremljen.
