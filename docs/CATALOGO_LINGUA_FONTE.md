# Catálogo da lingua fonte

A lingua humana canónica deste ramo é o galego. O catálogo queda conxelado na versión `1.0.0` durante o Stage 1.

A orde normativa non depende nunca do texto galego. Cada nome conserva un `canonicalIndex` fixo, e os algoritmos de selección, rango e desrango traballan exclusivamente con eses índices. A cadea galega resólvese só na capa de presentación do resultado.

Os nomes con significado léxico tradúcense polo seu significado. Os nomes propios, topónimos e secuencias inventadas sen significado léxico tradúcense por transliteración estable. Para estes nomes, a regra deste ramo é conservar unha forma latina recoñecible e estable, sen introducir unha interpretación semántica nova. Esa decisión afecta só á presentación.

Os nomes fraccionarios tradúcense como unha única expresión completa. Ningunha ordenación alfabética, regra Unicode, colación local nin cambio futuro de locale pode alterar a orde canónica.

Os índices de katsuletas son `1..17`; os índices de meses son `1..47`. O ficheiro `src/source_language_catalog.pl` é a fonte executable conxelada deste catálogo.

Para as secuencias inventadas escritas no material de partida, a consoante fricativa final representada como `sh` mantense como `sh` na forma latina conxelada. Non se aplican regras de colación nin de normalización fonética para reconstruír índices; a transliteración é só texto de presentación.
