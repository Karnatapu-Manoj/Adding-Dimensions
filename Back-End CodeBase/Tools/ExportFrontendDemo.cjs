const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '../../Front-End CodeBase');
const ts = require(path.join(root, 'node_modules/typescript'));
const cache = new Map();
const storage = new Map();
const localStorage = { getItem: key => storage.get(key) ?? null, setItem: (key,value) => storage.set(key,value), removeItem: key => storage.delete(key) };
const roles=['sponsor-admin','schoolnet-super-admin','schoolnet-project-admin','state-admin','school-admin','trainer','trainee','reporting-audit-user'];
storage.set('teacher-training-users',JSON.stringify(roles.map((role,index)=>({userId:'Demo'+(index+1),role,active:true}))));
let identity=0;
function load(filename) {
  filename = path.resolve(filename);
  if(path.basename(filename)==='dataStore.ts')return {dataStore:localStorage};
  if(path.basename(filename)==='auth.ts')return {getUsers:()=>JSON.parse(storage.get('teacher-training-users'))};
  if (cache.has(filename)) return cache.get(filename).exports;
  const module = { exports: {} }; cache.set(filename,module);
  const source = ts.transpileModule(fs.readFileSync(filename,'utf8').replaceAll('import.meta.env','({})'), { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 } }).outputText;
  const context = { module, exports: module.exports, localStorage, window: { localStorage }, crypto: {randomUUID:()=>`00000000-0000-4000-8000-${String(++identity).padStart(12,'0')}`}, console, Date, URL,
    require: name => name.startsWith('.') ? load(path.resolve(path.dirname(filename),name+'.ts')) : require(name) };
  vm.runInNewContext(source,context,{filename});
  return module.exports;
}
load(path.join(root,'src/demoSampleData.ts')).seedDemoSampleData();
const data=Object.fromEntries([...storage].map(([key,value])=>[key,JSON.parse(value)]));
data['teacher-training-schools']=load(path.join(root,'src/data/kgbvSchools.ts')).kgbvSchools;
const output=process.argv[2] || path.join(__dirname,'../.local/frontend-demo.json');
fs.mkdirSync(path.dirname(path.resolve(output)),{recursive:true});
fs.writeFileSync(output,JSON.stringify(data,null,2));
console.log(`Exported ${Object.keys(data).length} existing frontend demo datasets for one-time database seeding.`);
