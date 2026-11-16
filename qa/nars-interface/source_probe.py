#!/usr/bin/env python3
"""Read-only NARS2000 source inventory and interface discovery: NOT Native/CLI proof."""
import argparse, hashlib, json, pathlib, re, sys
PATTERNS={
"startup_command_line": r"\b(?:GetCommandLine[AW]?|CommandLineToArgvW|lpCmdLine|argc|argv|ParseCommandLine)\b",
"stdin_console": r"\b(?:GetStdHandle|STD_INPUT_HANDLE|ReadConsole[AW]?|ReadFile|fgets|scanf|stdin|AllocConsole|AttachConsole)\b",
"windows_ipc": r"\b(?:WM_COPYDATA|WM_DDE_EXECUTE|DdeInitialize[AW]?|DdeConnect|CreateNamedPipe[AW]?|CreatePipe|WM_APP|RegisterWindowMessage[AW]?)\b",
"com_automation": r"\b(?:IDispatch|CoCreateInstance|CoRegisterClassObject|DllGetClassObject|DISPATCH_METHOD|CLSID|GetIDsOfNames)\b",
"workspace_auto": r"\b(?:QuadLX|LoadWorkspace|LoadWS|NARS2000\.ini|ws\.nars|Startup|StartUp)\b",
}
def probe(root, max_files=3500, max_bytes=40_000_000):
    files=sorted(p for p in root.rglob('*') if p.is_file() and p.suffix.lower() in ('.c','.h','.cpp','.rc','.y'))
    if not files: raise ValueError('SOURCE_UNAVAILABLE: no C-family files')
    if len(files)>max_files: raise ValueError('SOURCE_TOO_MANY_FILES')
    total=sum(p.stat().st_size for p in files)
    if total>max_bytes: raise ValueError('SOURCE_TOO_LARGE')
    patterns={k:re.compile(v) for k,v in PATTERNS.items()}
    hits={k:[] for k in PATTERNS}; inventory=[]
    for p in files:
        raw=p.read_bytes(); rel=p.relative_to(root).as_posix()
        inventory.append({'path':rel,'bytes':len(raw),'sha256':hashlib.sha256(raw).hexdigest()})
        for n,line in enumerate(raw.decode('latin-1').splitlines(),1):
            for key,regex in patterns.items():
                for match in regex.finditer(line):
                    hits[key].append({'file':rel,'line':n,'token':match.group(),'context':line.strip()[:240]})
    return {'schema':'NARS2000_SOURCE_INTERFACE_DISCOVERY_V1',
            'project_id':'PC-BRANCH-APL-GERMAN','source_files':len(files),
            'source_bytes':total,'inventory':inventory,'matches':hits,
            'interpretation':'CANDIDATES_ONLY_NO_CLI_OR_NATIVE_PROOF',
            'cli_supported':'UNDETERMINED','native_executed':False}
def main():
    ap=argparse.ArgumentParser();ap.add_argument('source',type=pathlib.Path)
    ap.add_argument('--out',type=pathlib.Path,default=pathlib.Path('source_interface_scan.json'))
    ns=ap.parse_args()
    try: out=probe(ns.source.resolve())
    except (OSError,ValueError) as exc:
        out={'schema':'NARS2000_SOURCE_INTERFACE_DISCOVERY_V1','status':'SOURCE_UNAVAILABLE',
             'error':str(exc),'cli_supported':'UNDETERMINED','native_executed':False}
        ns.out.parent.mkdir(parents=True,exist_ok=True)
        ns.out.write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8')
        print(out['error'],file=sys.stderr);return 2
    ns.out.parent.mkdir(parents=True,exist_ok=True)
    ns.out.write_text(json.dumps(out,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print('SOURCE_FILES=',out['source_files'])
    print('CANDIDATE_HITS=',{k:len(v) for k,v in out['matches'].items()})
    print('CLI_SUPPORTED=UNDETERMINED; NATIVE=NOT_RUN')
    return 0
if __name__=='__main__':sys.exit(main())
