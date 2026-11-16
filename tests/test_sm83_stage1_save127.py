#!/usr/bin/env python3
"""Independent signed SAVE127 Host oracle; NOT SM83 execution evidence."""
from random import Random
M = (1 << 127) - 1
BANK = 8192

def save_math(n):
    return 1 + ((n - 1) % M)

def stream_mod(raw):
    r = 0
    for b in reversed(raw):
        r = (256 * r + b) % M
    return r

def reference(active, owner, lease, banks, sign, length):
    old = {b: bytes(v) for b,v in banks.items()}
    def reject(s):
        assert all(bytes(banks[b]) == v for b,v in old.items())
        return s,sign,length
    if not active: return reject(6)
    if owner not in range(1,254) or sign not in (0,1): return reject(2)
    if not 1 <= len(lease) <= 13 or len(set(lease)) != len(lease): return reject(2)
    if any(b not in banks for b in lease): return reject(2)
    if length < 0 or length > BANK*len(lease): return reject(2)
    raw = b"".join(old[b] for b in lease)
    if (length==0 and sign) or (length and raw[length-1]==0): return reject(2)
    mag = int.from_bytes(raw[:length],"little")
    n = -mag if sign else mag
    answer = save_math(n)
    residue = stream_mod(raw[:length])
    independently = (M-residue)%M if sign else residue
    assert answer == (independently or M)
    assert 1 <= answer <= M
    banks[lease[0]][:16] = answer.to_bytes(16,"little")
    assert bytes(banks[lease[0]][16:]) == old[lease[0]][16:]
    assert all(bytes(banks[b]) == old[b] for b in banks if b != lease[0])
    return 0,0,(answer.bit_length()+7)//8

def main():
    rng=Random(0x73127)
    cases=0
    leases=((3,),(3,5),(2,3,5,6,7,8,9,10,11,12,13,14,15))
    for lease in leases:
        for length in (0,1,2,15,16,17,18,255,256,8192,8193,len(lease)*BANK):
            if length>len(lease)*BANK: continue
            for sign in (0,1):
                for seed in (1,127,255):
                    banks={b:bytearray([0x7d]*BANK) for b in range(2,16)}
                    payload=bytearray(length)
                    if length:
                        payload[-1]=seed
                        if length>1: payload[0]=rng.randrange(256)
                    padded=payload.ljust(BANK*len(lease),b"\x00")
                    for i,b in enumerate(lease):
                        banks[b][:]=padded[i*BANK:(i+1)*BANK]
                    old_peer=bytes(banks[4])
                    status,s,n=reference(True,61,lease,banks,sign,length)
                    assert status==(2 if length==0 and sign else 0)
                    assert bytes(banks[4])==old_peer
                    if status==0:
                        raw=int.from_bytes(payload,"little")
                        answer=save_math(-raw if sign else raw)
                        assert (s,n)==(0,(answer.bit_length()+7)//8)
                        assert int.from_bytes(banks[lease[0]][:16],"little")==answer
                    cases+=1
    for active,owner,sign,length in (
        (False,61,0,1),(True,254,0,1),(True,61,2,1),
        (True,61,1,0),(True,61,0,8193),(True,61,0,2)):
        banks={3:bytearray(BANK),4:bytearray([0xc3]*BANK)}
        banks[3][0]=1
        status,_,_=reference(active,owner,(3,),banks,sign,length)
        assert status in (2,6)
        cases+=1
    for n in (-(M+1),-M,-(M-1),-1,0,1,M-1,M,M+1,
              -(1<<127),1<<127,-(1<<128),1<<128):
        assert save_math(n)==((n-1)%M)+1
        cases+=1
    print(f"HOST_STAGE1_SAVE127_ORACLE=PASS cases={cases} "
          "signed_euclidean=YES width_127_128=YES boundary_8192_8193=YES "
          "full_13_bank_input=YES nonowner_immutable=YES invalid_immutable=YES "
          "native_execution=NOT_CLAIMED")

if __name__=="__main__":
    main()
