import {readFileSync} from "node:fs";
import {createHash} from "node:crypto";

// A source-only prediction for the exact second-x landing. Unknown incoming stack
// words and memory reads are symbolic. A jump with an unknown vector terminates
// the proof. Self-modification, an empty cell, or an unsupported instruction does too.
function check(ok, message) {
  if (!ok) throw new Error(message);
}

function number(value, sites = []) {
  return { value: BigInt(value), expression: String(value), root: false, sites };
}

function variable(expression, root = false) {
  return { value: null, expression, root, sites: [] };
}

function coordinate(word) {
  check(word.value !== null, "dynamic address or jump vector");
  const n = Number(word.value);
  check(Number.isSafeInteger(n), "coordinate out of exact range");
  return n;
}

function combine(op, a, b) {
  if (a.value === null || b.value === null) {
    return variable("(" + a.expression + op + b.expression + ")", a.root || b.root);
  }
  const x = a.value, y = b.value;
  let value;
  switch (op) {
    case "+": value = x+y; break;
    case "-": value = x-y; break;
    case "*": value = x*y; break;
    case "/": value = y === 0n ? 0n : x/y; break;
    case "%": value = y === 0n ? 0n : x%y; break;
    default: throw new Error("unsupported arithmetic " + op);
  }
  return number(value,a.sites.concat(b.sites));
}

function predict(rows) {
  const stack = [], written = new Set(), reads = [], stores = [], branches = [], users = [];
  let x = 575, y = 670, dx = 35, dy = 475, below = 0, firstLoss = null, atBoundary = null;
  let divisorSites = null;
  const pop = () => stack.pop() || variable("entry" + (++below));
  for (let step = 1; step <= 1536; ++step) {
    const pos = [x,y], key = pos.join(","), op = rows[y]?.[x] ?? " ";
    check(!written.has(key) && op !== " ", "modified or empty instruction at " + key);
    function observe(args) {
      if (step > 1024 && args.some(w => w.root)) {
        users.push({step,pos,op,operands:args.map(w => w.expression)});
        if (users.length === 1 && op === "%") divisorSites = args[1].sites;
      }
    }
    if ("0123456789abcdef".includes(op)) {
      stack.push(number(parseInt(op,16),[pos]));
    } else if ("+-*/%".includes(op)) {
      const b = pop(), a = pop();
      observe([a,b]);
      stack.push(combine(op,a,b));
    } else if (op === "g" || op === "p") {
      const ay = pop(), ax = pop(), address = [coordinate(ax),coordinate(ay)];
      if (op === "g") {
        observe([ax,ay]);
        reads.push({step,pos,address});
        const root = x === 174 && y === 195 && address[0] === 43 && address[1] === 1702;
        stack.push(variable(root ? "R" : "G"+step,root));
      } else {
        const value = pop();
        observe([value,ax,ay]);
        written.add(address.join(","));
        stores.push({step,pos,address,value:value.expression});
      }
    } else if (op === "x") {
      const by = pop(), bx = pop();
      observe([bx,by]);
      dx = coordinate(bx); dy = coordinate(by);
      branches.push({step,pos,vector:[dx,dy]});
    } else if ("^v<>".includes(op)) {
      [dx,dy] = {"^":[0,-1],v:[0,1],"<":[-1,0],">":[1,0]}[op];
    } else {
      throw new Error("unmodeled source instruction " + op + " at " + key);
    }
    if (step === 1024) atBoundary = stack.filter(w => w.root).map(w => w.expression);
    if (step > 1024 && firstLoss === null && !stack.some(w => w.root)) firstLoss = step;
    x += dx; y += dy;
  }
  return {reads,stores,branches,users,divisorSites,firstLoss,atBoundary,
          end:stack.filter(w => w.root).map(w => w.expression)};
}

function auditSource(rows) {
  const baseline = predict(rows);
  const extended = a => a.filter(q => q.step > 1024);
  const m = (2n**127n - 1n).toString(10);
  const addr = (v,x,y) => !!v && v[0] === x && v[1] === y;
  const historical = baseline.reads.filter(e => addr(e.address,43,1702));
  check(historical.length === 2 && historical[0].step === 667 && historical[1].step === 901
    && baseline.branches.filter(e => e.step <= 1024).length === 26, "QA31BG anchor");
  check(baseline.atBoundary.length === 1 && baseline.atBoundary[0] === "(G882+R)"
    && baseline.reads.some(e => e.step === 882 && addr(e.address,61,1706)), "boundary source expression");
  const [rem,put] = baseline.users;
  check(baseline.users.length === 2 && rem.op === "%" && rem.step === 1270
    && addr(rem.pos,860,205) && rem.operands[1] === m, "first consumer or modulus");
  check(put.step === 1309 && put.op === "p" && addr(put.pos,1440,575)
    && put.operands[0] === "((G882+R)%"+m+")" && put.operands[1] === "61"
    && put.operands[2] === "1706" && baseline.firstLoss === 1309
    && baseline.end.length === 0, "write or final stack");
  check(extended(baseline.branches).length === 13 && extended(baseline.stores).length === 1
    && extended(baseline.reads).length === 2, "source control and memory counts");
  const sites = [...new Map(baseline.divisorSites.map(p => [p.join(","),p])).values()]
    .filter(([x,y]) => /^[0-9]$/.test(rows[y][x]));
  check(sites.length >= 12, "insufficient divisor-literal mutation sites");
  const controls = [];
  for (let i = 0; i < 12; ++i) {
    const [x,y] = sites[Math.floor(i*(sites.length-1)/11)];
    const old = rows[y][x], replacement = old === "9" ? "8" : String(Number(old)+1);
    const altered = rows.slice();
    altered[y] = rows[y].slice(0,x) + replacement + rows[y].slice(x+1);
    const result = predict(altered);
    const [other,otherPut] = result.users;
    check(other.step === rem.step && other.op === "%" && other.operands[1] !== m
      && otherPut.step === put.step && addr(otherPut.pos,1440,575)
      && otherPut.operands[1] === "61" && otherPut.operands[2] === "1706",
      "unchanged mutated divisor or unexpected route");
    controls.push({pos:[x,y],old,replacement,altered_divisor:other.operands[1]});
  }
  return {scope:"conditional unchanged source, symbolic memory, no new Native or physical cohort replay",
    source_root_read_step:901,other_read_step:882,boundary:baseline.atBoundary,first_use:rem,write:put,
    extinction:baseline.firstLoss,extension_x:13,read_after_write:extended(baseline.reads),controls};
}

const bytes = readFileSync(process.argv[2] ?? "src/interleaved_work_counts.b98");
const actual = createHash("sha1").update("blob " + bytes.length + "\0").update(bytes).digest("hex");
check(actual === "560d6aa5807a7f766213a33835cce85eab0fa40c", "original source blob mismatch");
console.log(JSON.stringify({source_blob:actual,...auditSource(bytes.toString("ascii").split("\n"))},null,2));
