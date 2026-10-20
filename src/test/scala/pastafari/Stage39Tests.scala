package pastafari

import pastafari.monster._
import pastafari.catalog.SourceLanguageCatalog
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH19: il nome italiano dipende dal mese tessuto, non dal giorno. */
object Stage39Tests {
  private var passed=0
  private var failed=0
  private val A=Vector.fill(84)(1)++Vector.fill(84)(2)++Vector.fill(84)(3)
  private val B=Vector(1,2)++Vector.fill(83)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)
  private val C=Vector(1,1,2)++Vector.fill(82)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)
  private val Q=(1 to 47).flatMap(i=>Vector.fill(6)(i)).toVector
  private val First=Vector(1,2,3)
  private val All=(1 to 47).toVector
  private val Huge=(BigInt(1)<<16384)+39102026

  private def check(label:String)(run: => Unit):Unit={
    try {run;passed+=1;println("PASS — "+label)}
    catch {case error:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+error.getMessage)
      error.printStackTrace(System.out)}
  }
  private def eqv[T](got:T,want:T,label:String):Unit={
    if(got!=want)throw new AssertionError(
      label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(value:Boolean,label:String):Unit={
    if(!value)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(run: => Unit):Unit={
    var rejected=false
    try run catch {case _:IllegalArgumentException=>rejected=true}
    truth(rejected,label+": argomento illecito accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit={
    var rejected=false
    try run catch {case _:IllegalStateException=>rejected=true}
    truth(rejected,label+": stato illecito accettato")
  }
  private def patched(
    w:Vector[Int]=A,ids:Vector[Int]=First,day:Int=1
  ):Patch19DayIndexedMonthNameResult =
    Patch19DayIndexedMonthNameWrapper.dayIndexedNamePatch(w,ids,day)
  private def manager(
    w:Vector[Int]=A,ids:Vector[Int]=First,day:Int=1
  ):Patch19DayIndexedMonthNameReport =
    new BaseMonsterManager().patch19DayIndexedMonthName(Huge,-Huge,w,ids,day)

  // Oracolo test-only: scansione del catalogo per chiave canonica,
  // senza chiamare il wrapper, il manager o SourceLanguageCatalog.month.
  private def reference(w:Vector[Int],ids:Vector[Int],day:Int):String={
    val id=ids(w(day)-1)
    val hits=SourceLanguageCatalog.Months.filter(_.canonicalIndex==id)
    eqv(hits.length,1,"Chiave canonica univoca")
    hits.head.italian
  }
  private def uniform(n:Int):Vector[Int]={
    val days=math.max(6,(252+n-1)/n)
    (1 to n).flatMap(i=>Vector.fill(days)(i)).toVector
  }
  private def ready(
    w:Vector[Int]=C,ids:Vector[Int]=First,day:Int=2
  ):BaseMonsterContext={
    val ctx=BaseMonsterContext(Huge,-Huge)
    ctx.status="BOOTSTRAPPED"
    ctx.branchTrace.append("BOOT")
    ctx.phase="DISCOVERY_19_DAY_INDEXED_MONTH_NAME"
    ctx.dayNameWeaving=Some(w)
    ctx.dayNameCanonicalIndices=Some(ids)
    ctx.dayNameOffset=Some(day)
    val metrics=new BaseMetricsShell
    new Discovery19DayIndexedMonthNameHandler(metrics).handle(ctx)
    new BaseValidationManager().requireDiscovery19Ready(ctx)
    ctx.phase="PATCH_19_DAY_INDEXED_MONTH_NAME"
    new Patch19DayIndexedMonthNameHandler(metrics).handle(ctx)
    ctx
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }

  def main(args:Array[String]):Unit={
    check("il catalogo congelato contiene 47 indici consecutivi"){
      eqv(SourceLanguageCatalog.Months.map(_.canonicalIndex),All,"Indici")
    }
    check("il catalogo italiano conserva argilla melagrana gomito"){
      eqv(First.map(SourceLanguageCatalog.month(_).italian),
        Vector("argilla","melagrana","gomito"),"Nomi")
    }
    check("il giorno zero mantiene il nome del primo mese"){
      eqv(patched(A,First,0).correctedItalianMonthName,"argilla","Zero")
    }
    check("il giorno uno del primo mese non diventa melagrana"){
      val r=patched()
      eqv(r.correctedMonthId,1,"Mese")
      eqv(r.correctedItalianMonthName,"argilla","Corretto")
      eqv(r.historical.legacyItalianMonthName,"melagrana","Storico")
    }
    check("il giorno 2 della tessitura C usa il mese reale 2"){
      val r=patched(C,First,2)
      eqv(r.correctedMonthId,2,"Mese")
      eqv(r.correctedItalianMonthName,"melagrana","Corretto")
      eqv(r.historical.legacyItalianMonthName,"gomito","Cicatrice")
    }
    check("il giorno 46 della tessitura Q usa il mese 8"){
      val r=patched(Q,All,46)
      eqv(r.correctedMonthId,8,"Mese")
      eqv(r.correctedItalianMonthName,reference(Q,All,46),"Nome")
      eqv(r.historical.legacyItalianMonthName,"sabbia","Storico")
    }
    check("l'ultimo giorno dell'anno di 47 mesi usa il mese 47"){
      val r=patched(Q,All,281)
      eqv(r.correctedMonthId,47,"Mese")
      eqv(r.correctedItalianMonthName,"sabbia","Nome")
    }
    check("due giorni nello stesso mese non cambiano nome"){
      eqv(patched(A,First,0).correctedItalianMonthName,
        patched(A,First,1).correctedItalianMonthName,"Identità")
    }
    check("l'intercalazione dei mesi cambia correttamente il nome"){
      eqv(patched(B,First,1).correctedItalianMonthName,
        "melagrana","Intercalazione")
    }
    check("l'apertura C 1-2-1 riusa il nome del primo mese"){
      eqv(patched(C,First,3).correctedItalianMonthName,
        "argilla","Ritorno")
    }
    check("tutti i 252 giorni della tessitura A coincidono con l'oracolo"){
      for(day<-A.indices)
        eqv(patched(A,First,day).correctedItalianMonthName,
          reference(A,First,day),"A "+day)
    }
    check("tutti i 252 giorni della tessitura B coincidono con l'oracolo"){
      for(day<-B.indices)
        eqv(patched(B,First,day).correctedItalianMonthName,
          reference(B,First,day),"B "+day)
    }
    check("tutti i 252 giorni della tessitura C coincidono con l'oracolo"){
      for(day<-C.indices)
        eqv(patched(C,First,day).correctedItalianMonthName,
          reference(C,First,day),"C "+day)
    }
    check("tutti i 282 giorni della tessitura Q coincidono con l'oracolo"){
      for(day<-Q.indices)
        eqv(patched(Q,All,day).correctedItalianMonthName,
          reference(Q,All,day),"Q "+day)
    }
    check("tutte le 45 cardinalità da 3 a 47 hanno nome corretto"){
      for(n<-3 to 47){
        val w=uniform(n)
        val ids=All.take(n)
        for(day<-Vector(0,1,5,w.length/2,w.length-1))
          eqv(patched(w,ids,day).correctedItalianMonthName,
            reference(w,ids,day),"n="+n+" day="+day)
      }
    }
    check("4096 permutazioni deterministiche di nomi ed offset"){
      val rng=new Random(39102026L)
      for(i<-1 to 4096){
        val n=3+rng.nextInt(45)
        val ids=rng.shuffle(All).take(n).toVector
        val w=uniform(n)
        val day=rng.nextInt(w.length)
        val r=patched(w,ids,day)
        eqv(r.correctedItalianMonthName,reference(w,ids,day),"Norma "+i)
        eqv(r.historical.legacyItalianMonthName,
          SourceLanguageCatalog.Months.find(
            _.canonicalIndex==ids(day%n)).get.italian,"Legacy "+i)
        eqv(r.historical.selectedMonthId,w(day),"Mese "+i)
        eqv(r.historical.legacyNameSlot,day%n,"Slot "+i)
      }
    }
    check("il vecchio adapter rimane identico prima e dopo la patch"){
      for((w,ids,d)<-Vector((A,First,1),(C,First,2),(Q,All,46))){
        eqv(patched(w,ids,d).historical,
          LegacyDayIndexedMonthNameAdapter.oldDayIndexedMonthName(w,ids,d),
          "Storico")
      }
    }
    check("la versione del catalogo è identica nella traccia storica"){
      eqv(patched().historical.frozenCatalogVersion,
        SourceLanguageCatalog.Version,"Versione")
    }
    check("la patch non modifica il catalogo sorgente"){
      val before=SourceLanguageCatalog.Months
      patched(Q,All,46)
      eqv(SourceLanguageCatalog.Months,before,"Catalogo")
    }
    check("richieste intercalate non mutano il risultato"){
      val first=patched(C,First,2)
      patched(Q,All,46)
      patched(A,First,251)
      eqv(patched(C,First,2),first,"Determinismo")
    }
    check("i numeri enormi del manager non sono troncati"){
      val r=manager()
      eqv(r.calculationDay,Huge,"Calcolo")
      eqv(r.targetDay,-Huge,"Bersaglio")
    }
    check("il manager conserva i dati in ingresso e lo snapshot"){
      val r=manager(C,First,2)
      eqv(r.annualWeaving,C,"Weave")
      eqv(r.canonicalMonthNameIndices,First,"ID")
      eqv(r.dayOffset,2,"Offset")
    }
    check("il manager passa davvero dalla diagnosi alla patch"){
      val r=manager(C,First,2)
      eqv(r.phase,"PATCH_19_DAY_INDEXED_MONTH_NAME","Fase")
      eqv(r.status,"PATCH_19_READY","Stato")
      eqv(r.trace,Vector("BOOT",
        "DISCOVERY_19_DAY_INDEXED_MONTH_NAME",
        "PATCH_19_DAY_INDEXED_MONTH_NAME"),"Trace")
      truth(r.patchApplied,"Flag")
      eqv(r.legacyItalianMonthName,"gomito","Legacy")
      eqv(r.correctedItalianMonthName,"melagrana","Corretto")
    }
    check("il manager conserva i contatori indipendenti delle fasi"){
      val m=new BaseMonsterManager
      m.patch19DayIndexedMonthName(1,2,C,First,2)
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery19.day.name.calls"),BigInt(1),
        "Discovery")
      eqv(m.metricsSnapshot("patch19.day.name.calls"),BigInt(1),"Patch")
    }
    check("due manager non condividono contatori"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      a.patch19DayIndexedMonthName(1,2,A,First,1)
      b.patch19DayIndexedMonthName(3,4,C,First,2)
      eqv(a.metricsSnapshot("patch19.day.name.calls"),BigInt(1),"A")
      eqv(b.metricsSnapshot("patch19.day.name.calls"),BigInt(1),"B")
    }
    check("richieste multiple non sovrascrivono vecchi report"){
      val m=new BaseMonsterManager
      val first=m.patch19DayIndexedMonthName(1,2,C,First,2)
      val before=first.copy()
      m.patch19DayIndexedMonthName(3,4,Q,All,46)
      eqv(first,before,"Primo")
      eqv(m.metricsSnapshot("patch19.day.name.calls"),BigInt(2),"Numero")
    }
    check("input con meno di tre indici è respinto"){
      rejectArg("Due"){patched(A,Vector(1,2),1)}
    }
    check("indici canonici duplicati sono respinti"){
      rejectArg("Duplicati"){patched(A,Vector(1,1,2),1)}
    }
    check("indice zero è respinto"){
      rejectArg("Zero"){patched(A,Vector(0,2,3),1)}
    }
    check("indice 48 è respinto"){
      rejectArg("48"){patched(A,Vector(1,2,48),1)}
    }
    check("offset negativo è respinto"){
      rejectArg("Negativo"){patched(A,First,-1)}
    }
    check("offset alla fine è respinto"){
      rejectArg("Fine"){patched(A,First,252)}
    }
    check("tessitura troppo breve è respinta"){
      rejectArg("Breve"){patched(Vector(1,2,3),First,0)}
    }
    check("mesi con meno di sei giorni sono respinti"){
      rejectArg("Durata"){patched(Vector.fill(250)(1)++Vector(2,3),
        First,0)}
    }
    check("ordine errato della tessitura è respinto"){
      rejectArg("Ordine"){patched(Vector.fill(84)(2)++
        Vector.fill(84)(1)++Vector.fill(84)(3),First,0)}
    }
    check("il validator indipendente conferma uno stato integro"){
      new BaseValidationManager().requirePatch19Ready(ready())
    }
    check("il validator rifiuta un nome corretto falsificato"){
      val c=ready();c.dayNamePatchedItalian=Some("gomito")
      rejectState("Nome"){new BaseValidationManager().requirePatch19Ready(c)}
    }
    check("il validator rifiuta la vecchia cicatrice falsificata"){
      val c=ready();c.dayNameLegacyItalian=Some("argilla")
      rejectState("Storico"){new BaseValidationManager().requirePatch19Ready(c)}
    }
    check("il validator rifiuta il mese errato"){
      val c=ready();c.dayNameLegacyMonthId=Some(3)
      rejectState("Mese"){new BaseValidationManager().requirePatch19Ready(c)}
    }
    check("il validator rifiuta uno slot errato"){
      val c=ready();c.dayNameLegacySlot=Some(0)
      rejectState("Slot"){new BaseValidationManager().requirePatch19Ready(c)}
    }
    check("il validator rifiuta snapshot alterata"){
      val c=ready();c.dayNameOffset=Some(1)
      rejectState("Snapshot"){new BaseValidationManager().requirePatch19Ready(c)}
    }
    check("il validator rifiuta versione errata"){
      val c=ready();c.dayNameFrozenVersion=Some("wrong")
      rejectState("Versione"){new BaseValidationManager().requirePatch19Ready(c)}
    }
    check("il validator rifiuta trace alterata"){
      val c=ready();c.branchTrace.append("INTRUSO")
      rejectState("Trace"){new BaseValidationManager().requirePatch19Ready(c)}
    }
    check("il validator rifiuta flag di patch rimosso"){
      val c=ready();c.patch19Applied=false
      rejectState("Flag"){new BaseValidationManager().requirePatch19Ready(c)}
    }
    check("il validator rifiuta stato errato"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Stato"){new BaseValidationManager().requirePatch19Ready(c)}
    }
    check("l'handler non accetta il salto della fase discovery"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="PATCH_19_DAY_INDEXED_MONTH_NAME"
      c.dayNameWeaving=Some(A)
      c.dayNameCanonicalIndices=Some(First)
      c.dayNameOffset=Some(1)
      rejectState("Bootstrap"){new Patch19DayIndexedMonthNameHandler(
        new BaseMetricsShell).handle(c)}
      truth(c.dayNamePatchedItalian.isEmpty,"Nessuna pubblicazione")
    }
    check("l'handler rifiuta mutazione dopo discovery"){
      val c=ready()
      c.phase="DISCOVERY_19_DAY_INDEXED_MONTH_NAME"
      c.status="LEGACY_DAY_INDEXED_MONTH_NAME_READY"
      c.branchTrace.remove(2)
      c.dayNameOffset=Some(5)
      rejectState("Mutazione"){new Patch19DayIndexedMonthNameHandler(
        new BaseMetricsShell).handle(c)}
    }
    check("PATCH18 conserva la ricerca canonica e l'errore vecchio"){
      val r=new BaseMonsterManager().patch18SourceCatalogIndex(
        0,0,Vector(46,47,1))
      eqv(r.correctedItalianMonthNames,
        Vector("arco","sabbia","argilla"),"PATCH18")
      eqv(r.legacyItalianMonthNames,
        Vector("sabbia","argilla","melagrana"),"Discovery18")
    }
    check("PATCH17 continua a scegliere tre nomi distinti"){
      eqv(new BaseMonsterManager().patch17DistinctMonthName(
        0,0,3,1).correctedCanonicalNameIndices,First,"PATCH17")
    }
    check("il difetto DISCOVERY19 rimane osservabile e indipendente"){
      val r=new BaseMonsterManager().discover19DayIndexedMonthName(
        1,2,C,First,2)
      eqv(r.legacyItalianMonthName,"gomito","Cicatrice")
      eqv(r.selectedMonthId,2,"Tessitura reale")
    }
    check("nessun oracolo test è importato nel codice produttivo"){
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Oracolo test")
      truth(sources.contains("def oldDayIndexedMonthName("),"Cicatrice")
      truth(sources.contains("def dayIndexedNamePatch("),"PATCH19")
    }
    check("Stage38 è certificato prima dell'ingresso in Stage39"){
      val st=new String(Files.readAllBytes(root().resolve(
        "DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(st.contains(
        "STAGE_38_NATIVE_VERIFICATION=PASS_EXPECTED_RED_45_PASS_3_FAIL"),
        "Firma RED storica")
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .get.split("=",2)(1).toInt
      truth(current>=39,"Stage39 presente")
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .get.split("=",2)(1).toInt
      truth(done>=38 && done<=current,"Progresso non inventato")
    }
    println("\nRISULTATO STADIO 39: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
