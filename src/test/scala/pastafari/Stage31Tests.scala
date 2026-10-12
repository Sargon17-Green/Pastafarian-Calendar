package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 15: una tessitura scelta una volta per l'intero anno. */
object Stage31Tests {
  private var passed=0
  private var failed=0
  private val A=Vector.fill(84)(1)++Vector.fill(84)(2)++Vector.fill(84)(3)
  private val C=Vector(1,1,2)++Vector.fill(82)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)
  private val B=Vector(1,2)++Vector.fill(83)(1)++
    Vector.fill(83)(2)++Vector.fill(84)(3)
  private val Weaves=Vector(A,C,B)

  private def check(label:String)(run: => Unit):Unit={
    try {run;passed+=1;println("PASS — "+label)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+label+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit={
    if(got!=want)throw new AssertionError(
      label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(ok:Boolean,label:String):Unit={
    if(!ok)throw new AssertionError(label)
  }
  private def rejectArg(label:String)(run: => Unit):Unit={
    var caught=false
    try run catch {case _:IllegalArgumentException=>caught=true}
    truth(caught,label+": argomento illegale accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit={
    var caught=false
    try run catch {case _:IllegalStateException=>caught=true}
    truth(caught,label+": stato invalido accettato")
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    p
  }
  private def normWeave(rank:BigInt,
                        family:Vector[Vector[Int]]=Weaves):Vector[Int]=
    family((rank-1).toInt)
  private def normMonth(rank:BigInt,day:Int,
                        family:Vector[Vector[Int]]=Weaves):Int=
    normWeave(rank,family)(day)
  private def normDay(rank:BigInt,day:Int,
                      family:Vector[Vector[Int]]=Weaves):Int={
    val w=normWeave(rank,family)
    val m=w(day)
    (0 to day).count(i=>w(i)==m)
  }
  private def patched(rank:BigInt=1,day:Int=0,
                      family:Vector[Vector[Int]]=Weaves):
      Patch15MonthWeavingResult=
    Patch15MonthWeavingWrapper.daywiseWeavingPatch(family,rank,day)
  private def ready(rank:BigInt=1,day:Int=0,
                    family:Vector[Vector[Int]]=Weaves):BaseMonsterContext={
    val c=BaseMonsterContext(43,-9181)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_15_DAYWISE_WEAVING"
    c.daywiseCandidateWeavings=Some(family)
    c.daywiseYearRank1=Some(rank)
    c.daywiseOffset=Some(day)
    new Discovery15DaywiseWeavingHandler(new BaseMetricsShell).handle(c)
    c.phase="PATCH_15_DAYWISE_WEAVING"
    new Patch15MonthWeavingHandler(new BaseMetricsShell).handle(c)
    c
  }
  private def singleInsertion(position:Int):Vector[Int]=
    Vector.fill(position)(1)++Vector(2)++Vector.fill(84-position)(1)++
      Vector.fill(83)(2)++Vector.fill(84)(3)

  def main(args:Array[String]):Unit={
    check("prima selezione annuale, giorno zero, mese primo"){
      val r=patched()
      eqv(r.fixedAnnualWeaving,A,"Tessitura")
      eqv(r.correctedMonthId,1,"Mese")
      eqv(r.correctedDayInMonth,1,"Giorno")
    }
    check("seconda selezione annuale, giorno zero"){
      val r=patched(2)
      eqv(r.fixedAnnualWeaving,C,"Tessitura")
      eqv(r.correctedMonthId,1,"Mese")
      eqv(r.correctedDayInMonth,1,"Giorno")
    }
    check("terza selezione annuale, giorno zero"){
      val r=patched(3)
      eqv(r.fixedAnnualWeaving,B,"Tessitura")
      eqv(r.correctedMonthId,1,"Mese")
      eqv(r.correctedDayInMonth,1,"Giorno")
    }
    check("la vecchia selezione al giorno uno diverge per rango due"){
      val r=patched(2,1)
      eqv(r.historical.dayRank1,BigInt(3),"Rango storico")
      eqv(r.historical.monthId,2,"Vecchio mese")
      eqv(r.correctedMonthId,1,"Mese corretto")
      eqv(r.correctedDayInMonth,2,"Giorno nel mese")
    }
    check("la vecchia selezione al giorno uno diverge per rango tre"){
      val r=patched(3,1)
      eqv(r.historical.dayRank1,BigInt(1),"Rango storico")
      eqv(r.historical.monthId,1,"Vecchio mese")
      eqv(r.correctedMonthId,2,"Mese corretto")
      eqv(r.correctedDayInMonth,1,"Giorno nel mese")
    }
    check("la vecchia selezione al giorno due diverge per rango tre"){
      val r=patched(3,2)
      eqv(r.historical.dayRank1,BigInt(2),"Rango storico")
      eqv(r.historical.monthId,2,"Vecchio mese")
      eqv(r.correctedMonthId,1,"Mese corretto")
      eqv(r.correctedDayInMonth,2,"Giorno nel mese")
    }
    check("l'evento precoce di C al giorno due e' il primo giorno del secondo mese"){
      val r=patched(2,2)
      eqv(r.correctedMonthId,2,"Mese")
      eqv(r.correctedDayInMonth,1,"Primo giorno mensile")
    }
    check("il ritorno al mese uno in C continua la sua numerazione"){
      val r=patched(2,3)
      eqv(r.correctedMonthId,1,"Mese")
      eqv(r.correctedDayInMonth,3,"Contatore discontinuo")
    }
    check("il ritorno al mese uno in B continua la sua numerazione"){
      val r=patched(3,2)
      eqv(r.correctedMonthId,1,"Mese")
      eqv(r.correctedDayInMonth,2,"Contatore")
    }
    check("il primo mese di A finisce al giorno 83"){
      val r=patched(1,83)
      eqv(r.correctedMonthId,1,"Mese")
      eqv(r.correctedDayInMonth,84,"Ultimo")
    }
    check("il secondo mese di A comincia al giorno 84"){
      val r=patched(1,84)
      eqv(r.correctedMonthId,2,"Mese")
      eqv(r.correctedDayInMonth,1,"Primo")
    }
    check("il secondo mese di A finisce al giorno 167"){
      val r=patched(1,167)
      eqv(r.correctedMonthId,2,"Mese")
      eqv(r.correctedDayInMonth,84,"Ultimo")
    }
    check("il terzo mese di A comincia al giorno 168"){
      val r=patched(1,168)
      eqv(r.correctedMonthId,3,"Mese")
      eqv(r.correctedDayInMonth,1,"Primo")
    }
    check("l'anno A finisce con il giorno 84 del terzo mese"){
      val r=patched(1,251)
      eqv(r.correctedMonthId,3,"Mese")
      eqv(r.correctedDayInMonth,84,"Ultimo")
    }
    check("l'ultimo giorno C non dipende dal rango legacy variabile"){
      val r=patched(2,251)
      eqv(r.correctedMonthId,3,"Mese")
      eqv(r.correctedDayInMonth,84,"Giorno")
      eqv(r.fixedAnnualWeaving,C,"Tessitura")
    }
    check("l'ultimo giorno B non dipende dal rango legacy variabile"){
      val r=patched(3,251)
      eqv(r.correctedMonthId,3,"Mese")
      eqv(r.correctedDayInMonth,84,"Giorno")
      eqv(r.fixedAnnualWeaving,B,"Tessitura")
    }
    check("il rango annuale non dipende mai dall'indice del giorno"){
      for(rank<-1 to 3;day<-0 until 252)
        eqv(patched(rank,day).fixedAnnualWeaving,
          normWeave(rank),"Rango="+rank+" Giorno="+day)
    }
    check("tutti i 756 mesi corretti coincidono con il riferimento"){
      for(rank<-1 to 3;day<-0 until 252)
        eqv(patched(rank,day).correctedMonthId,
          normMonth(rank,day),"Rango="+rank+" Giorno="+day)
    }
    check("tutti i 756 giorni mensili corretti coincidono con il riferimento"){
      for(rank<-1 to 3;day<-0 until 252)
        eqv(patched(rank,day).correctedDayInMonth,
          normDay(rank,day),"Rango="+rank+" Giorno="+day)
    }
    check("tutte le 756 selezioni legacy conservano la cicatrice"){
      for(rank<-1 to 3;day<-0 until 252)
        eqv(patched(rank,day).historical,
          LegacyDaywiseWeavingAdapter.legacyChooseEachDaySeparately(
            Weaves,rank,day),"Legacy="+rank+" Day="+day)
    }
    check("ognuno dei 252 giorni mantiene le durate 84,84,84"){
      for(rank<-1 to 3){
        val ids=(0 until 252).map(day=>patched(rank,day).correctedMonthId)
        eqv((1 to 3).map(i=>ids.count(_==i)).toVector,
          Vector(84,84,84),"Rank "+rank)
      }
    }
    check("i contatori interni hanno 1..84 senza duplicati o salti"){
      for(rank<-1 to 3){
        val daily=(0 until 252).map(day=>{
          val p=patched(rank,day);(p.correctedMonthId,p.correctedDayInMonth)
        })
        for(m<-1 to 3)
          eqv(daily.collect{case (id,count) if id==m => count}.sorted.toVector,
            (1 to 84).toVector,"Mese "+m+" Rango "+rank)
      }
    }
    check("la tessitura resta identica anche dopo chiamate intercalate"){
      val r=patched(3,2)
      for(day<-0 until 252)patched(2,day)
      eqv(patched(3,2),r,"Report non mutato")
      eqv(Weaves,Vector(A,C,B),"Input non mutati")
    }
    check("famiglia con unico candidato non cambia il risultato legacy"){
      for(day<-0 until 252){
        val r=patched(1,day,Vector(A))
        eqv(r.correctedMonthId,r.historical.monthId,"Mese "+day)
        eqv(r.correctedDayInMonth,normDay(1,day,Vector(A)),"Giorno "+day)
      }
    }
    check("ventiquattro tessiture ordinate possiedono ranghi stabili"){
      val family=(1 to 24).reverse.map(singleInsertion).toVector
      LegacyDaywiseWeavingAdapter.validateCandidates(family)
      for(rank<-1 to family.size;day<-Vector(0,1,2,83,84,85,168,251)){
        val r=patched(rank,day,family)
        eqv(r.fixedAnnualWeaving,family(rank-1),"Rango "+rank)
        eqv(r.correctedMonthId,normMonth(rank,day,family),"Mese "+day)
        eqv(r.correctedDayInMonth,normDay(rank,day,family),"Giorno "+day)
      }
    }
    check("4096 vettori deterministici su 24 tessiture concordano"){
      val family=(1 to 24).reverse.map(singleInsertion).toVector
      val rng=new Random(31102026L)
      for(i<-1 to 4096){
        val rank=1+rng.nextInt(family.length)
        val day=rng.nextInt(252)
        val r=patched(rank,day,family)
        eqv(r.correctedMonthId,normMonth(rank,day,family),"Mese "+i)
        eqv(r.correctedDayInMonth,normDay(rank,day,family),"Giorno "+i)
        eqv(r.historical,LegacyDaywiseWeavingAdapter.legacyChooseEachDaySeparately(
          family,rank,day),"Vecchio "+i)
      }
    }
    check("una tessitura legale lunga 369 giorni produce contatori 123"){
      val w=Vector.fill(123)(1)++Vector.fill(123)(2)++
        Vector.fill(123)(3)
      val r=patched(1,368,Vector(w))
      eqv(r.fixedAnnualWeaving,w,"Tessitura")
      eqv(r.correctedMonthId,3,"Mese")
      eqv(r.correctedDayInMonth,123,"Durata")
    }
    check("quarantasette mesi ammessi mantengono il contatore"){
      val w=(1 to 47).flatMap(x=>Vector.fill(6)(x)).toVector
      val r=patched(1,281,Vector(w))
      eqv(r.correctedMonthId,47,"Mese")
      eqv(r.correctedDayInMonth,6,"Contatore")
    }
    check("un anno lungo con 5778 giorni e' esattamente al limite"){
      val w=(1 to 46).flatMap(x=>Vector.fill(123)(x)).toVector++
        Vector.fill(120)(47)
      val r=patched(1,5777,Vector(w))
      eqv(w.length,5778,"Massimo normativo")
      eqv(r.correctedMonthId,47,"Mese")
      eqv(r.correctedDayInMonth,120,"Giorno")
    }
    check("la famiglia vuota viene respinta senza pubblicazione"){
      rejectArg("Vuota"){patched(1,0,Vector.empty)}
    }
    check("un rango nullo viene respinto"){
      rejectArg("Zero"){patched(0)}
    }
    check("un rango negativo viene respinto"){
      rejectArg("Negativo"){patched(-1)}
    }
    check("un rango oltre la famiglia viene respinto"){
      rejectArg("Alto"){patched(4)}
    }
    check("un giorno negativo viene respinto"){
      rejectArg("Negativo"){patched(1,-1)}
    }
    check("un giorno oltre 251 in anno minimo viene respinto"){
      rejectArg("Fuori"){patched(1,252)}
    }
    check("le durate inferiori a quattro giorni vengono respinte"){
      val invalid=Vector(1,2,3)++Vector.fill(249)(3)
      rejectArg("Mese breve"){patched(1,0,Vector(invalid))}
    }
    check("una tessitura fuori ordine viene respinta"){
      rejectArg("Ordine"){patched(1,0,Vector(B,C,A))}
    }
    check("una tessitura con duplicato viene respinta"){
      rejectArg("Duplicato"){patched(1,0,Vector(A,A))}
    }
    check("il report manager pubblica la trace completa"){
      val m=new BaseMonsterManager
      val r=m.patch15DaywiseWeaving(43,-9181,Weaves,3,1)
      eqv(r.calculationDay,BigInt(43),"Calcolo")
      eqv(r.targetDay,BigInt(-9181),"Target")
      eqv(r.candidates,Weaves,"Famiglia")
      eqv(r.yearRank1,BigInt(3),"Rango")
      eqv(r.dayOffset,1,"Giorno")
      eqv(r.legacyDayRank1,BigInt(1),"Vecchio rango")
      eqv(r.legacyMonthId,1,"Vecchio mese")
      eqv(r.fixedAnnualWeaving,B,"Tessitura")
      eqv(r.correctedMonthId,2,"Mese corretto")
      eqv(r.correctedDayInMonth,1,"Contatore")
      truth(r.patchApplied,"Flag")
      eqv(r.phase,"PATCH_15_DAYWISE_WEAVING","Fase")
      eqv(r.status,"PATCH_15_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_15_DAYWISE_WEAVING",
        "PATCH_15_DAYWISE_WEAVING"),"Trace")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Boot")
      eqv(m.metricsSnapshot("discovery15.daywise.weaving.calls"),BigInt(1),"Legacy")
      eqv(m.metricsSnapshot("patch15.month.weaving.calls"),BigInt(1),"Patch")
    }
    check("il manager mantiene un'unica tessitura attraversando l'anno"){
      val m=new BaseMonsterManager
      val expected=C
      for(day<-0 until 252){
        val r=m.patch15DaywiseWeaving(5,13,Weaves,2,day)
        eqv(r.fixedAnnualWeaving,expected,"Giorno "+day)
        eqv(r.correctedMonthId,expected(day),"Mese "+day)
      }
      eqv(m.metricsSnapshot("patch15.month.weaving.calls"),
        BigInt(252),"Metriche")
    }
    check("manager riutilizzato non altera i vecchi report"){
      val m=new BaseMonsterManager
      val a=m.patch15DaywiseWeaving(1,2,Weaves,2,1)
      val b=m.patch15DaywiseWeaving(3,4,Weaves,3,1)
      eqv(a.fixedAnnualWeaving,C,"Vecchia tessitura")
      eqv(a.correctedMonthId,1,"Vecchio mese")
      eqv(b.fixedAnnualWeaving,B,"Nuova tessitura")
      eqv(b.correctedMonthId,2,"Nuovo mese")
      eqv(m.metricsSnapshot("patch15.month.weaving.calls"),BigInt(2),"Metrica")
    }
    check("due manager hanno stato e metriche separati"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      eqv(a.patch15DaywiseWeaving(1,2,Weaves,2,1).correctedMonthId,1,"A")
      eqv(b.patch15DaywiseWeaving(3,4,Weaves,3,1).correctedMonthId,2,"B")
      eqv(a.metricsSnapshot("patch15.month.weaving.calls"),BigInt(1),"M1")
      eqv(b.metricsSnapshot("patch15.month.weaving.calls"),BigInt(1),"M2")
    }
    check("il vecchio manager discovery conserva l'output errato"){
      val m=new BaseMonsterManager
      val legacy=m.discover15DaywiseWeaving(1,2,Weaves,3,1)
      val corr=m.patch15DaywiseWeaving(1,2,Weaves,3,1)
      eqv(legacy.legacyMonthId,corr.legacyMonthId,"Cicatrice")
      eqv(legacy.legacyDayRank1,corr.legacyDayRank1,"Vecchio rango")
      truth(corr.correctedMonthId!=legacy.legacyMonthId,"Divergenza")
    }
    check("handler rifiuta un contesto mai bootstrapped"){
      val c=BaseMonsterContext(1,2)
      c.phase="PATCH_15_DAYWISE_WEAVING"
      rejectState("Senza bootstrap"){
        new Patch15MonthWeavingHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta bootstrap senza discovery"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="PATCH_15_DAYWISE_WEAVING"
      rejectState("Senza discovery"){
        new Patch15MonthWeavingHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler non permette la doppia applicazione"){
      val c=ready()
      rejectState("Due patch"){
        new Patch15MonthWeavingHandler(new BaseMetricsShell).handle(c)}
    }
    check("handler rifiuta la cicatrice falsificata senza produrre output"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_15_DAYWISE_WEAVING"
      c.daywiseCandidateWeavings=Some(Weaves)
      c.daywiseYearRank1=Some(3)
      c.daywiseOffset=Some(1)
      new Discovery15DaywiseWeavingHandler(new BaseMetricsShell).handle(c)
      c.phase="PATCH_15_DAYWISE_WEAVING"
      c.legacyDaywiseMonthId=Some(9)
      rejectState("Falso"){
        new Patch15MonthWeavingHandler(new BaseMetricsShell).handle(c)}
      truth(c.patchedAnnualWeaving.isEmpty,"Non pubblicato")
      truth(!c.patch15Applied,"Flag non pubblicato")
    }
    check("handler rifiuta input modificati anche se il mese coincide"){
      val c=BaseMonsterContext(1,2)
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.phase="DISCOVERY_15_DAYWISE_WEAVING"
      c.daywiseCandidateWeavings=Some(Weaves)
      c.daywiseYearRank1=Some(1)
      c.daywiseOffset=Some(0)
      new Discovery15DaywiseWeavingHandler(new BaseMetricsShell).handle(c)
      c.phase="PATCH_15_DAYWISE_WEAVING"
      c.daywiseYearRank1=Some(2)
      rejectState("Rango post-hoc"){
        new Patch15MonthWeavingHandler(new BaseMetricsShell).handle(c)}
      truth(c.patchedAnnualWeaving.isEmpty,"Nessun output parziale")
    }
    check("validator indipendente accetta il contesto autentico"){
      new BaseValidationManager().requirePatch15Ready(ready(3,1))
    }
    check("validator accetta tutti i ranghi e i giorni di confine"){
      val v=new BaseValidationManager
      for(rank<-1 to 3;day<-Vector(0,1,2,3,83,84,85,167,168,251))
        v.requirePatch15Ready(ready(rank,day))
    }
    check("validator accetta tutti i 252 giorni con rango due"){
      val v=new BaseValidationManager
      for(day<-0 until 252)
        v.requirePatch15Ready(ready(2,day))
    }
    check("validator rifiuta l'ID mese patch contraffatto"){
      val c=ready(3,1)
      c.patchedMonthId=Some(1)
      rejectState("Mese"){new BaseValidationManager().requirePatch15Ready(c)}
    }
    check("validator rifiuta il contatore del giorno contraffatto"){
      val c=ready(2,3)
      c.patchedDayInMonth=Some(99)
      rejectState("Contatore"){new BaseValidationManager().requirePatch15Ready(c)}
    }
    check("validator rifiuta la tessitura annuale contraffatta"){
      val c=ready(3,1)
      c.patchedAnnualWeaving=Some(A)
      rejectState("Tessitura"){new BaseValidationManager().requirePatch15Ready(c)}
    }
    check("validator rifiuta il rango storico contraffatto"){
      val c=ready(3,1)
      c.legacyDaywiseRank1=Some(3)
      rejectState("Legacy"){new BaseValidationManager().requirePatch15Ready(c)}
    }
    check("validator rifiuta il mese storico contraffatto"){
      val c=ready(3,1)
      c.legacyDaywiseMonthId=Some(9)
      rejectState("Vecchio mese"){
        new BaseValidationManager().requirePatch15Ready(c)}
    }
    check("validator rifiuta il rango annuale mutato"){
      val c=ready(1,0)
      c.daywiseYearRank1=Some(2)
      rejectState("Rango"){new BaseValidationManager().requirePatch15Ready(c)}
    }
    check("validator rifiuta il giorno mutato"){
      val c=ready(2,1)
      c.daywiseOffset=Some(4)
      rejectState("Giorno"){new BaseValidationManager().requirePatch15Ready(c)}
    }
    check("validator rifiuta la famiglia mutata senza alterare il mese"){
      val c=ready(1,0)
      c.daywiseCandidateWeavings=Some(Vector(A))
      rejectState("Famiglia"){new BaseValidationManager().requirePatch15Ready(c)}
    }
    check("validator rifiuta una snapshot alterata"){
      val c=ready(2,1)
      c.daywiseInputSnapshot=Some((Weaves,BigInt(2),0))
      rejectState("Snapshot"){new BaseValidationManager().requirePatch15Ready(c)}
    }
    check("validator rifiuta la mancanza della snapshot"){
      val c=ready(2,1)
      c.daywiseInputSnapshot=None
      rejectState("Assente"){new BaseValidationManager().requirePatch15Ready(c)}
    }
    check("validator rifiuta un output patch assente"){
      val c=ready(2,1)
      c.patchedAnnualWeaving=None
      rejectState("Vuoto"){new BaseValidationManager().requirePatch15Ready(c)}
    }
    check("validator rifiuta un flag fase status e trace alterati"){
      val c=ready(2,1)
      val v=new BaseValidationManager
      c.patch15Applied=false
      rejectState("Flag"){v.requirePatch15Ready(c)}
      c.patch15Applied=true
      c.status="LEGACY_DAYWISE_WEAVING_READY"
      rejectState("Status"){v.requirePatch15Ready(c)}
      c.status="PATCH_15_READY"
      c.branchTrace.remove(1)
      rejectState("Trace"){v.requirePatch15Ready(c)}
      c.branchTrace.insert(1,"DISCOVERY_15_DAYWISE_WEAVING")
      c.phase="DISCOVERY_15_DAYWISE_WEAVING"
      rejectState("Phase"){v.requirePatch15Ready(c)}
    }
    check("le quattordici patch normative precedenti funzionano ancora"){
      val m=new BaseMonsterManager
      val mod=NormativeOracle.M
      val f=NormativeOracle.FoundationDay
      eqv(m.patch01Save(0,0,mod).patchedOutput,mod,"P01")
      eqv(m.patch02DayTag(f,f,f).patchedTag,BigInt(1),"P02")
      eqv(m.patch03Distance(f,f).patchedDistance,BigInt(1),"P03")
      eqv(m.patch04Stones(0,0).patchedStoneRows,NormativeOracle.Stones,"P04")
      eqv(m.patch05Prior(0,0,Vector[BigInt](1,2,3,4,5,6,7),
        Vector.empty,1,7).patchedValue,BigInt(7),"P05")
      eqv(m.patch06Grind(0,0,1,7,11,13,17,
        Vector[BigInt](19,23,29,31,37)).patchedValue,BigInt(422),"P06")
      eqv(m.patch07Permutation(0,0,720).patchedPermutation,
        Vector(6,5,4,3,2,1),"P07")
      eqv(m.patch08Bowls(0,0,Vector[BigInt](11,13,17,19,23,29),
        37,Vector[BigInt](31,37,41,43,47),1,1).patchedBowls(1),
        BigInt(4061162),"P08")
      eqv(m.patch09Vault(0,0,Vector[BigInt](11,13,17,19,23,29)).patchedBowls,
        NormativeOracle.postStir12(Vector[BigInt](11,13,17,19,23,29)),"P09")
      eqv(m.patch10Order46(0,0,1,720,1).correctedNextBowl,6,"P10")
      eqv(m.patch11ShortPick(0,0,mod,1,5).patchedRank,BigInt(1),"P11")
      eqv(m.patch12YearCeiling(0,0,Vector.fill(6)(963)).patchedAccepted,
        true,"P12")
      eqv(m.patch13YearJump(0,601,0,Vector(400,500,600,700,800),
        Vector(600,700,800,900,1000)).correctedYearOffset,BigInt(1),"P13")
      eqv(m.patch14VirtualGateList(0,0,17,3,BigInt(1)<<64,
        (BigInt(1)<<32)+1).patchedSelectedGateIndex,
        BigInt(17)+((BigInt(1)<<32)*3),"P14")
    }
    check("oracolo test-only, cicatrice conservata, nessuno Stage32"){
      val stream=Files.walk(root().resolve("src/main/scala"))
      val sources=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!sources.contains("NormativeOracle"),"Oracle")
      truth(sources.contains("def legacyChooseEachDaySeparately("),"Legacy")
      truth(sources.contains("def daywiseWeavingPatch("),"PATCH 15")
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      if(current<32)
        truth(!sources.contains("oldContiguousMonthDayGuess"),"Stage32 assente")
      else
        truth(sources.contains("def oldContiguousMonthDayGuess("),
          "DISCOVERY 16 posteriore presente")
    }
    check("metadati Stage31 mantengono le certificazioni precedenti"){
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE="))
        .map(_.stripPrefix("CURRENT_STAGE=").toInt).get
      truth(current>=31,"Stadio")
      if(current==31){
        truth(st.contains("CURRENT_KIND=PATCH"),"Tipo")
        truth(st.contains("CURRENT_PATCH=15"),"Patch")
      } else {
        truth(st.contains("STAGE_31_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_66_PASS_0_FAIL"),
          "PATCH 15 storica certificata")
      }
      truth(st.contains("STAGE_30_NATIVE_VERIFICATION=PASS_EXPECTED_RED_53_PASS_3_FAIL"),
        "Discovery 15")
      truth(st.contains("STAGE_29_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_55_PASS_0_FAIL"),
        "Patch 14")
      val done=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(done>=30 && done<=current,"Sequenza")
    }
    println("\nRISULTATO STADIO 31: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
