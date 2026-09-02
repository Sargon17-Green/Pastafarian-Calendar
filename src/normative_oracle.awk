# Rein testreferanse for den normative kalenderkjernen. Produksjonslaget får ikkje kalle denne fila.

function oracle_init(    i) {
    M="170141183460469231731687303715884105727"
    TABLETS_DAY=-278522
    FOUNDATION_DAY=-15055671
    GATE_GAP_MIN=42; GATE_GAP_MAX=963
    YEAR_MIN_DAYS=252; YEAR_MAX_DAYS=5778
    MIN_CUTLETS=6; MAX_CUTLETS=17
    MIN_MONTHS=3; MAX_MONTHS=47
    MIN_MONTH_DAYS=4; MAX_MONTH_DAYS=123
    WHEAT=1; BARLEY=2; SALT=3; BITTER=4; RED=5

    SEAL_GATE_GAP=1
    SEAL_YEAR_5000=10
    SEAL_NEXT_YEAR=11
    SEAL_PREVIOUS_YEAR=12
    SEAL_CUTLET_COUNT=20
    SEAL_CUTLET_PARTITION=21
    SEAL_CUTLET_NAMES=22
    SEAL_MONTH_COUNT=30
    SEAL_MONTH_LENGTHS=31
    SEAL_MONTH_WEAVING=32
    SEAL_MONTH_NAMES=33

    BOWL_PRIME[1]=17; BOWL_PRIME[2]=19; BOWL_PRIME[3]=23
    BOWL_PRIME[4]=29; BOWL_PRIME[5]=31; BOWL_PRIME[6]=37
    BOWL_STONE[1]=WHEAT; BOWL_STONE[2]=BARLEY; BOWL_STONE[3]=SALT
    BOWL_STONE[4]=BITTER; BOWL_STONE[5]=RED; BOWL_STONE[6]=WHEAT

    HCA[1]=3; HCB[1]=4; HCC[1]=6; HCD[1]=8
    HCA[2]=5; HCB[2]=7; HCC[2]=10; HCD[2]=12
    HCA[3]=7; HCB[3]=10; HCC[3]=14; HCD[3]=16
    HCA[4]=9; HCB[4]=13; HCC[4]=18; HCD[4]=20
    HCA[5]=11; HCB[5]=16; HCC[5]=22; HCD[5]=24
    HCA[6]=13; HCB[6]=19; HCC[6]=26; HCD[6]=28
    HCA[7]=15; HCB[7]=22; HCC[7]=30; HCD[7]=32
    HIDDEN_STONE[1]=WHEAT; HIDDEN_STONE[2]=BARLEY; HIDDEN_STONE[3]=SALT
    HIDDEN_STONE[4]=BITTER; HIDDEN_STONE[5]=RED; HIDDEN_STONE[6]=WHEAT; HIDDEN_STONE[7]=BARLEY

    VGA[1]=3;  VGB[1]=5;  VGC[1]=7;  VGD[1]=11; VGK[1]=WHEAT
    VGA[2]=5;  VGB[2]=7;  VGC[2]=11; VGD[2]=13; VGK[2]=BARLEY
    VGA[3]=7;  VGB[3]=11; VGC[3]=13; VGD[3]=17; VGK[3]=SALT
    VGA[4]=11; VGB[4]=13; VGC[4]=17; VGD[4]=19; VGK[4]=BITTER
    VGA[5]=13; VGB[5]=17; VGC[5]=19; VGD[5]=23; VGK[5]=RED
    VGA[6]=17; VGB[6]=19; VGC[6]=23; VGD[6]=29; VGK[6]=WHEAT
    VGA[7]=19; VGB[7]=23; VGC[7]=29; VGD[7]=31; VGK[7]=BARLEY
    VGA[8]=23; VGB[8]=29; VGC[8]=31; VGD[8]=37; VGK[8]=SALT
    VGA[9]=29; VGB[9]=31; VGC[9]=37; VGD[9]=41; VGK[9]=BITTER
    VGA[10]=31; VGB[10]=37; VGC[10]=41; VGD[10]=43; VGK[10]=RED
    VGA[11]=37; VGB[11]=41; VGC[11]=43; VGD[11]=47; VGK[11]=WHEAT

    if (!ORACLE_STONES_READY) { build_stones(); ORACLE_STONES_READY=1 }
    if (!ORACLE_GATES_READY) {
        delete GATE; GATE[0]=FOUNDATION_DAY; MIN_GATE_IDX=0; MAX_GATE_IDX=0; ORACLE_GATES_READY=1
    }
}

function nmod(x,d,    r) { r=x%d; if (r<0) r+=d; return r }
function wrap1(p,n) { return nmod(p-1,n)+1 }
function ceil_div_native(a,b) { return int((a+b-1)/b) }
function min_native(a,b) { return a<b?a:b }
function max_native(a,b) { return a>b?a:b }

function save_big(x,    r) {
    r=bi_mod_euclid(bi_sub(x,"1"),M)
    return bi_add(r,"1")
}

function day_count(day) {
    if (day==FOUNDATION_DAY) return "1"
    if (day>FOUNDATION_DAY) return (2*(day-FOUNDATION_DAY)+1) ""
    return (2*(FOUNDATION_DAY-day)) ""
}

function work_counts(cday,tday) {
    COUNT_ACTION=day_count(cday)
    COUNT_TARGET=day_count(tday)
    COUNT_DISTANCE=(tday>=cday ? tday-cday : cday-tday)+1
    COUNT_DISTANCE=COUNT_DISTANCE ""
    COUNT_CONNECTION=bi_add(COUNT_ACTION,COUNT_TARGET)
    COUNT_DIRECTION=(tday<cday?1:(tday==cday?2:3))
}

function stone_get(i,k) { return STONE[i SUBSEP k] }
function stone_set(i,k,v) { STONE[i SUBSEP k]=v }

function build_stones(    i,w,b,s,m,r,nw,nb,ns,nm,nr) {
    delete STONE
    stone_set(1,WHEAT,"17"); stone_set(1,BARLEY,"29"); stone_set(1,SALT,"43"); stone_set(1,BITTER,"71"); stone_set(1,RED,"101")
    for (i=2;i<=46;i++) {
        w=stone_get(i-1,WHEAT); b=stone_get(i-1,BARLEY); s=stone_get(i-1,SALT); m=stone_get(i-1,BITTER); r=stone_get(i-1,RED)
        nw=save_big(bi_add(bi_add(bi_square(w),bi_mul_small(b,3)),i ""))
        nb=save_big(bi_add(bi_add(bi_square(b),bi_mul_small(s,5)),w))
        ns=save_big(bi_add(bi_add(bi_square(s),bi_mul_small(m,7)),b))
        nm=save_big(bi_add(bi_add(bi_square(m),bi_mul_small(r,11)),s))
        nr=save_big(bi_add(bi_add(bi_square(r),bi_mul_small(w,13)),m))
        stone_set(i,WHEAT,nw); stone_set(i,BARLEY,nb); stone_set(i,SALT,ns); stone_set(i,BITTER,nm); stone_set(i,RED,nr)
    }
}

function build_hidden(    k,x,g,kind,sum) {
    delete HIDDEN
    for (k=1;k<=7;k++) {
        x=COUNT_ACTION
        x=bi_add(x,bi_mul_small(COUNT_TARGET,HCA[k]))
        x=bi_add(x,bi_mul_small(COUNT_DISTANCE,HCB[k]))
        x=bi_add(x,bi_mul_small(COUNT_CONNECTION,HCC[k]))
        x=bi_add(x,bi_mul_small(COUNT_DIRECTION "",HCD[k]))
        sum=bi_add(bi_add(stone_get(k,WHEAT),stone_get(k,BARLEY)),bi_add(stone_get(k,SALT),bi_add(stone_get(k,BITTER),stone_get(k,RED))))
        x=save_big(bi_add(x,sum))
        for (g=1;g<=7;g++) {
            kind=HIDDEN_STONE[g]
            x=save_big(bi_add(bi_add(bi_add(bi_square(x),bi_mul_small(x,3)),stone_get(k,kind)),g ""))
        }
        HIDDEN[k]=x
    }
}

function prior_value(i,back,    slot,k) {
    slot=i-back
    if (slot>=1) return DROP[slot]
    k=1-slot
    return HIDDEN[k]
}

function build_visible(    i,p1,p3,p7,x,g,kind) {
    delete DROP
    for (i=1;i<=46;i++) {
        p1=prior_value(i,1); p3=prior_value(i,3); p7=prior_value(i,7)
        x=bi_mul(stone_get(i,WHEAT),COUNT_ACTION)
        x=bi_add(x,bi_mul(stone_get(i,BARLEY),COUNT_TARGET))
        x=bi_add(x,bi_mul(stone_get(i,SALT),COUNT_DISTANCE))
        x=bi_add(x,bi_mul(stone_get(i,BITTER),COUNT_CONNECTION))
        x=bi_add(x,bi_mul_small(stone_get(i,RED),COUNT_DIRECTION))
        x=bi_add(x,p1); x=bi_add(x,bi_mul_small(p3,3)); x=bi_add(x,bi_mul_small(p7,5)); x=bi_add(x,i "")
        x=save_big(x)
        for (g=1;g<=11;g++) {
            kind=VGK[g]
            x=save_big(bi_add(bi_add(bi_add(bi_add(bi_add(bi_square(x),bi_mul_small(x,VGA[g])),bi_mul_small(p1,VGB[g])),bi_mul_small(p3,VGC[g])),bi_mul_small(p7,VGD[g])),stone_get(i,kind)))
        }
        DROP[i]=x
    }
}

function factorial_native(n,    i,r) { r=1; for (i=2;i<=n;i++) r*=i; return r }

function bowl_order_from_number(rank1,    rank0,n,block,q,pos,i,idx) {
    delete ORDER; delete REMAINING_ORDER
    for (i=1;i<=6;i++) REMAINING_ORDER[i]=i
    rank0=rank1-1; n=6
    for (pos=1;pos<=6;pos++) {
        block=factorial_native(n-1)
        q=int(rank0/block); rank0=nmod(rank0,block)
        idx=q+1; ORDER[pos]=REMAINING_ORDER[idx]
        for (i=idx;i<n;i++) REMAINING_ORDER[i]=REMAINING_ORDER[i+1]
        delete REMAINING_ORDER[n]
        n--
    }
}

function bowl_order_from_drop(v) { bowl_order_from_number(bi_mod_small(bi_sub(v,"1"),720)+1) }

function initial_bowls(    id,s) {
    delete BOWL
    for (id=1;id<=6;id++) {
        s=COUNT_ACTION
        s=bi_add(s,bi_mul_small(COUNT_TARGET,id))
        s=bi_add(s,COUNT_DISTANCE); s=bi_add(s,COUNT_CONNECTION); s=bi_add(s,COUNT_DIRECTION "")
        s=bi_add(s,(BOWL_PRIME[id]*BOWL_PRIME[id]) "")
        BOWL[id]=save_big(bi_add(bi_square(s),id ""))
    }
}

function apply_visible_to_bowls(    i,drop,p1,p2,p3,pos,id,prev,nxt,kind,s) {
    delete ORDER46
    for (i=1;i<=46;i++) {
        drop=DROP[i]; bowl_order_from_drop(drop)
        delete OLD_BOWL; delete POUR; delete NEXT_BOWL
        for (id=1;id<=6;id++) OLD_BOWL[id]=BOWL[id]
        p1=ORDER[1]; p2=ORDER[2]; p3=ORDER[3]
        POUR[1]=save_big(bi_add(bi_add(bi_square(drop),bi_mul(stone_get(i,WHEAT),OLD_BOWL[p1])),(3*i) ""))
        POUR[2]=save_big(bi_add(bi_add(bi_square(drop),bi_mul(stone_get(i,BARLEY),OLD_BOWL[p2])),(5*i) ""))
        POUR[3]=save_big(bi_add(bi_add(bi_square(drop),bi_mul(stone_get(i,SALT),OLD_BOWL[p3])),(7*i) ""))
        POUR[4]="0"; POUR[5]="0"; POUR[6]="0"
        for (pos=1;pos<=6;pos++) {
            id=ORDER[pos]; prev=ORDER[wrap1(pos-1,6)]; nxt=ORDER[wrap1(pos+1,6)]; kind=BOWL_STONE[pos]
            s=OLD_BOWL[id]
            s=bi_add(s,bi_mul_small(OLD_BOWL[prev],2)); s=bi_add(s,bi_mul_small(OLD_BOWL[nxt],3))
            s=bi_add(s,POUR[pos]); s=bi_add(s,drop); s=bi_add(s,stone_get(i,kind))
            NEXT_BOWL[id]=save_big(bi_add(bi_square(s),bi_add(bi_mul_small(bi_mul(OLD_BOWL[prev],OLD_BOWL[nxt]),5),(i*pos) "")))
        }
        for (id=1;id<=6;id++) BOWL[id]=NEXT_BOWL[id]
        if (i==46) for (pos=1;pos<=6;pos++) ORDER46[pos]=ORDER[pos]
    }
}

function post_stir12(    stir,id,pos,prev,nxt,s,saved) {
    for (stir=1;stir<=12;stir++) {
        delete OLD_BOWL; delete NEXT_BOWL
        saved="0"
        for (id=1;id<=6;id++) { OLD_BOWL[id]=BOWL[id]; saved=bi_add(saved,BOWL[id]) }
        saved=save_big(bi_add(saved,(149*stir) ""))
        bowl_order_from_number(bi_mod_small(bi_sub(saved,"1"),720)+1)
        for (pos=1;pos<=6;pos++) {
            id=ORDER[pos]; prev=ORDER[wrap1(pos-1,6)]; nxt=ORDER[wrap1(pos+1,6)]
            s=OLD_BOWL[id]
            s=bi_add(s,bi_mul_small(OLD_BOWL[prev],3)); s=bi_add(s,bi_mul_small(OLD_BOWL[nxt],5))
            s=bi_add(s,saved); s=bi_add(s,stir ""); s=bi_add(s,(pos*pos) "")
            NEXT_BOWL[id]=save_big(bi_add(bi_square(s),bi_mul_small(bi_mul(OLD_BOWL[prev],OLD_BOWL[nxt]),7)))
        }
        for (id=1;id<=6;id++) BOWL[id]=NEXT_BOWL[id]
    }
}

function sauce(cday,tday,    id,pos) {
    work_counts(cday,tday); build_hidden(); build_visible(); initial_bowls(); apply_visible_to_bowls(); post_stir12()
    delete SAUCE_BOWL; delete SAUCE_ORDER46
    for (id=1;id<=6;id++) SAUCE_BOWL[id]=BOWL[id]
    for (pos=1;pos<=6;pos++) SAUCE_ORDER46[pos]=ORDER46[pos]
}

function sauce_snapshot_to_structure(    i) {
    delete STRUCT_BOWL; delete STRUCT_ORDER46
    for (i=1;i<=6;i++) { STRUCT_BOWL[i]=SAUCE_BOWL[i]; STRUCT_ORDER46[i]=SAUCE_ORDER46[i] }
}

function sauce_restore_structure(    i) {
    delete SAUCE_BOWL; delete SAUCE_ORDER46
    for (i=1;i<=6;i++) { SAUCE_BOWL[i]=STRUCT_BOWL[i]; SAUCE_ORDER46[i]=STRUCT_ORDER46[i] }
}

function ask_bowl(bowlid,seal,    p,nextid,first,direction) {
    for (p=1;p<=6;p++) if (SAUCE_ORDER46[p]==bowlid) break
    nextid=SAUCE_ORDER46[wrap1(p+1,6)]
    first=save_big(bi_add(bi_add(bi_square(bi_add(bi_add(SAUCE_BOWL[bowlid],seal ""),"181")),bi_mul_small(SAUCE_BOWL[nextid],179)),seal ""))
    direction=save_big(bi_add(bi_add(bi_square(bi_add(bi_add(bi_add(first,seal ""),"1"),"193")),bi_mul_small(first,193)),bi_mul_small(SAUCE_BOWL[6],197)))
    STREAM_FIRST=first; STREAM_STEP=(bi_mod_small(direction,2)==1?1:-1)
}

function answer_at(k) { return bi_add(bi_mod_euclid(bi_add(bi_sub(STREAM_FIRST,"1"),(STREAM_STEP*k) ""),M),"1") }

function choose_rank_short(N,    limit,k,x,q) {
    q=bi_div_floor(M,N); limit=bi_mul(q,N); k=0
    while (1) {
        x=answer_at(k)
        if (bi_cmp(x,limit)<=0) { CHOSEN_RANK=bi_add(bi_mod_euclid(bi_sub(x,"1"),N),"1"); return }
        k++
    }
}

function choose_rank_wide(N,    places,space,j,wide,weight,digit,limit,q) {
    places=1; space=M
    while (bi_cmp(space,N)<0) { places++; space=bi_mul(space,M) }
    wide="1"; weight="1"
    for (j=0;j<places;j++) {
        digit=bi_sub(answer_at(j),"1")
        wide=bi_add(wide,bi_mul(digit,weight)); weight=bi_mul(weight,M)
    }
    q=bi_div_floor(space,N); limit=bi_mul(q,N)
    while (bi_cmp(wide,limit)>0) wide=bi_add(bi_mod_euclid(bi_add(bi_sub(wide,"1"),STREAM_STEP ""),space),"1")
    CHOSEN_RANK=bi_add(bi_mod_euclid(bi_sub(wide,"1"),N),"1")
}

function choose_rank(N) { if (bi_cmp(N,M)<=0) choose_rank_short(N); else choose_rank_wide(N) }

function falling_factorial(n,k,    r,j) { r="1"; for (j=0;j<k;j++) r=bi_mul_small(r,n-j); return r }

function unrank_distinct(masterCount,k,rank,    pos,suf,block,cand,nrem,i,chosen) {
    delete NAME_INDEX; delete NAME_REMAIN
    for (i=1;i<=masterCount;i++) NAME_REMAIN[i]=i
    nrem=masterCount
    for (pos=1;pos<=k;pos++) {
        suf=k-pos; block=falling_factorial(nrem-1,suf)
        for (cand=1;cand<=nrem;cand++) {
            if (bi_cmp(rank,block)>0) rank=bi_sub(rank,block)
            else {
                chosen=NAME_REMAIN[cand]; NAME_INDEX[pos]=chosen
                for (i=cand;i<nrem;i++) NAME_REMAIN[i]=NAME_REMAIN[i+1]
                delete NAME_REMAIN[nrem]; nrem--; break
            }
        }
    }
}

function bc_prepare(total,slots,lo,hi) { BC_TOTAL=total; BC_SLOTS=slots; BC_LO=lo; BC_HI=hi; delete BC_MEMO }
function bc_count(rem,k,    key,x,s) {
    if (k==0) return rem==0?"1":"0"
    if (rem<k*BC_LO || rem>k*BC_HI) return "0"
    key=rem SUBSEP k; if (key in BC_MEMO) return BC_MEMO[key]
    s="0"; for (x=BC_LO;x<=BC_HI;x++) s=bi_add(s,bc_count(rem-x,k-1))
    BC_MEMO[key]=s; return s
}
function bc_unrank(total,slots,rank,    pos,x,block,rem) {
    delete COMP; rem=total
    for (pos=1;pos<=slots;pos++) {
        for (x=BC_LO;x<=BC_HI;x++) {
            block=bc_count(rem-x,slots-pos)
            if (bi_cmp(rank,block)>0) rank=bi_sub(rank,block)
            else { COMP[pos]=x; rem-=x; break }
        }
    }
}

function cp_prepare(G,K,required) { CP_G=G; CP_K=K; CP_REQUIRED=required; delete CP_MEMO }
function cp_count(rem,slots,cumulative,hit,    key,x,maxx,nc,nh,s) {
    if (slots==0) return rem==0 && (CP_REQUIRED<0 || hit)?"1":"0"
    if (rem<slots) return "0"
    key=rem SUBSEP slots SUBSEP cumulative SUBSEP hit; if (key in CP_MEMO) return CP_MEMO[key]
    s="0"; maxx=rem-(slots-1)
    for (x=1;x<=maxx;x++) {
        nc=cumulative+x; nh=hit
        if (CP_REQUIRED>=0 && !hit) {
            if (nc==CP_REQUIRED) nh=1
            else if (nc>CP_REQUIRED) continue
        }
        s=bi_add(s,cp_count(rem-x,slots-1,nc,nh))
    }
    CP_MEMO[key]=s; return s
}
function cp_unrank(G,K,rank,    rem,slots,cum,hit,pos,x,maxx,nc,nh,block) {
    delete CUTLET_PART; rem=G; slots=K; cum=0; hit=0; pos=1
    while (slots>0) {
        maxx=rem-(slots-1)
        for (x=1;x<=maxx;x++) {
            nc=cum+x; nh=hit
            if (CP_REQUIRED>=0 && !hit) {
                if (nc==CP_REQUIRED) nh=1
                else if (nc>CP_REQUIRED) continue
            }
            block=cp_count(rem-x,slots-1,nc,nh)
            if (bi_cmp(rank,block)>0) rank=bi_sub(rank,block)
            else { CUTLET_PART[pos++]=x; rem-=x; slots--; cum=nc; hit=nh; break }
        }
    }
}

function weave_prepare(m,    j) {
    WV_M=m; WV_OPEN=0; WV_CLOSED=0; delete WV_MEMO; delete WV_REMAIN; delete WV_LEN
    for (j=1;j<=m;j++) { WV_LEN[j]=MONTH_LENGTH[j]; WV_REMAIN[j]=MONTH_LENGTH[j] }
}
function weave_key(    j,k) { k=WV_OPEN "|" WV_CLOSED; for (j=1;j<=WV_M;j++) k=k "|" WV_REMAIN[j]; return k }
function weave_legal(j,    opened,willclose) {
    if (WV_REMAIN[j]==0) return 0
    opened=(WV_REMAIN[j] < WV_LEN[j])
    if (!opened && j!=WV_OPEN+1) return 0
    willclose=(WV_REMAIN[j]==1)
    if (willclose && j!=WV_CLOSED+1) return 0
    return 1
}
function weave_count(    key,j,total,oldopen,oldclosed,oldrem,block,allzero) {
    allzero=1; for (j=1;j<=WV_M;j++) if (WV_REMAIN[j]!=0) { allzero=0; break }
    if (allzero) return "1"
    key=weave_key(); if (key in WV_MEMO) return WV_MEMO[key]
    total="0"
    for (j=1;j<=WV_M;j++) if (weave_legal(j)) {
        oldopen=WV_OPEN; oldclosed=WV_CLOSED; oldrem=WV_REMAIN[j]
        if (WV_REMAIN[j]==WV_LEN[j]) WV_OPEN=j
        WV_REMAIN[j]--
        if (WV_REMAIN[j]==0) WV_CLOSED=j
        block=weave_count(); total=bi_add(total,block)
        WV_REMAIN[j]=oldrem; WV_OPEN=oldopen; WV_CLOSED=oldclosed
    }
    WV_MEMO[key]=total; return total
}
function weave_unrank(rank,    totalpos,pos,j,oldopen,oldclosed,oldrem,block,chosen) {
    delete WEAVE; totalpos=0; for (j=1;j<=WV_M;j++) totalpos+=WV_LEN[j]
    for (pos=1;pos<=totalpos;pos++) {
        chosen=0
        for (j=1;j<=WV_M;j++) if (weave_legal(j)) {
            oldopen=WV_OPEN; oldclosed=WV_CLOSED; oldrem=WV_REMAIN[j]
            if (WV_REMAIN[j]==WV_LEN[j]) WV_OPEN=j
            WV_REMAIN[j]--
            if (WV_REMAIN[j]==0) WV_CLOSED=j
            block=weave_count()
            if (bi_cmp(rank,block)>0) {
                rank=bi_sub(rank,block); WV_REMAIN[j]=oldrem; WV_OPEN=oldopen; WV_CLOSED=oldclosed
            } else { WEAVE[pos]=j; chosen=1; break }
        }
        if (!chosen) { ORACLE_ERROR="ingen lovleg vevgrein"; return 0 }
    }
    return 1
}

function positive_gate_gap(n) { sauce(FOUNDATION_DAY,FOUNDATION_DAY+n); ask_bowl(1,SEAL_GATE_GAP); choose_rank("922"); return 41+(CHOSEN_RANK+0) }
function negative_gate_gap(n) { sauce(FOUNDATION_DAY,FOUNDATION_DAY-n); ask_bowl(1,SEAL_GATE_GAP); choose_rank("922"); return 41+(CHOSEN_RANK+0) }

function ensure_gate_index(k,    n) {
    if (k>MAX_GATE_IDX) {
        for (n=MAX_GATE_IDX+1;n<=k;n++) GATE[n]=GATE[n-1]+positive_gate_gap(n)
        MAX_GATE_IDX=k
    }
    if (k<MIN_GATE_IDX) {
        for (n=MIN_GATE_IDX-1;n>=k;n--) GATE[n]=GATE[n+1]-negative_gate_gap(-n)
        MIN_GATE_IDX=k
    }
    return GATE[k]
}
function ensure_gates_cover(low,high) {
    while (GATE[MIN_GATE_IDX]>low) ensure_gate_index(MIN_GATE_IDX-1)
    while (GATE[MAX_GATE_IDX]<high) ensure_gate_index(MAX_GATE_IDX+1)
}
function gate_index_at_or_before(day,    lo,hi,mid) {
    ensure_gates_cover(day,day); lo=MIN_GATE_IDX; hi=MAX_GATE_IDX
    while (lo<hi) { mid=lo+int((hi-lo+1)/2); if (GATE[mid]<=day) lo=mid; else hi=mid-1 }
    return lo
}
function exact_gate_index(day,    i) { i=gate_index_at_or_before(day); return GATE[i]==day?i:999999999 }

function valid_year_pair(i,j,    L) { if (j-i<6) return 0; L=GATE[j]-GATE[i]; return L>=YEAR_MIN_DAYS && L<=YEAR_MAX_DAYS }
function year_set(number,i,j) { Y_NUMBER=number; Y_OPEN_IDX=i; Y_CLOSE_IDX=j; Y_OPEN_DAY=GATE[i]; Y_CLOSE_DAY=GATE[j] }

function sort_year_pairs(n,    i,j,ti,tj,tl) {
    for (i=2;i<=n;i++) {
        ti=YC_I[i]; tj=YC_J[i]; tl=YC_L[i]; j=i-1
        while (j>=1 && (YC_L[j]>tl || (YC_L[j]==tl && GATE[YC_I[j]]>GATE[ti]))) {
            YC_I[j+1]=YC_I[j]; YC_J[j+1]=YC_J[j]; YC_L[j+1]=YC_L[j]; j--
        }
        YC_I[j+1]=ti; YC_J[j+1]=tj; YC_L[j+1]=tl
    }
}
function sort_year_indices(n,isNext,anchor,    i,j,t,lt,lj) {
    for (i=2;i<=n;i++) {
        t=YIDX[i]; lt=isNext?GATE[t]-GATE[anchor]:GATE[anchor]-GATE[t]; j=i-1
        while (j>=1) {
            lj=isNext?GATE[YIDX[j]]-GATE[anchor]:GATE[anchor]-GATE[YIDX[j]]
            if (lj<=lt) break
            YIDX[j+1]=YIDX[j]; j--
        }
        YIDX[j+1]=t
    }
}

function year5000(cday,    i,j,n,L,rank) {
    ensure_gates_cover(cday-YEAR_MAX_DAYS,cday+YEAR_MAX_DAYS)
    delete YC_I; delete YC_J; delete YC_L; n=0
    for (i=MIN_GATE_IDX;i<MAX_GATE_IDX;i++) for (j=i+1;j<=MAX_GATE_IDX;j++) {
        L=GATE[j]-GATE[i]
        if (L>YEAR_MAX_DAYS) break
        if (!valid_year_pair(i,j)) continue
        if (!(GATE[i]<cday && cday<=GATE[j])) continue
        n++; YC_I[n]=i; YC_J[n]=j; YC_L[n]=L
    }
    sort_year_pairs(n); sauce(cday,cday); ask_bowl(1,SEAL_YEAR_5000); choose_rank(n ""); rank=CHOSEN_RANK+0
    year_set(5000,YC_I[rank],YC_J[rank])
}

function next_year(cday,    open,j,n,rank) {
    open=Y_CLOSE_IDX; ensure_gates_cover(GATE[open],GATE[open]+YEAR_MAX_DAYS); delete YIDX; n=0
    for (j=open+1;;j++) {
        ensure_gate_index(j); if (GATE[j]-GATE[open]>YEAR_MAX_DAYS) break
        if (valid_year_pair(open,j)) YIDX[++n]=j
    }
    sort_year_indices(n,1,open); sauce(cday,GATE[open]); ask_bowl(1,SEAL_NEXT_YEAR); choose_rank(n ""); rank=CHOSEN_RANK+0
    year_set(Y_NUMBER+1,open,YIDX[rank])
}
function previous_year(cday,    cl,i,n,rank) {
    cl=Y_OPEN_IDX; ensure_gates_cover(GATE[cl]-YEAR_MAX_DAYS,GATE[cl]); delete YIDX; n=0
    for (i=cl-1;;i--) {
        ensure_gate_index(i); if (GATE[cl]-GATE[i]>YEAR_MAX_DAYS) break
        if (valid_year_pair(i,cl)) YIDX[++n]=i
    }
    sort_year_indices(n,0,cl); sauce(cday,GATE[cl]); ask_bowl(1,SEAL_PREVIOUS_YEAR); choose_rank(n ""); rank=CHOSEN_RANK+0
    year_set(Y_NUMBER-1,YIDX[rank],cl)
}
function find_target_year(cday,tday) {
    year5000(cday)
    while (tday>Y_CLOSE_DAY) next_year(cday)
    while (tday<=Y_OPEN_DAY) previous_year(cday)
}

function build_year_structure(cday,    first,gaps,k,n,rank,G,g,required,L,lo,hi,mc,j,N,count,offset,cum) {
    first=Y_OPEN_DAY+1; sauce(cday,first); sauce_snapshot_to_structure()

    gaps=Y_CLOSE_IDX-Y_OPEN_IDX; delete TMP_CAND; n=0
    for (k=6;k<=17;k++) if (k<=gaps) TMP_CAND[++n]=k
    sauce_restore_structure(); ask_bowl(2,SEAL_CUTLET_COUNT); choose_rank(n ""); CUTLET_COUNT=TMP_CAND[CHOSEN_RANK+0]

    g=exact_gate_index(cday); required=-1
    if (g!=999999999 && Y_OPEN_IDX<g && g<Y_CLOSE_IDX) required=g-Y_OPEN_IDX
    cp_prepare(gaps,CUTLET_COUNT,required); count=cp_count(gaps,CUTLET_COUNT,0,0)
    sauce_restore_structure(); ask_bowl(2,SEAL_CUTLET_PARTITION); choose_rank(count); cp_unrank(gaps,CUTLET_COUNT,CHOSEN_RANK)

    N=falling_factorial(17,CUTLET_COUNT); sauce_restore_structure(); ask_bowl(5,SEAL_CUTLET_NAMES); choose_rank(N); unrank_distinct(17,CUTLET_COUNT,CHOSEN_RANK)
    delete CUTLET_NAME_INDEX; delete CUTLET_FIRST; delete CUTLET_LAST
    cum=Y_OPEN_IDX
    for (k=1;k<=CUTLET_COUNT;k++) {
        CUTLET_NAME_INDEX[k]=NAME_INDEX[k]; CUTLET_FIRST[k]=GATE[cum]+1; cum+=CUTLET_PART[k]; CUTLET_LAST[k]=GATE[cum]
    }

    L=Y_CLOSE_DAY-Y_OPEN_DAY; lo=ceil_div_native(L,123); hi=min_native(47,int(L/4))
    sauce_restore_structure(); ask_bowl(3,SEAL_MONTH_COUNT); choose_rank((hi-lo+1) ""); MONTH_COUNT=lo+(CHOSEN_RANK+0)-1

    bc_prepare(L,MONTH_COUNT,4,123); count=bc_count(L,MONTH_COUNT)
    sauce_restore_structure(); ask_bowl(3,SEAL_MONTH_LENGTHS); choose_rank(count); bc_unrank(L,MONTH_COUNT,CHOSEN_RANK)
    delete MONTH_LENGTH; for (j=1;j<=MONTH_COUNT;j++) MONTH_LENGTH[j]=COMP[j]

    weave_prepare(MONTH_COUNT); count=weave_count()
    sauce_restore_structure(); ask_bowl(4,SEAL_MONTH_WEAVING); choose_rank(count)
    weave_prepare(MONTH_COUNT); if (!weave_unrank(CHOSEN_RANK)) return 0

    N=falling_factorial(47,MONTH_COUNT); sauce_restore_structure(); ask_bowl(5,SEAL_MONTH_NAMES); choose_rank(N); unrank_distinct(47,MONTH_COUNT,CHOSEN_RANK)
    delete MONTH_NAME_INDEX; for (j=1;j<=MONTH_COUNT;j++) MONTH_NAME_INDEX[j]=NAME_INDEX[j]
    return 1
}

function calendar_date_oracle(cday,tday,    k,cutid,offset,monthid,p) {
    ORACLE_ERROR=""; find_target_year(cday,tday)
    if (!build_year_structure(cday)) return 0
    cutid=0
    for (k=1;k<=CUTLET_COUNT;k++) if (CUTLET_FIRST[k]<=tday && tday<=CUTLET_LAST[k]) { cutid=k; break }
    if (!cutid) { ORACLE_ERROR="fann inga kottlet for dagen"; return 0 }
    RESULT_YEAR=Y_NUMBER
    RESULT_CUTLET_INDEX=CUTLET_NAME_INDEX[cutid]
    RESULT_DAY_IN_CUTLET=tday-CUTLET_FIRST[cutid]+1
    offset=tday-(Y_OPEN_DAY+1); monthid=WEAVE[offset+1]
    RESULT_MONTH_INDEX=MONTH_NAME_INDEX[monthid]
    RESULT_DAY_IN_MONTH=0
    for (p=1;p<=offset+1;p++) if (WEAVE[p]==monthid) RESULT_DAY_IN_MONTH++
    RESULT_CUTLET_TEXT=catalog_cutlet(RESULT_CUTLET_INDEX)
    RESULT_MONTH_TEXT=catalog_month(RESULT_MONTH_INDEX)
    return 1
}
