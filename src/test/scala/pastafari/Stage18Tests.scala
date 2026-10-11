package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY 09: il vecchio caveau rimane congelato per tutti i dodici giri. */
object Stage18Tests {
  private var passed = 0
  private var failed = 0
  private val Ordinary = Vector[BigInt](11,13,17,19,23,29)
  private val Symmetric = Vector.fill[BigInt](6)(1)
  private val Signed = Vector[BigInt](-1,0,1,2,3,4)
  private val M = NormativeOracle.M

  private def check(name:String)(run: => Unit): Unit = {
    try {run; passed+=1;println("PASS — "+name)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+name+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit =
    if(got!=want)throw new AssertionError(label+": atteso="+want+", ottenuto="+got)
  private def truth(ok:Boolean,label:String):Unit =
    if(!ok)throw new AssertionError(label)
  private def rejectArg(name:String)(run: => Unit):Unit = {
    var rejected=false
    try run catch {case _:IllegalArgumentException => rejected=true}
    truth(rejected,name+": parametro invalido accettato")
  }
  private def rejectState(name:String)(run: => Unit):Unit = {
    var rejected=false
    try run catch {case _:IllegalStateException => rejected=true}
    truth(rejected,name+": stato invalido accettato")
  }
  private def root():java.nio.file.Path = {
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")) && p.getParent!=null)
      p=p.getParent
    if(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice non trovata")
    p
  }

  // Riferimento test-only: un giro usa solo i sei vecchi valori.
  private def singleRound(old:Vector[BigInt],step:Int):LegacyVaultRound = {
    val sum = NormativeOracle.save(old.sum + 149*step)
    val rank = (((sum-1)%720)+1).toInt
    val order = NormativeOracle.bowlOrderFromNumber(rank)
    val values = Array.fill[BigInt](6)(BigInt(0))
    for(position <- 1 to 6) {
      val bowl=order(position-1)-1
      val prev=order((position+4)%6)-1
      val next=order(position%6)-1
      val t=old(bowl)+3*old(prev)+5*old(next)+sum+step+position*position
      values(bowl)=NormativeOracle.save(t*t+7*old(prev)*old(next))
    }
    LegacyVaultRound(step,sum,rank,order,values.toVector)
  }

  private def independentStale(initial:Vector[BigInt]):Vector[LegacyVaultRound] =
    (1 to 12).map(step=>singleRound(initial,step)).toVector

  private def independentRolling(initial:Vector[BigInt]):Vector[LegacyVaultRound] = {
    var previous=initial
    (1 to 12).map { step =>
      val record=singleRound(previous,step)
      previous=record.bowls
      record
    }.toVector
  }

  private def ready(initial:Vector[BigInt]=Ordinary):BaseMonsterContext = {
    val ctx=BaseMonsterContext(1,2)
    ctx.status="BOOTSTRAPPED"
    ctx.branchTrace.append("BOOT")
    ctx.postStirInput=Some(initial)
    ctx.phase="DISCOVERY_09_VAULT"
    new Discovery09VaultHandler(new BaseMetricsShell).handle(ctx)
    ctx
  }

  def main(args:Array[String]):Unit = {
    check("tutte le dodici righe legacy sono ordinate da 1 a 12") {
      val rows=LegacyVaultAdapter.vaultOld(Ordinary).rounds
      eqv(rows.map(_.step),(1 to 12).toVector,"Ordine dei giri")
    }
    check("il primo giro è realmente normativo") {
      val actual=LegacyVaultAdapter.vaultOld(Ordinary).rounds.head
      eqv(actual,singleRound(Ordinary,1),"Primo giro")
      eqv(actual.bowls,Vector[BigInt](227180,225843,164987,204240,199572,184647),
        "Output del primo giro")
    }
    check("tutti gli indici del rango sono esattamente da 1 a 720") {
      for(row<-LegacyVaultAdapter.vaultOld(Ordinary).rounds){
        truth(row.orderRank>=1 && row.orderRank<=720,"Rango "+row.step)
        eqv(row.order.sorted,Vector(1,2,3,4,5,6),"Permutazione")
      }
    }
    check("SAVE rimane fra uno e M per tutte le 72 uscite") {
      val r=LegacyVaultAdapter.vaultOld(Ordinary)
      truth(r.rounds.forall(_.bowls.forall(x=>x>=1 && x<=M)),"SAVE")
      eqv(r.bowls,r.rounds.last.bowls,"Risultato finale")
    }
    check("l'errore storico usa davvero l'ingresso iniziale ad ogni giro") {
      val actual=LegacyVaultAdapter.vaultOld(Ordinary)
      eqv(actual.rounds,independentStale(Ordinary),"Giri obsoleti")
      eqv(actual.bowls,independentStale(Ordinary).last.bowls,"Ultimo giro obsoleto")
    }
    check("la stessa diagnostica vale con sei ciotole identiche") {
      eqv(LegacyVaultAdapter.vaultOld(Symmetric).rounds,
        independentStale(Symmetric),"Caveau simmetrico")
    }
    check("la stessa diagnostica vale con valori signed") {
      eqv(LegacyVaultAdapter.vaultOld(Signed).rounds,
        independentStale(Signed),"Caveau signed")
    }
    check("la somma del giro due rimane legata all'ingresso originario") {
      val actual=LegacyVaultAdapter.vaultOld(Ordinary).rounds
      eqv(actual(1).savedSum,NormativeOracle.save(Ordinary.sum+149*2),"Somma vecchia")
      truth(actual(1).savedSum !=
        NormativeOracle.save(actual.head.bowls.sum+149*2),"Somma aggiornata diversa")
    }
    check("ogni rango di primo giro tra 1 e 720 è raggiungibile") {
      val ranks=(1 to 720).map { x =>
        LegacyVaultAdapter.vaultOld(Vector[BigInt](x,0,0,0,0,0)).rounds.head.orderRank
      }
      eqv(ranks.toSet,(1 to 720).toSet,"Copertura 720 ranghi")
    }
    check("tutte le 720 permutazioni del primo giro sono normative") {
      for(x<-1 to 720) {
        val initial=Vector[BigInt](x,0,0,0,0,0)
        val row=LegacyVaultAdapter.vaultOld(initial).rounds.head
        eqv(row.order,NormativeOracle.bowlOrderFromNumber(row.orderRank),"Rango "+x)
      }
    }
    check("le dodici righe mostrano istantanee immutabili distinte") {
      val records=LegacyVaultAdapter.vaultOld(Ordinary).rounds
      eqv(records.length,12,"Giri")
      truth(records.map(_.bowls).distinct.size>1,"Gli output variano")
      eqv(records.head,singleRound(Ordinary,1),"Prima istantanea")
    }
    check("test indipendente della catena normativa sui dodici giri") {
      for(initial<-Vector(Ordinary,Symmetric,Signed)){
        val rolling=independentRolling(initial)
        eqv(rolling.last.bowls,NormativeOracle.postStir12(initial),
          "Formula normativa test-only")
      }
    }
    check("256 ingressi signed deterministici conservano la cicatrice") {
      val rng=new Random(20261012L)
      for(sample<-1 to 256){
        val old=Vector.tabulate[BigInt](6)(j=>
          BigInt(rng.nextInt(100001)-50000)*(j+1)+sample)
        val actual=LegacyVaultAdapter.vaultOld(old)
        eqv(actual.rounds,independentStale(old),"Campione "+sample)
      }
    }
    check("BigInt signed maggiori di 16384 bit non vengono troncati") {
      val g=(BigInt(1)<<16384)+91
      val old=Vector(g,-g,g*2,-g*3,g+1,-g-2)
      val r=LegacyVaultAdapter.vaultOld(old)
      eqv(r.rounds,independentStale(old),"BigInt")
      truth(r.bowls.forall(x=>x>=1 && x<=M),"SAVE BigInt")
    }
    check("l'input originale non viene modificato") {
      val before=Ordinary
      LegacyVaultAdapter.vaultOld(before)
      eqv(before,Vector[BigInt](11,13,17,19,23,29),"Stato dell'input")
    }
    check("l'output non dipende da chiamate intercalate") {
      val base=LegacyVaultAdapter.vaultOld(Ordinary)
      for(i<-1 to 70) {
        LegacyVaultAdapter.vaultOld(Vector.fill[BigInt](6)(i))
      }
      eqv(LegacyVaultAdapter.vaultOld(Ordinary),base,"Ripetibilità")
    }
    check("i vettori di dimensione diversa da sei sono rifiutati") {
      for(n<-Vector(0,1,2,5,7,10,100)){
        rejectArg("Lunghezza "+n){
          LegacyVaultAdapter.vaultOld(Vector.fill[BigInt](n)(1))
        }
      }
    }
    check("il manager attraversa realmente Bootstrap e DISCOVERY 09") {
      val m=new BaseMonsterManager
      val report=m.discover09Vault(17,-19,Ordinary)
      eqv(report.initialBowls,Ordinary,"Input")
      eqv(report.legacyRounds,independentStale(Ordinary),"Dodici diagnostiche")
      eqv(report.legacyBowls,independentStale(Ordinary).last.bowls,"Finale")
      eqv(report.phase,"DISCOVERY_09_VAULT","Fase")
      eqv(report.status,"LEGACY_VAULT_READY","Stato")
      eqv(report.trace,Vector("BOOT","DISCOVERY_09_VAULT"),"Trace")
      eqv(report.calculationDay,BigInt(17),"Giorno calcolo")
      eqv(report.targetDay,BigInt(-19),"Giorno richiesto")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery09.vault.calls"),BigInt(1),"Metrica")
    }
    check("due invocazioni mantengono report e metrica isolati") {
      val m=new BaseMonsterManager
      val a=m.discover09Vault(1,2,Ordinary)
      val b=m.discover09Vault(3,4,Symmetric)
      eqv(a.initialBowls,Ordinary,"Input A")
      eqv(b.initialBowls,Symmetric,"Input B")
      truth(a.legacyBowls != b.legacyBowls,"Output distinti")
      eqv(m.metricsSnapshot("discovery09.vault.calls"),BigInt(2),"Due chiamate")
    }
    check("giorni di calendario BigInt enormi non cambiano il caveau locale") {
      val huge=(BigInt(1)<<16384)+7
      val m=new BaseMonsterManager
      val a=m.discover09Vault(0,0,Ordinary)
      val b=m.discover09Vault(huge,-huge,Ordinary)
      eqv(a.legacyRounds,b.legacyRounds,"Indipendenza")
      eqv(b.targetDay,-huge,"Giorno enorme conservato")
    }
    check("il validatore respinge output assente e traccia mancante") {
      val v=new BaseValidationManager
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_09_VAULT"
      c.status="LEGACY_VAULT_READY"
      c.postStirInput=Some(Ordinary)
      rejectState("Nessuna risposta"){v.requireDiscovery09Ready(c)}
      val old=LegacyVaultAdapter.vaultOld(Ordinary)
      c.legacyVaultRounds=Some(old.rounds)
      c.legacyVaultOutput=Some(old.bowls)
      rejectState("Trace mancante"){v.requireDiscovery09Ready(c)}
      c.branchTrace.appendAll(Seq("BOOT","DISCOVERY_09_VAULT"))
      v.requireDiscovery09Ready(c)
    }
    check("il validatore rileva il rango contraffatto") {
      val v=new BaseValidationManager
      val c=ready()
      val records=c.legacyVaultRounds.get
      c.legacyVaultRounds=Some(records.updated(0,records.head.copy(orderRank=1)))
      rejectState("Rango falsificato"){v.requireDiscovery09Ready(c)}
    }
    check("il validatore rileva una riga controffatta") {
      val v=new BaseValidationManager
      val c=ready()
      val records=c.legacyVaultRounds.get
      c.legacyVaultRounds=Some(records.updated(11,
        records.last.copy(bowls=records.last.bowls.updated(0,BigInt(999)))))
      rejectState("Riga falsificata"){v.requireDiscovery09Ready(c)}
    }
    check("l'handler rifiuta bypass e doppia esecuzione") {
      val h=new Discovery09VaultHandler(new BaseMetricsShell)
      val c=BaseMonsterContext(1,2)
      rejectState("Bootstrap mancante"){h.handle(c)}
      c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
      c.postStirInput=Some(Ordinary);c.phase="DISCOVERY_09_VAULT"
      h.handle(c)
      val previous=c.legacyVaultOutput
      rejectState("Seconda esecuzione"){h.handle(c)}
      eqv(c.legacyVaultOutput,previous,"Stato non mutato")
    }
    check("le otto patch precedenti rimangono normative") {
      val m=new BaseMonsterManager
      val f=NormativeOracle.FoundationDay
      eqv(m.patch01Save(0,0,M).patchedOutput,M,"SAVE")
      eqv(m.patch02DayTag(f,f,f).patchedTag,BigInt(1),"DayTag")
      eqv(m.patch03Distance(f,f).patchedDistance,BigInt(1),"Distance")
      eqv(m.patch04Stones(0,0).patchedStoneRows,NormativeOracle.Stones,"Stones")
      val h=Vector[BigInt](101,202,303,404,505,606,707)
      eqv(m.patch05Prior(0,0,h,Vector.empty,1,7).patchedValue,BigInt(707),"Prior")
      eqv(m.patch06Grind(0,0,1,7,11,13,17,
        Vector[BigInt](19,23,29,31,37)).patchedValue,BigInt(422),"Grind")
      eqv(m.patch07Permutation(0,0,720).patchedPermutation,Vector(6,5,4,3,2,1),
        "Permutation")
      eqv(m.patch08Bowls(0,0,Vector[BigInt](11,13,17,19,23,29),
        37,Vector[BigInt](31,37,41,43,47),1,1).patchedBowls(1),
        BigInt(4061162),"Bowl freeze")
    }
    check("nessun oracolo in produzione e nessuna PATCH 09") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val src=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!src.contains("NormativeOracle"),"Oracolo test-only")
      truth(src.contains("val old = vaultOld"),"Lettura obsoleta reale")
      truth(!src.contains("vaultPatch"),"PATCH 09 anticipata")
      truth(!src.contains("orderAt46Latch"),"Logica del prossimo stadio")
    }
    check("metadati dello stadio 18 sono intenzionalmente RED") {
      val text=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(text.contains("CURRENT_STAGE=18"),"Stadio")
      truth(text.contains("CURRENT_KIND=DISCOVERY"),"Tipo")
      truth(text.contains("CURRENT_PATCH=08"),"Patch precedente")
      truth(text.contains("EXPECTED_REPOSITORY_STATE=EXPECTED_RED"),"RED")
      truth(text.contains("STAGE_17_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_31_PASS_0_FAIL"),
        "Precedente certificazione intatta")
      val completed=text.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed==17 || completed==18,"Ordine certificazioni")
    }

    val manager=new BaseMonsterManager
    Vector(("ordinario",Ordinary),("simmetrico",Symmetric),("signed",Signed))
      .foreach {case(label,input) =>
        check("equivalenza normativa caveau "+label) {
          eqv(manager.discover09Vault(0,0,input).legacyBowls,
            NormativeOracle.postStir12(input),"Caveau vecchio non aggiornato: "+label)
        }
      }
    println("\nRISULTATO STADIO 18: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
