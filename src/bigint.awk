# Desimalt heiltalslag for verdiar som må vere eksakte utover maskintalet sitt trygge område.

function bi_strip(s,    neg,i,c) {
    s = s ""
    neg = 0
    if (substr(s,1,1) == "-") { neg = 1; s = substr(s,2) }
    i = 1
    while (i < length(s) && substr(s,i,1) == "0") i++
    s = substr(s,i)
    if (s == "" || s ~ /^0+$/) return "0"
    return neg ? "-" s : s
}

function bi_sign(s) { s = bi_strip(s); return substr(s,1,1)=="-" ? -1 : (s=="0" ? 0 : 1) }
function bi_abs(s) { s=bi_strip(s); return substr(s,1,1)=="-" ? substr(s,2) : s }
function bi_neg(s) { s=bi_strip(s); return s=="0" ? "0" : (substr(s,1,1)=="-" ? substr(s,2) : "-" s) }
function bi_eq(a,b) { return bi_cmp(a,b) == 0 }

function bi_cmp_abs(a,b,    la,lb,i,da,db) {
    a=bi_abs(a); b=bi_abs(b); la=length(a); lb=length(b)
    if (la < lb) return -1
    if (la > lb) return 1
    for (i=1;i<=la;i++) {
        da=substr(a,i,1)+0; db=substr(b,i,1)+0
        if (da<db) return -1
        if (da>db) return 1
    }
    return 0
}

function bi_cmp(a,b,    sa,sb,c) {
    a=bi_strip(a); b=bi_strip(b); sa=bi_sign(a); sb=bi_sign(b)
    if (sa < sb) return -1
    if (sa > sb) return 1
    if (sa == 0) return 0
    c=bi_cmp_abs(a,b)
    return sa>0 ? c : -c
}

function bi_add_abs(a,b,    i,j,carry,out,da,db,s) {
    a=bi_abs(a); b=bi_abs(b); i=length(a); j=length(b); carry=0; out=""
    while (i>0 || j>0 || carry>0) {
        da = i>0 ? substr(a,i,1)+0 : 0
        db = j>0 ? substr(b,j,1)+0 : 0
        s = da + db + carry
        out = (s % 10) out
        carry = int(s/10)
        i--; j--
    }
    return bi_strip(out)
}

function bi_sub_abs(a,b,    i,j,borrow,out,da,db,d) {
    a=bi_abs(a); b=bi_abs(b)
    if (bi_cmp_abs(a,b) < 0) return ""
    i=length(a); j=length(b); borrow=0; out=""
    while (i>0) {
        da=substr(a,i,1)+0-borrow
        db=j>0 ? substr(b,j,1)+0 : 0
        if (da < db) { da += 10; borrow=1 } else borrow=0
        d=da-db
        out=d out
        i--; j--
    }
    return bi_strip(out)
}

function bi_add(a,b,    sa,sb,c,r) {
    a=bi_strip(a); b=bi_strip(b); sa=bi_sign(a); sb=bi_sign(b)
    if (sa==0) return b
    if (sb==0) return a
    if (sa==sb) { r=bi_add_abs(a,b); return sa<0 ? "-" r : r }
    c=bi_cmp_abs(a,b)
    if (c==0) return "0"
    if (c>0) { r=bi_sub_abs(a,b); return sa<0 ? "-" r : r }
    r=bi_sub_abs(b,a); return sb<0 ? "-" r : r
}

function bi_sub(a,b) { return bi_add(a,bi_neg(b)) }

function bi_mul_abs(a,b,    i,j,la,lb,da,db,k,maxk,carry,v,out,R) {
    a=bi_abs(a); b=bi_abs(b)
    if (a=="0" || b=="0") return "0"
    la=length(a); lb=length(b)
    delete R
    for (i=la; i>=1; i--) {
        da=substr(a,i,1)+0
        for (j=lb; j>=1; j--) {
            db=substr(b,j,1)+0
            k=(la-i+1)+(lb-j+1)-1
            R[k]+=da*db
        }
    }
    maxk=la+lb
    carry=0
    for (k=1; k<=maxk; k++) {
        v=R[k]+carry
        R[k]=v%10
        carry=int(v/10)
    }
    while (carry>0) { maxk++; R[maxk]=carry%10; carry=int(carry/10) }
    while (maxk>1 && R[maxk]==0) maxk--
    out=""
    for (k=maxk; k>=1; k--) out=out R[k]
    return bi_strip(out)
}

function bi_mul(a,b,    s,r) {
    a=bi_strip(a); b=bi_strip(b)
    if (a=="0" || b=="0") return "0"
    s=bi_sign(a)*bi_sign(b); r=bi_mul_abs(a,b)
    return s<0 ? "-" r : r
}

function bi_square(a) { return bi_mul(a,a) }

function bi_mul_small(a,n,    neg,i,carry,d,v,out) {
    a=bi_strip(a); n+=0
    if (a=="0" || n==0) return "0"
    neg=(bi_sign(a)<0)
    if (n<0) { neg=!neg; n=-n }
    a=bi_abs(a); carry=0; out=""
    for (i=length(a); i>=1; i--) {
        d=substr(a,i,1)+0
        v=d*n+carry
        out=(v%10) out
        carry=int(v/10)
    }
    while (carry>0) { out=(carry%10) out; carry=int(carry/10) }
    out=bi_strip(out)
    return neg ? "-" out : out
}

function bi_divmod_abs(a,b,    i,d,rem,q,qdig,k,prod) {
    a=bi_abs(a); b=bi_abs(b)
    if (b=="0") { BI_ERROR="deling på null"; BI_DIV_Q=""; BI_DIV_R=""; return 0 }
    rem="0"; q=""
    for (i=1; i<=length(a); i++) {
        d=substr(a,i,1)
        rem=bi_strip((rem=="0" ? "" : rem) d)
        qdig=0
        for (k=9; k>=1; k--) {
            prod=bi_mul_small(b,k)
            if (bi_cmp_abs(prod,rem)<=0) { qdig=k; rem=bi_sub_abs(rem,prod); break }
        }
        q=q qdig
    }
    BI_DIV_Q=bi_strip(q); BI_DIV_R=bi_strip(rem); return 1
}

function bi_div_floor(a,b,    sa,qa,ra,q) {
    a=bi_strip(a); b=bi_strip(b)
    if (bi_sign(b)<=0) { BI_ERROR="delaren må vere positiv"; return "" }
    sa=bi_sign(a)
    bi_divmod_abs(a,b); qa=BI_DIV_Q; ra=BI_DIV_R
    if (sa>=0) return qa
    if (ra=="0") return bi_neg(qa)
    q=bi_add_abs(qa,"1")
    return bi_neg(q)
}

function bi_mod_euclid(a,b,    sa,r) {
    a=bi_strip(a); b=bi_strip(b)
    if (bi_sign(b)<=0) { BI_ERROR="modulus må vere positiv"; return "" }
    sa=bi_sign(a); bi_divmod_abs(a,b); r=BI_DIV_R
    if (sa>=0 || r=="0") return r
    return bi_sub_abs(b,r)
}

function bi_mod_small(a,m,    i,r,d,neg) {
    a=bi_strip(a); neg=bi_sign(a)<0; a=bi_abs(a); r=0
    for (i=1;i<=length(a);i++) { d=substr(a,i,1)+0; r=(r*10+d)%m }
    if (neg && r!=0) r=m-r
    return r
}

function bi_abs_diff(a,b,    c) { c=bi_cmp(a,b); return c>=0 ? bi_sub(a,b) : bi_sub(b,a) }
function bi_min(a,b) { return bi_cmp(a,b)<=0 ? bi_strip(a) : bi_strip(b) }
function bi_max(a,b) { return bi_cmp(a,b)>=0 ? bi_strip(a) : bi_strip(b) }

function bi_pow_small(base,power,    r,i) {
    r="1"
    for (i=0;i<power;i++) r=bi_mul_small(r,base)
    return r
}

function bi_to_native_if_safe(a) { return bi_strip(a)+0 }
