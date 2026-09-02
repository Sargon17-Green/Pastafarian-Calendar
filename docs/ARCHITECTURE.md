# Arhitektūra pēc 1. posma

Ražošanas puse pagaidām ir skelets. Katram izsaukumam tiek veidots atsevišķs konteksts. Semantiskais stāvoklis pieder tikai šim kontekstam; metriku un žurnāla dati ir novērojamības stāvoklis un nav izmantojami lēmumos par normatīvo rezultātu.

Bāzes dispečers pieņem fāzes identifikatoru un izsauc reģistrētu apstrādātāju. Pirmajā posmā nav reģistrēts neviens vēsturiska ielāpa apstrādātājs. Validācijas pārvaldnieks drīkst tikai apstiprināt invariantu vai izraisīt kļūdu. Atkopšanas karkass drīkstēs vēlāk atjaunot precīzu apstiprinātu momentuzņēmumu, bet šajā posmā tam nav semantiska algoritma.

Testu pusē atrodas atsevišķs tīrs normatīvais etalons. Tas nav ražošanas atkarība un netiek ielādēts no `src/` failiem.
