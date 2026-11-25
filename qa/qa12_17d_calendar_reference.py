"""Compare each finished Funge++ calendar result with this branch's independent Native BF98 day_count."""
from __future__ import print_function
import hashlib
import json
import subprocess
import sys

path="reference/day_count.b98"
with open(path,"rb") as stream:
    code=stream.read()
source_id=hashlib.sha1(("blob %d\0"%len(code)).encode("ascii")+code).hexdigest()
with open(sys.argv[1],"rb") as f:
    rows=json.load(f)
for row in rows:
    value=row["stdout"][-2]
    fields="%d %d\n"%(int(value<0),abs(value))
    p=subprocess.Popen(["timeout","-k","2s","35s","pyfunge","--disable-fprint","--no-concurrent",
                        "--no-filesystem","-v98","-d2",path],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
    output,_=p.communicate(fields.encode("ascii"))
    tokens=output.split()
    if p.returncode or len(tokens)!=1 or int(tokens[0])!=row["stdout"][-1]:
        raise ValueError("Independent day_count mismatch for signed day "+str(value))
    row["native_befunge_day_count"]=int(tokens[0])
    row["native_reference_blob"]=source_id
with open(sys.argv[1],"wb") as f:
    f.write((json.dumps(rows,separators=(",",":"))+"\n").encode("ascii"))
print("Native independent BF98 oracle",source_id,len(rows))
