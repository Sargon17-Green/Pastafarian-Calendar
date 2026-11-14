#!/usr/bin/env node
'use strict';
/**
 * Make an EXPLICIT DERIVATIVE of the pinned JavaScript reference.
 * Only the memory-heavy month weaving family is replaced, and only in a
 * distinct output directory. The original reference is never altered.
 * A derivative is NOT an independent engine in the soak inventory.
 */
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const [originalFile,catalogFile,optimizedFile,outDir]=process.argv.slice(2);
if(!originalFile||!catalogFile||!optimizedFile||!outDir) throw Error('required arguments: original.js catalog.js optimized.cjs output-dir');
function sha(b){return crypto.createHash('sha256').update(b).digest('hex');}
const expectedOriginal='8276e428c3a392ab39429331cdfdd7b80a8b1041efb4c9d806a6c141630a9fa5';
const expectedCatalog='211333bff832e597e5388a789c811ae8fffb55780484f28b60b097410c786699';
const original=fs.readFileSync(originalFile);
const catalog=fs.readFileSync(catalogFile);
if(sha(original)!==expectedOriginal||sha(catalog)!==expectedCatalog)
 throw Error('pinned original/canonical catalog source does not match lock');
const text=original.toString('utf8');
const begin='function makeMonthWeavingFamily(lengths) {';
const finish='\nfunction chooseMonthWeaving(';
const s=text.indexOf(begin),e=text.indexOf(finish,s);
if(s<0||e<=s||text.indexOf(begin,s+begin.length)!==-1||text.indexOf(finish,e+finish.length)!==-1)
 throw Error('original month weaving replacement anchors not unique');
if(!text.slice(s,e).includes('const memo = new Map();') ||
   !text.slice(s,e).includes('function countAll()'))
 throw Error('frozen original month weaving body was not recognized');
const replacement=[
'function makeMonthWeavingFamily(lengths) {',
"  // DERIVED from Python/Türkçe. Not original nor independent.",
"  return require('./optimized_month_weaving_v022.cjs').makeFastMonthWeavingFamily(lengths);",
'}',
''].join('\n');
const target=path.resolve(outDir);
if(fs.existsSync(target))throw Error('refusing to overwrite existing derivative directory');
fs.mkdirSync(path.join(target,'tests'),{recursive:true});
fs.mkdirSync(path.join(target,'src'),{recursive:true});
const derived=text.slice(0,s)+replacement+text.slice(e);
const output=path.join(target,'tests','normative-reference.js');
fs.writeFileSync(output,derived,{flag:'wx'});
fs.copyFileSync(catalogFile,path.join(target,'src','source-language-catalog.js'),fs.constants.COPYFILE_EXCL);
fs.copyFileSync(optimizedFile,path.join(target,'tests','optimized_month_weaving_v022.cjs'),fs.constants.COPYFILE_EXCL);
const provenance={
 schema:'PASTAFARI_DERIVED_JS_REFERENCE/1',
 status:'EXPERIMENT_ONLY_NOT_ORIGINAL_NOT_INDEPENDENT',
 original_commit:'03ac0c7f4db3c35487993dd31982faa37dd3948e',
 original_sha256:expectedOriginal,
 source_language_catalog_sha256:expectedCatalog,
 replaced_function:'makeMonthWeavingFamily',
 replaced_original_body_sha256:sha(Buffer.from(text.slice(s,e),'utf8')),
 derivative_sha256:sha(Buffer.from(derived,'utf8')),
 optimized_module_sha256:sha(fs.readFileSync(optimizedFile)),
 source_comparisons_certified:0,
 source_independence_certified:false,
 allow_main_update:false
};
fs.writeFileSync(path.join(target,'PROVENANCE.json'),JSON.stringify(provenance,null,2)+'\n',{flag:'wx'});
console.log('DERIVED_MONTH_WEAVING_PROVENANCE='+JSON.stringify(provenance));
