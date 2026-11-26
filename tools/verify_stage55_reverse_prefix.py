from pathlib import Path
import hashlib,json,os,sys
sys.set_int_max_str_digits(0)
d=Path("logs/stage55_reverse_prefix")
expected="""1 1 c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8 cd5ce4036fc8e99355a4bab5d48c3db473422083d035df5e0af25297be1be3b6
2 2 d14117c552025c61ee7f5af7140344e390202cdec045e219f1925e60495a53ce 1191f818e77c6dd94d3d2e8e70ee0a419b2a2eb3234ffd60098f8481769c99ac
3 3 da8d066cf0c7a5d5a613edf7de109301969997102c19794d41a165ec62c30c4a 25b8697dfb238f466a4c2457e168d3c6cdb177fa8f9b4390dd91e844ba4d9d46
4 4 2b8fbcebcd72d7197a6b216c3271cd241cdd6ab81cfbb7da17387ddbf2498cba 637ec208a1ddbbd3f5b8d236502146a4eb0c84f732736d891e7f243fa47d8d87
5 5 8c0e6abeeee779f8a89c67f7e12aa0198118fdee4cc76290648ae1d92719211f f9bace24e466e0a54b8c9438bb024815f6c67185358153e0fbae5a0732e9a32b
6 6 c47a58f5b9fb8b9d1bb3c17be5b8573dcf72b08e2a3ad0d429672916c5b9f49e 71223178e09a86889e1c5497cd7ae30e2458cdb58d0e0d11b96ecb3460959443
7 7 311b713ba26e926b60243b9a63b0bb8d13132a17d95a346b4841b02e5b5e2eec 9bcda2a7da72a077ee51db8debd858b2cdd578ab5b95913212209d9bf2a313fa
8 4 3adfc02aa07e839ae8477c1852b05a3012b916dad070e3aa24a9834757e138c3 038e3565af370fbac347033fada61fdfe4830e265d4cf94c40d6f6ceca9acd79
9 8 d17a7f10a6ed4ff570134adb6e13f0d028118d9985b56ee6a4c28249924ecf0a 6ba97455e7575822d215fe020e7140815d55759f889710f99c23e2281fd3633a
10 9 42433e519055e6f1d25b640264c4ce3b1f72abc5e4a9df66a820209ff4c7d96a 39053710e806551b019c8a4b87ef0e2c98afece5efc384a88431dd91a5b33fc8
11 10 fd999f8e3c4cf00910df2956eb7dfff62bc1b891d503ec51d5336ac3e44c4709 e0c60e5e0b4deb0b169269402d43c420d4fe5c4b2295ba3dc5f7473be9776ac1
12 9 9cc21ee7a163a496a079b4610124dd7a83e612ae111a07c7bf6f71f23ed69c44 a39b215363a95ead14111432cd29b779be0e333857d7d7570d217cf0abdada55
""".splitlines()
def sha(s): return hashlib.sha256(s.encode("ascii")).hexdigest()
L=json.loads(Path("tests/fixtures/stage55_year5000_appendix_a_metadata.json").read_text())["month_lengths"]
W=json.loads(Path("tests/fixtures/stage55_year5000_middle_word.json").read_text())
R=L.copy()
total=(d/"root_count.txt").read_text(); rank=(d/"root_rank.txt").read_text()
assert sha(total)==expected[0].split()[2] and sha(rank)==expected[0].split()[3]
assert int(rank)==int(total)//2+1
assert json.loads((d/"tiny.json").read_text())=={"families":115,"states":1335,"blocks":1697}
for line in expected:
    p,i,h,r=line.split(); p,i=int(p),int(i)
    f=d/f"cursor_{p:02}.json"
    assert f.is_file(), f"missing completed cursor {p}"
    a=json.loads(f.read_text())
    assert (a["position"],a["symbol"],a["sha"])==(p,i,os.environ["GITHUB_SHA"])
    assert i==W[p-1] and sha(a["count"])==h and sha(a["local_rank"])==r
    R[i-1]-=1
    assert a["remaining"]==R and a["prefix"]==W[:p]
    assert a["legal_blocks"]==[1,2,3,4,5,6,7,8,8,9,10,11][p-1]
    assert 0<a["peak_rss_kib"]<3*1024*1024
    assert 1<=int(a["local_rank"])<=int(a["count"])<=int(total)
    assert a["external_calls"]==(0 if p==1 else 1)
    print(f"CURSOR {p} VERIFIED",flush=True)
    total=a["count"]
report=json.loads((d/"native_complete.json").read_text())
assert report["positions"]==12 and report["sha"]==os.environ["GITHUB_SHA"] and not report["production_used"] and not report["stage55_accepted"]
assert report["elapsed"]<1800
print("REVERSE_PREFIX_DIFFERENTIAL_PASS 12/12; STAGE55 OPEN")
