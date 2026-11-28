"""Rebuild exact opcode maps, directed IP graphs and executable-cell versions from real Native step records."""
import argparse
import gzip
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path

PINS={"bootstrap":"6da65824962ed32e0980a1cf9fd6be981fbd82b6",
      "day_count":"ccff205ce45fe267433950ca994ec5aaa49c0352",
      "save":"f99b49cef13a1a036fa43e675cb68bf56f3b03e5",
      "interleaved_day_save":"04212ba0681f583524fb9f5553b075d8a0794d58",
      "work_counts":"7418e1ec5fe88fe5c14b75710dea2d5607527f28"}
CASES={"bootstrap":["0","10"],"day_count":["0 12","1 0"],"save":["1 21","2 12"],
       "interleaved_day_save":["1 12","1 0"],"work_counts":["0 21 1 12","0 12 1 21","1 2 0 1","2 1 0 2"]}
GATE=(1020,1046)


def need(ok,why):
    if not ok: raise ValueError(why)


def oracle(name,raw):
    fields=[int(s) for s in raw.split()]
    if name=="bootstrap": return [str(int(fields==[0]))]
    def valid(s,m): return s==0 or (s==1 and m>0)
    def count(n):
        h=n+15055671
        return -2*h if h<0 else 2*h+1
    M=2**127-1
    def save(n): return 1+(n-1)%M
    pairs=list(zip(fields[::2],fields[1::2]))
    width={"day_count":1,"save":1,"interleaved_day_save":2,"work_counts":7}[name]
    if not all(valid(*pair) for pair in pairs): return ["-1"]*width
    days=[(1-2*s)*m for s,m in pairs]
    a=days[0]
    if name=="work_counts":
        b=days[1]
        nums=[count(a),count(b),abs(a-b)+1,count(a)+count(b),2+(b>a)-(b<a),save(a),save(b)]
    elif name=="interleaved_day_save": nums=[count(a),save(a)]
    elif name=="day_count": nums=[count(a)]
    else: nums=[save(a)]
    return list(map(str,nums))


def save_gzip(path,obj):
    data=json.dumps(obj,separators=(",",":"),sort_keys=True).encode()
    path.write_bytes(gzip.compress(data,mtime=0))


def evaluate(folder,root):
    data=json.loads((folder/"runs.json").read_bytes())
    expected=[(n,s) for n in PINS for s in CASES[n]]
    need([(r["program"],r["raw"]) for r in data["runs"]]==expected,"input matrix")
    peers=data["peer_schedules"]
    need([s["order"] for s in peers]==[[0,1],[1,0]],"peer order")
    for s in peers:
        previous=[32,32]
        need(s["outputs"]==[oracle("work_counts",raw) for raw in CASES["work_counts"][:2]],"live peer output")
        need(len(s["snapshots"])==4,"missing peer observation")
        for step,(digit,index,before,after,ticks) in enumerate(s["snapshots"]):
            need(digit==step//2 and index==s["order"][step%2] and before==previous and ticks>0,"peer timeline")
            want=previous.copy()
            want[index]=[[118,62],[62,118]][digit][index]
            need(after==want,"foreign gate write while peer paused")
            previous=after
    summary={}
    for name,sha in PINS.items():
        source=(root/"src"/(name+".b98")).read_bytes()
        need(hashlib.sha1(b"blob "+str(len(source)).encode()+b"\0"+source).hexdigest()==sha,"source identity")
        original={(x,y):op for y,line in enumerate(source.split(b"\n")) for x,op in enumerate(line) if op!=32}
        edges=Counter()
        directions=Counter()
        ops=Counter()
        visits=Counter()
        gate_versions=Counter()
        targets=Counter()
        observations=[]
        revisits=0
        for ri,r in enumerate(data["runs"]):
            if r["program"]!=name: continue
            need(r["trace"]=="route-%02d.jsonl.gz"%ri and r["source_blob"]==sha,"trace identity")
            mem={}
            writes={}
            previous=None
            pid=None
            op=None
            ticks=0
            local_cells=set()
            with gzip.open(folder/r["trace"],"rt",encoding="ascii") as stream:
                for line in stream:
                    tick,ip,x,y,dx,dy,op,depth,frames,access=json.loads(line)
                    ticks+=1
                    pos=x,y
                    if pid is None:
                        pid=ip
                        need(pos==(0,0) and (dx,dy)==(1,0) and depth==0 and frames==1,"fresh entry")
                    need(tick==ticks and ip==pid and depth>=0 and frames>=1 and (dx,dy)!=(0,0),"bad step metadata")
                    need(op==mem.get(pos,original.get(pos,32)),"fetched byte contradicts last physical writer")
                    if pos in writes:
                        prior= writes[pos]
                        gate_versions[(x,y,op)]+=1
                        observations.append([ri,prior,tick,x,y,op])
                    if previous is not None: edges[previous+pos]+=1
                    previous=pos
                    directions[(dx,dy)]+=1
                    ops[chr(op)]+=1
                    visits[pos]+=1
                    local_cells.add(pos)
                    if op in (ord("p"),ord("g")):
                        need(access and access[0]==chr(op),"missing native memory event")
                        coord=tuple(access[1:3])
                        old=mem.get(coord,original.get(coord,32))
                        need(access[3]==old,"memory value/lineage")
                        targets[(chr(op),)+coord]+=1
                        if op==ord("p"):
                            need(len(access)==5,"write has no after-value")
                            mem[coord]=access[4]
                            writes[coord]=tick
                        else: need(len(access)==4,"invalid read record")
                    else: need(access is None,"unexpected non-p write")
            need(op==ord("@") and ticks==r["ticks"] and r["output"]==r["native_expected"]==oracle(name,r["raw"]),
                 "halt or independent output")
            revisits+=ticks-len(local_cells)
        children,parents=defaultdict(set),defaultdict(set)
        for x,y,u,v in edges:
            children[x,y].add((u,v))
            parents[u,v].add((x,y))
        forks={p for p,ds in children.items() if len(ds)>1}
        joins={p for p,ps in parents.items() if len(ps)>1}
        need(all(v in directions for v in ((1,0),(-1,0),(0,-1),(0,1))) and
             bool(gate_versions) and any(n>1 for n in visits.values()) and all(ops.get(k) for k in "xpg"),
             "2D motion or physical executable rewrite absent")
        if name=="work_counts":
            need({op for x,y,op in gate_versions if (x,y)==GATE}=={62,118} and
                 all(ops.get(k) for k in "[]rwjk_|{}u") and forks and joins,"missing meaningful active geometry")
        def packed_counts(counter):
            return [[*key,n] for key,n in sorted(counter.items())]
        save_gzip(folder/(name+"-graph.json.gz"),{"source_blob":sha,
            "source_map":[[x,y,op] for (x,y),op in sorted(original.items())],"directed_edges":packed_counts(edges),
            "coordinate_visits":packed_counts(visits),"directions":packed_counts(directions),
            "memory_accesses":packed_counts(targets),"written_byte_fetches":observations})
        summary[name]={"native_steps":sum(visits.values()),"visited_cells":len(visits),"directed_edges":len(edges),
                       "returns_to_visited_cell":revisits,"directions":len(directions),
                       "fork_cells":len(forks),"join_cells":len(joins),"fork_and_join_cells":len(forks&joins),
                       "opcode_counts":dict(ops),"written_then_executed":packed_counts(gate_versions)}
    return {"runs":len(data["runs"]),"two_live_program_schedules":len(peers),"programs":summary}


if __name__=="__main__":
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("folder",type=Path)
    p.add_argument("--root",type=Path,default=Path("."))
    args=p.parse_args()
    result=evaluate(args.folder,args.root)
    (args.folder/"geometry.json").write_text(json.dumps(result,sort_keys=True,indent=2)+"\n")
    print("Actual Bootstrap geometry and two paused-peer schedules verified:",result["runs"],"paths,",
          sum(m["native_steps"] for m in result["programs"].values()),"real steps")
