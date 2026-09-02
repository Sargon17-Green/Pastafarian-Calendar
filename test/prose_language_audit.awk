# Denne kontrollen avviser hebraiske UTF-8-byte i prosjekttekst som skal vere nynorsk.

BEGIN { bad=0; b214=sprintf("%c",214); b215=sprintf("%c",215) }
{
    if (FILENAME ~ /DEVELOPMENT_STAGE.md$/ && index($0,"NATURAL_LANGUAGE=")==1) next
    if (index($0,b214)>0 || index($0,b215)>0) {
        printf("FEIL | hebraisk byte funnen i %s:%d\n",FILENAME,FNR)
        bad++
    }
}
END {
    if (bad==0) print "OK | ingen hebraisk skrift i menneskeskapt prosjekttekst"
    exit(bad==0?0:1)
}
