package pastafari

import pastafari.monster._
import pastafari.oracle.NormativeOracle
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** PATCH 09: tutti i dodici giri devono usare l'ultimo caveau pubblicato. */
object Stage19Tests {
  private var passed=0
  private var failed=0
  private val Ordinary=Vector[BigInt](11,13,17,19,23,29)
  private val Symmetric=Vector.fill[BigInt](6)(1)
  private val Signed=Vector[BigInt](-1,0,1,2,3,4)
  private val M=NormativeOracle.M

  private def check(name:String)(run: => Unit):Unit = {
    try {run;passed+=1;println("PASS — "+name)}
    catch {case e:Throwable =>
      failed+=1;println("FAIL — "+name+" — "+e.getMessage)
      e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit =
    if(got!=want)throw new AssertionError(
      label+": atteso="+want+", ottenuto="+got)
  private def truth(value:Boolean,label:String):Unit =
    if(!value)throw new AssertionError(label)
  private def rejectArg(label:String)(run: => Unit):Unit = {
    var rejected=false
    try run catch {case _:IllegalArgumentException => rejected=true}
    truth(rejected,label+": argomento accettato")
  }
  private def rejectState(label:String)(run: => Unit):Unit = {
    var rejected=false
    try run catch {case _:IllegalStateException => rejected=true}
    truth(rejected,label+": stato accettato")
  }
  private def root():java.nio.file.Path = {
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)
      p=p.getParent
    if(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md")))
      throw new IllegalStateException("Radice non trovata")
    p
  }

  // Riferimento indipendente test-only: un singolo giro simultaneo.
  private def one(old:Vector[BigInt],step:Int):LegacyVaultRound = {
    val saved=NormativeOracle.save(old.sum+149*step)
    val rank=((saved-1)%720+1).toInt
    val order=NormativeOracle.bowlOrderFromNumber(rank)
    val pairs=(1 to 6).map { position =>
      val at=order(position-1)-1
      val previous=order((position+4)%6)-1
      val following=order(position%6)-1
      val x=old(at)+3*old(previous)+5*old(following)+
        saved+step+position*position
      at->NormativeOracle.save(x*x+7*old(previous)*old(following))
    }
    LegacyVaultRound(step,saved,rank,order,
      pairs.sortBy(_._1).map(_._2).toVector)
  }

  private def rolling(initial:Vector[BigInt]):Vector[LegacyVaultRound] = {
    var previous=initial
    (1 to 12).map { step =>
      val round=one(previous,step)
      previous=round.bowls
      round
    }.toVector
  }
  private def stale(initial:Vector[BigInt]):Vector[LegacyVaultRound] =
    (1 to 12).map(step=>one(initial,step)).toVector

  private def ready(initial:Vector[BigInt]=Ordinary):BaseMonsterContext = {
    val c=BaseMonsterContext(1,2)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.postStirInput=Some(initial)
    c.phase="DISCOVERY_09_VAULT"
    new Discovery09VaultHandler(new BaseMetricsShell).handle(c)
    c.phase="PATCH_09_VAULT_ROLL"
    c
  }

  def main(args:Array[String]):Unit = {
    check("dodici rimescolamenti normativi del caveau ordinario") {
      val actual=Patch09VaultWrapper.vaultPatch(Ordinary)
      eqv(actual.bowls,NormativeOracle.postStir12(Ordinary),"Finale")
      eqv(actual.bowls,rolling(Ordinary).last.bowls,"Oracle per giro")
    }
    check("dodici rimescolamenti normativi del caveau simmetrico") {
      eqv(Patch09VaultWrapper.vaultPatch(Symmetric).bowls,
        NormativeOracle.postStir12(Symmetric),"Finale simmetrico")
    }
    check("dodici rimescolamenti normativi del caveau signed") {
      eqv(Patch09VaultWrapper.vaultPatch(Signed).bowls,
        NormativeOracle.postStir12(Signed),"Finale signed")
    }
    check("sei ciotole nulle hanno un risultato normativo") {
      val zero=Vector.fill[BigInt](6)(0)
      eqv(Patch09VaultWrapper.vaultPatch(zero).bowls,
        NormativeOracle.postStir12(zero),"Zero")
    }
    check("limiti SAVE e multipli di M restano normativi") {
      for(init<-Vector(Vector.fill[BigInt](6)(M),
          Vector.fill[BigInt](6)(-M),Vector.fill[BigInt](6)(M+1))) {
        eqv(Patch09VaultWrapper.vaultPatch(init).bowls,
          NormativeOracle.postStir12(init),"Bordo SAVE")
      }
    }
    check("la prima mescolatura coincide con la cicatrice vera") {
      for(initial<-Vector(Ordinary,Symmetric,Signed)) {
        val patched=Patch09VaultWrapper.vaultPatch(initial)
        eqv(patched.rounds.head,patched.historical.rounds.head,"Primo giro")
      }
    }
    check("dal secondo giro la ricorrenza usa il caveau aggiornato") {
      val r=Patch09VaultWrapper.vaultPatch(Ordinary)
      eqv(r.rounds(1),one(r.rounds.head.bowls,2),"Seconda fotografia")
      truth(r.rounds(1)!=r.historical.rounds(1),"La cicatrice deve differire")
    }
    check("le dodici fotografie coincidono con il calcolo indipendente") {
      for(initial<-Vector(Ordinary,Symmetric,Signed)) {
        eqv(Patch09VaultWrapper.vaultPatch(initial).rounds,
          rolling(initial),"Dodici prove")
      }
    }
    check("la diagnostica storica non è stata modificata") {
      for(initial<-Vector(Ordinary,Symmetric,Signed)) {
        val r=Patch09VaultWrapper.vaultPatch(initial)
        eqv(r.historical,LegacyVaultAdapter.vaultOld(initial),"Legacy")
        eqv(r.historical.rounds,stale(initial),"Caveau obsoleto")
      }
    }
    check("tutti i ranghi iniziali da uno a 720 sono raggiungibili") {
      val ranks=(1 to 720).map(x=>
        Patch09VaultWrapper.vaultPatch(Vector[BigInt](x,0,0,0,0,0)).rounds.head.orderRank)
      eqv(ranks.toSet,(1 to 720).toSet,"Tutti i ranghi")
    }
    check("720 ranghi e tutti i dodici giri concordano con l'oracolo") {
      for(i<-1 to 720) {
        val init=Vector[BigInt](i,0,0,0,0,0)
        val r=Patch09VaultWrapper.vaultPatch(init)
        eqv(r.rounds,rolling(init),"Rango "+i)
        eqv(r.bowls,NormativeOracle.postStir12(init),"Finale "+i)
      }
    }
    check("512 input signed deterministici di sei ciotole") {
      val rng=new Random(20261012L)
      for(i<-1 to 512) {
        val init=Vector.tabulate[BigInt](6) { p =>
          BigInt(rng.nextInt(200001)-100000)*(p+1)+i
        }
        val r=Patch09VaultWrapper.vaultPatch(init)
        eqv(r.rounds,rolling(init),"Campione "+i)
        eqv(r.bowls,NormativeOracle.postStir12(init),"Oracle "+i)
      }
    }
    check("interi signed oltre 16384 bit e nessun overflow") {
      val huge=(BigInt(1)<<16384)+999
      val initial=Vector(huge,-huge,huge*2,-huge*3,huge+11,-huge-13)
      val r=Patch09VaultWrapper.vaultPatch(initial)
      eqv(r.rounds,rolling(initial),"BigInt signed")
      eqv(r.bowls,NormativeOracle.postStir12(initial),"Oracolo grande")
    }
    check("tutte le 72 uscite e dodici somme appartengono a SAVE") {
      for(initial<-Vector(Ordinary,Symmetric,Signed)) {
        val records=Patch09VaultWrapper.vaultPatch(initial).rounds
        truth(records.forall(r=>r.bowls.forall(x=>x>=1&&x<=M)&&
          r.savedSum>=1&&r.savedSum<=M),"Dominio")
      }
    }
    check("le dodici registrazioni sono ordinate e complete") {
      val r=Patch09VaultWrapper.vaultPatch(Ordinary)
      eqv(r.rounds.map(_.step),(1 to 12).toVector,"Indice")
      eqv(r.rounds.last.bowls,r.bowls,"Pubblicazione")
    }
    check("tutti i ranghi e ordini intermedi sono normativi") {
      for(row<-Patch09VaultWrapper.vaultPatch(Ordinary).rounds) {
        truth(row.orderRank>=1&&row.orderRank<=720,"Rango")
        eqv(row.order,NormativeOracle.bowlOrderFromNumber(row.orderRank),"Ordine")
      }
    }
    check("la somma al giro seguente legge l'istantanea precedente") {
      val rows=Patch09VaultWrapper.vaultPatch(Ordinary).rounds
      for(step<-2 to 12) {
        val previous=rows(step-2).bowls
        eqv(rows(step-1).savedSum,NormativeOracle.save(previous.sum+149*step),
          "Somma "+step)
      }
    }
    check("un cambio di una ciotola entra nel calcolo successivo") {
      val first=one(Ordinary,1)
      val altered=first.bowls.updated(0,first.bowls.head+1)
      truth(one(first.bowls,2)!=one(altered,2),"Dipendenza dallo stato")
    }
    check("l'input immutabile non viene modificato dal wrapper") {
      val initial=Ordinary
      Patch09VaultWrapper.vaultPatch(initial)
      eqv(initial,Vector[BigInt](11,13,17,19,23,29),"Snapshot iniziale")
    }
    check("chiamate intercalate non cambiano l'output precedente") {
      val before=Patch09VaultWrapper.vaultPatch(Ordinary)
      for(i<-1 to 80) {
        Patch09VaultWrapper.vaultPatch(Vector.fill[BigInt](6)(i))
      }
      eqv(Patch09VaultWrapper.vaultPatch(Ordinary),before,"Determinismo")
    }
    check("le dimensioni di input diverse da sei sono respinte") {
      for(n<-Vector(0,1,2,5,7,12,100)) {
        rejectArg("Dimensione "+n) {
          Patch09VaultWrapper.vaultPatch(Vector.fill[BigInt](n)(1))
        }
      }
    }
    check("manager e dispatcher percorrono davvero la discovery e patch") {
      val m=new BaseMonsterManager
      val r=m.patch09Vault(17,-19,Ordinary)
      eqv(r.calculationDay,BigInt(17),"Giorno calcolo")
      eqv(r.targetDay,BigInt(-19),"Giorno chiesto")
      eqv(r.initialBowls,Ordinary,"Input")
      eqv(r.legacyRounds,stale(Ordinary),"Legacy")
      eqv(r.patchedRounds,rolling(Ordinary),"Patch")
      eqv(r.patchedBowls,NormativeOracle.postStir12(Ordinary),"Finale")
      truth(r.patchApplied,"Flag")
      eqv(r.phase,"PATCH_09_VAULT_ROLL","Fase")
      eqv(r.status,"PATCH_09_READY","Stato")
      eqv(r.trace,Vector("BOOT","DISCOVERY_09_VAULT","PATCH_09_VAULT_ROLL"),
        "Traccia")
      eqv(m.metricsSnapshot("base.bootstrap.calls"),BigInt(1),"Bootstrap")
      eqv(m.metricsSnapshot("discovery09.vault.calls"),BigInt(1),"Discovery")
      eqv(m.metricsSnapshot("patch09.vault.roll.calls"),BigInt(1),"Patch")
    }
    check("report della discovery indipendente conserva la stessa cicatrice") {
      val m=new BaseMonsterManager
      for(input<-Vector(Ordinary,Symmetric,Signed)) {
        val discovery=m.discover09Vault(0,0,input)
        val patched=m.patch09Vault(0,0,input)
        eqv(patched.legacyRounds,discovery.legacyRounds,"Registri")
        eqv(patched.legacyBowls,discovery.legacyBowls,"Cicatrice")
      }
    }
    check("due contesti indipendenti non condividono i registri") {
      val m=new BaseMonsterManager
      val a=m.patch09Vault(1,2,Ordinary)
      val b=m.patch09Vault(3,4,Symmetric)
      eqv(a.initialBowls,Ordinary,"Input A")
      eqv(b.initialBowls,Symmetric,"Input B")
      truth(a.patchedBowls!=b.patchedBowls,"Risultati distinti")
      eqv(m.metricsSnapshot("patch09.vault.roll.calls"),BigInt(2),"Metrica")
    }
    check("giorni arbitrari enormi non influenzano la funzione locale") {
      val huge=(BigInt(1)<<16384)+57
      val m=new BaseMonsterManager
      val a=m.patch09Vault(0,0,Ordinary)
      val b=m.patch09Vault(huge,-huge,Ordinary)
      eqv(a.patchedRounds,b.patchedRounds,"Stessa funzione")
      eqv(b.calculationDay,huge,"Calcolo gigantesco")
      eqv(b.targetDay,-huge,"Interrogazione gigantesca")
    }
    check("handler respinge uso senza il bootstrap") {
      val h=new Patch09VaultHandler(new BaseMetricsShell)
      rejectState("Contesto NEW"){h.handle(BaseMonsterContext(1,2))}
      val c=BaseMonsterContext(1,2)
      c.status="LEGACY_VAULT_READY";c.postStirInput=Some(Ordinary)
      rejectState("Senza traccia"){h.handle(c)}
      truth(c.patchedVaultRounds.isEmpty,"Nessun output")
    }
    check("handler respinge doppia applicazione e non muta il report") {
      val h=new Patch09VaultHandler(new BaseMetricsShell)
      val c=ready()
      h.handle(c)
      val rows=c.patchedVaultRounds
      rejectState("Doppia patch"){h.handle(c)}
      eqv(c.patchedVaultRounds,rows,"Report conservato")
    }
    check("validator rifiuta risultato patch assente") {
      val v=new BaseValidationManager
      val c=ready()
      c.phase="PATCH_09_VAULT_ROLL"
      c.status="PATCH_09_READY";c.patch09Applied=true
      c.branchTrace.append("PATCH_09_VAULT_ROLL")
      rejectState("Manca output"){v.requirePatch09Ready(c)}
    }
    check("validator accetta l'intera sequenza di 720 ranghi") {
      val v=new BaseValidationManager
      val h=new Patch09VaultHandler(new BaseMetricsShell)
      for(i<-1 to 720) {
        val c=ready(Vector[BigInt](i,0,0,0,0,0))
        h.handle(c)
        v.requirePatch09Ready(c)
      }
    }
    check("validator rifiuta un valore patched contraffatto") {
      val v=new BaseValidationManager
      val c=ready()
      new Patch09VaultHandler(new BaseMetricsShell).handle(c)
      val rows=c.patchedVaultRounds.get
      c.patchedVaultRounds=Some(rows.updated(6,
        rows(6).copy(bowls=rows(6).bowls.updated(0,BigInt(999)))))
      rejectState("Settimo giro contraffatto"){v.requirePatch09Ready(c)}
    }
    check("validator rifiuta un risultato finale contraffatto") {
      val v=new BaseValidationManager
      val c=ready()
      new Patch09VaultHandler(new BaseMetricsShell).handle(c)
      c.patchedVaultOutput=Some(c.patchedVaultOutput.get.updated(0,BigInt(1)))
      rejectState("Finale contraffatto"){v.requirePatch09Ready(c)}
    }
    check("validator rifiuta uno storico contraffatto") {
      val v=new BaseValidationManager
      val c=ready()
      new Patch09VaultHandler(new BaseMetricsShell).handle(c)
      c.legacyVaultRounds=Some(c.legacyVaultRounds.get.updated(5,
        c.legacyVaultRounds.get(5).copy(savedSum=BigInt(999))))
      rejectState("Cicatrice alterata"){v.requirePatch09Ready(c)}
    }
    check("validator rifiuta un rango o una somma falsificati") {
      val v=new BaseValidationManager
      val c=ready()
      new Patch09VaultHandler(new BaseMetricsShell).handle(c)
      val rows=c.patchedVaultRounds.get
      c.patchedVaultRounds=Some(rows.updated(3,rows(3).copy(orderRank=1)))
      rejectState("Rango falsificato"){v.requirePatch09Ready(c)}
      c.patchedVaultRounds=Some(rows.updated(3,rows(3).copy(savedSum=BigInt(1))))
      rejectState("Somma falsificata"){v.requirePatch09Ready(c)}
    }
    check("validator rifiuta flag e trace non corretti") {
      val v=new BaseValidationManager
      val c=ready()
      new Patch09VaultHandler(new BaseMetricsShell).handle(c)
      c.patch09Applied=false
      rejectState("Flag falso"){v.requirePatch09Ready(c)}
      c.patch09Applied=true
      c.branchTrace.remove(1)
      rejectState("Trace falsa"){v.requirePatch09Ready(c)}
    }
    check("le otto patch precedenti restano normative") {
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
      eqv(m.patch07Permutation(0,0,720).patchedPermutation,
        Vector(6,5,4,3,2,1),"Permutation")
      eqv(m.patch08Bowls(0,0,Vector[BigInt](11,13,17,19,23,29),37,
        Vector[BigInt](31,37,41,43,47),1,1).patchedBowls(1),
        BigInt(4061162),"Bowl freeze")
    }
    check("cicatrice intatta, oracolo test-only e nessun prossimo stadio") {
      val stream=Files.walk(root().resolve("src/main/scala"))
      val source=try stream.iterator().asScala
        .filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
        .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8))
        .mkString("\n")
      finally stream.close()
      truth(!source.contains("NormativeOracle"),"Oracle in produzione")
      truth(source.contains("val old = vaultOld"),"Cicatrice originale")
      truth(source.contains("LegacyVaultAdapter.vaultOld(initial)"),
        "Il wrapper attraversa il vecchio codice")
      truth(!source.contains("orderAt46Latch"),"Stage20 anticipato")
    }
    check("metadati dello Stage19 GREEN preservano Stage18 RED") {
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),
        StandardCharsets.UTF_8)
      truth(st.contains("CURRENT_STAGE=19"),"Stage corrente")
      truth(st.contains("CURRENT_KIND=PATCH"),"Fase")
      truth(st.contains("CURRENT_PATCH=09"),"Versione patch")
      truth(st.contains("EXPECTED_REPOSITORY_STATE=GREEN"),"GREEN")
      truth(st.contains("STAGE_18_NATIVE_VERIFICATION=PASS_EXPECTED_RED_27_PASS_3_FAIL"),
        "Certificazione Stage18")
      val completed=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE="))
        .map(_.stripPrefix("LAST_COMPLETED_STAGE=").toInt).get
      truth(completed>=18&&completed<=19,"Certificazione non anticipata")
    }

    println("\nRISULTATO STADIO 19: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
