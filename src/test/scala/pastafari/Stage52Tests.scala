package pastafari

import pastafari.monster._
import java.nio.charset.StandardCharsets
import java.nio.file.{Files,Paths}
import scala.jdk.CollectionConverters._
import scala.util.Random

/** DISCOVERY26: porta e cotoletta sono identita' distinte. */
object Stage52Tests {
  private var passed=0
  private var failed=0
  private val Six=Vector.fill(6)(42)
  private val Ones=Vector.fill(6)(1)
  private val Nine=Vector.fill(9)(42)
  private val Part=Vector(2,1,2,1,1,2)
  private val Huge=(BigInt(1)<<16384)+52
  private def check(label:String)(f: => Unit):Unit={
    try{f;passed+=1;println("PASS — "+label)}
    catch{case e:Throwable=>failed+=1;println("FAIL — "+label+" — "+e.getMessage);e.printStackTrace(System.out)}
  }
  private def eqv[A](got:A,want:A,label:String):Unit={
    if(got!=want)throw new AssertionError(label+": atteso="+want+", ottenuto="+got)
  }
  private def truth(x:Boolean,label:String):Unit={if(!x)throw new AssertionError(label)}
  private def rejectArg(label:String)(f: => Unit):Unit={
    var ok=false;try f catch{case _:IllegalArgumentException=>ok=true};truth(ok,label)
  }
  private def rejectState(label:String)(f: => Unit):Unit={
    var ok=false;try f catch{case _:IllegalStateException=>ok=true};truth(ok,label)
  }
  private def old(g:Vector[Int],p:Vector[Int],d:Int):LegacyGateToCutletProjectionResult =
    LegacyGateToCutletProjectionAdapter.oldGateToCutletProjection(g,p,d)
  // Test-only normative: counts GROUPS of gates.
  private def normative(g:Vector[Int],p:Vector[Int],d:Int):(Int,Int)={
    var start=0;var gate=0
    for((count,index)<-p.zipWithIndex){
      val duration=g.slice(gate,gate+count).sum
      if(d>=start && d<start+duration)return (index+1,d-start+1)
      start+=duration;gate+=count
    }
    throw new AssertionError("Partizione non copre il giorno")
  }
  private def ready():BaseMonsterContext={
    val c=BaseMonsterContext(Huge,-Huge)
    c.status="BOOTSTRAPPED";c.branchTrace.append("BOOT")
    c.phase="DISCOVERY_26_GATE_TO_CUTLET_PROJECTION"
    c.gateProjectionGaps=Some(Nine);c.gateProjectionPartition=Some(Part)
    c.gateProjectionDayOffset=Some(42)
    new Discovery26GateToCutletProjectionHandler(new BaseMetricsShell).handle(c)
    c
  }
  private def root():java.nio.file.Path={
    var p=Paths.get(System.getProperty("user.dir")).toAbsolutePath.normalize()
    while(!Files.exists(p.resolve("DEVELOPMENT_STAGE.md"))&&p.getParent!=null)p=p.getParent
    p
  }
  def main(args:Array[String]):Unit={
    check("minimo sei porte"){
      eqv(Six.sum,252,"Giorni")
    }
    check("nove porte 378 giorni"){
      eqv(Nine.sum,378,"Giorni")
    }
    check("partizione copre nove porte"){
      eqv(Part.sum,Nine.length,"Porte")
    }
    check("giorno zero"){
      eqv((old(Nine,Part,0).gateId,old(Nine,Part,0).legacyDayInCutlet),(1,1),"Primo")
    }
    check("giorno 41"){
      eqv(old(Nine,Part,41).legacyDayInCutlet,42,"Fine gate")
    }
    check("giorno 42 inaugura porta due"){
      eqv((old(Nine,Part,42).gateId,old(Nine,Part,42).legacyCutletId),(2,2),"Gate 2")
    }
    check("giorno 83 termina porta due"){
      eqv(old(Nine,Part,83).legacyDayInCutlet,42,"Fine")
    }
    check("giorno 84 inaugura porta tre"){
      eqv(old(Nine,Part,84).gateId,3,"Gate 3")
    }
    check("giorno 126 inaugura porta quattro"){
      eqv(old(Nine,Part,126).gateStartOffset,126,"Gate4")
    }
    check("giorno 168 inaugura porta cinque"){
      eqv(old(Nine,Part,168).legacyCutletId,5,"Gate5")
    }
    check("giorno 336 inaugura porta nove"){
      eqv(old(Nine,Part,336).legacyCutletId,9,"Gate9")
    }
    check("ultimo giorno porta nove"){
      eqv(old(Nine,Part,377).legacyDayInCutlet,42,"End")
    }
    check("tutti i 378 giorni del legacy"){
      for(d<-0 until Nine.sum){
        val r=old(Nine,Part,d)
        eqv((r.gateId,r.gateStartOffset,r.legacyDayInCutlet),
          (d/42+1,(d/42)*42,d%42+1),"Giorno "+d)
      }
    }
    check("sei porte una per cotoletta coincidono"){
      for(d<-0 until Six.sum){
        val r=old(Six,Ones,d)
        eqv((r.legacyCutletId,r.legacyDayInCutlet),
          normative(Six,Ones,d),"Giorno "+d)
      }
    }
    check("diciassette porte una per cotoletta coincidono"){
      val g=Vector.fill(17)(42)
      val p=Vector.fill(17)(1)
      for(d<-0 until g.sum by 17){
        val r=old(g,p,d)
        eqv((r.legacyCutletId,r.legacyDayInCutlet),
          normative(g,p,d),"Cutlet "+d)
      }
    }
    check("durata anno massima"){
      val g=Vector.fill(6)(963)
      val r=old(g,Ones,5777)
      eqv((r.gateId,r.legacyDayInCutlet),(6,963),"Anno")
    }
    check("quarantasette porte"){
      val g=Vector.fill(47)(42)
      val p=Vector(8,8,8,8,8,7)
      val r=old(g,p,1973)
      eqv(r.gateId,47,"Gate47")
      eqv((r.legacyCutletId,r.legacyDayInCutlet),(47,42),"Identita legacy al limite")
      eqv(normative(g,p,1973),(6,294),"Cotoletta e giorno locale al limite")
    }
    check("numero cotolette da 6 a 17"){
      for(n<-6 to 17){
       val g=Vector.fill(n+1)(42)
       val p=Vector.fill(n)(1).updated(0,2)
       val r=old(g,p,g.sum-1)
       eqv(r.gateId,n+1,"N "+n)
      }
    }
    check("2048 ingressi casuali deterministici"){
      val rng=new Random(52202026L)
      var mismatches=0
      var matches=0
      for(i<-1 to 2048){
       val n=6+rng.nextInt(12)
       val extra=rng.nextInt(48-n)
       val index=rng.nextInt(n)
       val p=Vector.fill(n)(1).updated(index,1+extra)
       val g=Vector.fill(n+extra)(42+rng.nextInt(31))
       val d=rng.nextInt(g.sum)
       val r=old(g,p,d)
       val start=g.take(r.gateId-1).sum
       eqv((r.gateStartOffset,r.legacyCutletId,r.legacyDayInCutlet),
         (start,r.gateId,d-start+1),"Input "+i)
       val norm=normative(g,p,d)
       val cutletStarts=p.scanLeft(0)(_+_)
       val cutletId=cutletStarts.indexWhere(_ >= r.gateId)
       truth(cutletId>=1 && cutletId<=n,"Gruppo "+i)
       val cutletDay=d-g.take(cutletStarts(cutletId-1)).sum+1
       eqv(norm,(cutletId,cutletDay),"Proiezione indipendente "+i)
       if((r.legacyCutletId,r.legacyDayInCutlet)==norm)matches+=1
       else mismatches+=1
      }
      truth(mismatches>0,"Campione senza divergenze legacy")
      truth(matches>0,"Campione senza casi coincidenti")
    }
    check("due manager contano indipendentemente"){
      val a=new BaseMonsterManager
      val b=new BaseMonsterManager
      for(i<-1 to 100){
       val m=if(i%2==0)a else b
       m.discover26GateToCutletProjection(i,-Huge,Nine,Part,i%378)
      }
      eqv(a.metricsSnapshot("discovery26.gate.cutlet.calls"),BigInt(50),"A")
      eqv(b.metricsSnapshot("discovery26.gate.cutlet.calls"),BigInt(50),"B")
    }
    check("report precedente rimane immutabile"){
      val m=new BaseMonsterManager
      val r=m.discover26GateToCutletProjection(1,2,Nine,Part,42)
      val before=r.copy()
      m.discover26GateToCutletProjection(3,4,Nine,Part,168)
      eqv(r,before,"Report")
    }
    check("BigInt senza troncamento"){
      val r=new BaseMonsterManager().discover26GateToCutletProjection(
       Huge,-Huge,Nine,Part,42)
      eqv((r.calculationDay,r.targetDay),(Huge,-Huge),"BigInt")
    }
    check("trace e status corretti"){
      val r=new BaseMonsterManager().discover26GateToCutletProjection(
       1,2,Nine,Part,42)
      eqv(r.trace,Vector("BOOT","DISCOVERY_26_GATE_TO_CUTLET_PROJECTION"),"Trace")
      eqv(r.status,"LEGACY_GATE_CUTLET_PROJECTION_READY","Status")
    }
    check("input restituiti intatti"){
      val r=old(Nine,Part,42)
      eqv((r.gateGaps,r.cutletPartition,r.dayOffset),(Nine,Part,42),"Input")
    }
    check("rifiuta cinque cotolette"){
      rejectArg("Cinque"){old(Vector.fill(6)(42),Vector(2,1,1,1,1),42)}
    }
    check("rifiuta diciotto cotolette"){
      rejectArg("Diciotto"){old(Vector.fill(18)(42),Vector.fill(18)(1),42)}
    }
    check("rifiuta quarantotto porte"){
      rejectArg("48"){old(Vector.fill(48)(42),Vector.fill(6)(8),42)}
    }
    check("rifiuta partizione incompleta"){
      rejectArg("Partizione"){old(Nine,Vector(2,1,1,1,1,2),42)}
    }
    check("rifiuta cotoletta senza porta"){
      rejectArg("Zero"){old(Nine,Vector(3,0,1,1,2,2),42)}
    }
    check("rifiuta porta sotto 42"){
      rejectArg("Corto"){old(Nine.updated(0,41),Part,42)}
    }
    check("rifiuta porta sopra 963"){
      rejectArg("Lungo"){old(Nine.updated(0,964),Part,42)}
    }
    check("rifiuta anno oltre 5778"){
      rejectArg("Anno"){old(Vector.fill(47)(963),Vector(8,8,8,8,8,7),42)}
    }
    check("rifiuta giorno negativo"){
      rejectArg("Negativo"){old(Nine,Part,-1)}
    }
    check("rifiuta giorno dopo anno"){
      rejectArg("Fine"){old(Nine,Part,378)}
    }
    check("validator accetta il contesto"){
      new BaseValidationManager().requireDiscovery26Ready(ready())
    }
    check("validator rifiuta ID gate falsificato"){
      val c=ready();c.gateProjectionLegacyGateId=Some(3)
      rejectState("Gate"){new BaseValidationManager().requireDiscovery26Ready(c)}
    }
    check("validator rifiuta inizio gate falso"){
      val c=ready();c.gateProjectionLegacyGateStart=Some(0)
      rejectState("Start"){new BaseValidationManager().requireDiscovery26Ready(c)}
    }
    check("validator rifiuta ID cotoletta falso"){
      val c=ready();c.gateProjectionLegacyCutletId=Some(1)
      rejectState("Cutlet"){new BaseValidationManager().requireDiscovery26Ready(c)}
    }
    check("validator rifiuta giorno locale falso"){
      val c=ready();c.gateProjectionLegacyOrdinal=Some(42)
      rejectState("Ordinal"){new BaseValidationManager().requireDiscovery26Ready(c)}
    }
    check("validator rifiuta snapshot falsificata"){
      val c=ready();c.gateProjectionDayOffset=Some(43)
      rejectState("Snapshot"){new BaseValidationManager().requireDiscovery26Ready(c)}
    }
    check("validator rifiuta trace aggiuntiva"){
      val c=ready();c.branchTrace.append("EXTRA")
      rejectState("Trace"){new BaseValidationManager().requireDiscovery26Ready(c)}
    }
    check("validator rifiuta status alterato"){
      val c=ready();c.status="BOOTSTRAPPED"
      rejectState("Status"){new BaseValidationManager().requireDiscovery26Ready(c)}
    }
    check("handler senza bootstrap non pubblica"){
      val c=BaseMonsterContext(1,2)
      c.phase="DISCOVERY_26_GATE_TO_CUTLET_PROJECTION"
      c.gateProjectionGaps=Some(Nine)
      c.gateProjectionPartition=Some(Part)
      c.gateProjectionDayOffset=Some(42)
      rejectState("Boot"){new Discovery26GateToCutletProjectionHandler(new BaseMetricsShell).handle(c)}
      truth(c.gateProjectionSnapshot.isEmpty,"Atomicita")
    }
    check("Stage51 rimane certificato e nessuna PATCH26"){
      val st=new String(Files.readAllBytes(root().resolve("DEVELOPMENT_STAGE.md")),StandardCharsets.UTF_8)
      truth(st.contains("STAGE_51_NATIVE_VERIFICATION=PASS_NATIVE_SCALA_64_PASS_0_FAIL"),"Stage51")
      val current=st.linesIterator.find(_.startsWith("CURRENT_STAGE=")).get.split("=",2)(1).toInt
      val completed=st.linesIterator.find(_.startsWith("LAST_COMPLETED_STAGE=")).get.split("=",2)(1).toInt
      truth(current>=52 && completed>=51 && completed<=current,"Stadi")
      if(completed>=52 || current>52)
       truth(st.contains("STAGE_52_NATIVE_VERIFICATION=PASS_EXPECTED_RED_44_PASS_3_FAIL"),"Certificato")
      val walk=Files.walk(root().resolve("src/main/scala"))
      val source=try walk.iterator().asScala.filter(p=>Files.isRegularFile(p)&&p.toString.endsWith(".scala"))
       .map(p=>new String(Files.readAllBytes(p),StandardCharsets.UTF_8)).mkString("\n")
      finally walk.close()
      if(current==52)truth(!source.contains("def gateToCutletPatch("),"PATCH26 assente")
      else truth(source.contains("def gateToCutletPatch("),"PATCH26 attesa")
    }
    check("equivalenza normativa GATE2_IN_CUTLET1"){
      val r=new BaseMonsterManager().discover26GateToCutletProjection(
        Huge,-Huge,Nine,Part,42)
      val norm=normative(Nine,Part,42)
      eqv(r.legacyCutletId,norm._1,"Gate usato come cotoletta: GATE2_IN_CUTLET1")
    }
    check("equivalenza normativa GATE5_IN_CUTLET3"){
      val r=new BaseMonsterManager().discover26GateToCutletProjection(
        Huge,-Huge,Nine,Part,168)
      val norm=normative(Nine,Part,168)
      eqv(r.legacyCutletId,norm._1,"Gate usato come cotoletta: GATE5_IN_CUTLET3")
    }
    check("equivalenza normativa GATE9_IN_CUTLET6"){
      val r=new BaseMonsterManager().discover26GateToCutletProjection(
        Huge,-Huge,Nine,Part,336)
      val norm=normative(Nine,Part,336)
      eqv(r.legacyCutletId,norm._1,"Gate usato come cotoletta: GATE9_IN_CUTLET6")
    }
    println("\nRISULTATO STADIO 52: "+passed+" PASS, "+failed+" FAIL")
    if(failed!=0)sys.exit(1)
  }
}
