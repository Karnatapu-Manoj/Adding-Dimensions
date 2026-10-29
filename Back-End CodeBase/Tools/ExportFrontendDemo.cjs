const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '../../Front-End CodeBase');
const ts = require(path.join(root, 'node_modules/typescript'));
const cache = new Map();
const storage = new Map();
const localStorage = { getItem: key => storage.get(key) ?? null, setItem: (key,value) => storage.set(key,value), removeItem: key => storage.delete(key) };
const roles=['sponsor-admin','schoolnet-super-admin','schoolnet-project-admin','state-admin','school-admin','trainer','trainee','reporting-audit-user'];
const additionalUsers=[
  {userId:'Demo9',role:'school-admin',fullName:'Aarav Sharma',active:true},
  {userId:'Demo10',role:'school-admin',fullName:'Meera Iyer',active:true},
  {userId:'Demo11',role:'trainer',fullName:'Rohan Kulkarni',active:true},
  {userId:'Demo12',role:'trainer',fullName:'Kavya Nair',active:true},
  {userId:'Demo13',role:'trainee',fullName:'Arjun Reddy',active:true}
];
storage.set('teacher-training-users',JSON.stringify([...roles.map((role,index)=>({userId:'Demo'+(index+1),role,active:true})),...additionalUsers]));
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
const schools=load(path.join(root,'src/data/kgbvSchools.ts')).kgbvSchools;
const school=schools.find(item=>item.state==='Andhra Pradesh') ?? schools[0];
const trainers=JSON.parse(storage.get('teacher-training-trainer-profiles') ?? '[]');
for(const trainer of [
  {id:'DEMO-SAMPLE-TRAINER-011',trainerCode:'TR-DEMO-011',userId:'Demo11',name:'Rohan Kulkarni',category:'Employee',email:'rohan.kulkarni@example.org',phone:'+91 90000 10011',languages:['English','Marathi'],competencies:['Digital pedagogy','Classroom technology'],certifications:'Certified Teacher Trainer',experienceYears:7,state:school.state,district:school.district,serviceArea:school.school,active:true},
  {id:'DEMO-SAMPLE-TRAINER-012',trainerCode:'TR-DEMO-012',userId:'Demo12',name:'Kavya Nair',category:'Consultant',email:'kavya.nair@example.org',phone:'+91 90000 10012',languages:['English','Malayalam'],competencies:['Teacher mentoring','Digital learning'],certifications:'Certified Teacher Trainer',experienceYears:6,state:school.state,district:school.district,serviceArea:school.school,active:true}
])if(!trainers.some(item=>item.userId===trainer.userId))trainers.push(trainer);
storage.set('teacher-training-trainer-profiles',JSON.stringify(trainers));
const trainees=JSON.parse(storage.get('teacher-training-trainees') ?? '[]');
if(!trainees.some(item=>item.userId==='Demo13'))trainees.push({id:'DEMO-SAMPLE-TRAINEE-013',traineeId:'DEMO-SAMPLE-TRAINEE-013',userId:'Demo13',name:'Arjun Reddy',email:'arjun.reddy@example.org',phone:'+91 90000 10013',category:'Teacher',schoolUdise:school.udise,schoolName:school.school,projectId:'DEMO-SAMPLE-PROJECT-001',state:school.state,district:school.district,consentProvided:true,createdAt:'2026-10-28T09:00:00.000Z',createdBy:'Demo2'});
storage.set('teacher-training-trainees',JSON.stringify(trainees));
const assignments=JSON.parse(storage.get('teacher-training-school-assignments') ?? '[]');
for(const userId of ['Demo9','Demo10'])if(!assignments.some(item=>item.userId===userId&&item.schoolUdise===school.udise))assignments.push({id:`DEMO-SAMPLE-SCHOOL-ASSIGNMENT-${userId}`,userId,schoolUdise:school.udise,projectId:'DEMO-SAMPLE-PROJECT-001'});
storage.set('teacher-training-school-assignments',JSON.stringify(assignments));
const data=Object.fromEntries([...storage].map(([key,value])=>[key,JSON.parse(value)]));
data['teacher-training-schools']=schools;
const output=process.argv[2] || path.join(__dirname,'../.local/frontend-demo.json');
fs.mkdirSync(path.dirname(path.resolve(output)),{recursive:true});
fs.writeFileSync(output,JSON.stringify(data,null,2));
console.log(`Exported ${Object.keys(data).length} existing frontend demo datasets for one-time database seeding.`);
