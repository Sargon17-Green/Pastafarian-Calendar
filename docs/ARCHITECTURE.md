# તબક્કો 1નું નિષ્પક્ષ સ્થાપત્ય

આ તબક્કાનો હેતુ ભવિષ્યની જટિલતા પહેલેથી બનાવવાનો નથી. તેથી ઉત્પાદન ભાગમાં માત્ર ચાર નિષ્પક્ષ સ્તરો છે: invocation-માલિક context, dispatcher, validation/error boundary અને observability shell.

`BaseMonsterContext` દરેક invocation માટે નવો બને છે. તેમાં હાલ કોઈ bowl, drop, gate, year, structure અથવા patch-specific state નથી. આ મર્યાદા ઇરાદાપૂર્વક છે, કારણ કે ઐતિહાસિક state તે સંબંધિત discovery અથવા patch તબક્કે જ ઉમેરવાનું છે.

`MetricsShell` અને `LogShell` માત્ર અવલોકન માટે છે. તેઓ નોર્મેટિવ નિર્ણયના input નથી. `BaseValidationManager` હાલ માત્ર bootstrap invariants ચકાસે છે અને કોઈ semantic normalization કરતો નથી.

પરીક્ષણ oracle ઉત્પાદનથી અલગ છે. તે `test/normative_scroll.cr` માં છે અને ઉત્પાદન module દ્વારા require થતો નથી. ભવિષ્યમાં differential પરીક્ષણમાં expected મૂલ્ય આ oracle આપશે અને actual મૂલ્ય તે જ અમલરેખાના spaghetti માર્ગમાંથી આવશે.

આ તબક્કામાં recovery, cache, compatibility mode, ghost computation, alias, latch અથવા legacy path ઉમેરવામાં આવ્યા નથી, કારણ કે એમ કરવાથી ભવિષ્યના તબક્કાનો ઐતિહાસિક ક્રમ તૂટી જાય.
