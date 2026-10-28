const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'../../Front-End CodeBase');
if(fs.readFileSync(path.join(root,'src/Login.tsx'),'utf8').includes('verifySignIn')){
  console.log('The frontend migration is already applied. No files changed.');
  return;
}
const ts=require(path.join(root,'node_modules/typescript'));

// Keep all layouts, JSX, CSS, assets and folders intact. Only data access and
// asynchronous save handlers are changed. Text edits preserve the original JSX.
for(const filename of fs.readdirSync(path.join(root,'src'),{recursive:true}).filter(name=>/\.tsx?$/.test(name))) {
  const file=path.join(root,'src',filename);
  if(['api.ts','dataStore.ts','auth.ts','main.tsx','demoSampleData.ts'].includes(filename))continue;
  let source=fs.readFileSync(file,'utf8');
  if(!source.includes('localStorage') || filename.includes('DashboardParts'))continue;
  source=source.replaceAll('localStorage.','dataStore.');
  const rel=path.relative(path.dirname(file),path.join(root,'src/dataStore')).replaceAll('\\','/');
  source=`import { dataStore } from '${rel.startsWith('.')?rel:'./'+rel}';\n`+source;
  if(filename==='HolidayMaster.tsx')source=source.replace('dataStore.setItem(key, JSON.stringify(fallback)); return fallback;','return fallback;');
  const ast=ts.createSourceFile(filename,source,ts.ScriptTarget.Latest,true,filename.endsWith('tsx')?ts.ScriptKind.TSX:ts.ScriptKind.TS);
  const parents=new Map(),functions=[],calls=[];
  function walk(node,parent){if(parent)parents.set(node,parent);if(ts.isFunctionDeclaration(node)||ts.isArrowFunction(node)||ts.isFunctionExpression(node))functions.push(node);if(ts.isCallExpression(node))calls.push(node);ts.forEachChild(node,child=>walk(child,node));}
  walk(ast);
  const nameOf=fn=>fn.name?.text??(ts.isVariableDeclaration(parents.get(fn))?parents.get(fn).name.getText(ast):'');
  const outer=call=>{let node=parents.get(call);while(node&&!functions.includes(node))node=parents.get(node);return node;};
  const asyncFunctions=new Set(),awaitCalls=new Set();
  for(const call of calls){const expression=call.expression.getText(ast);if(expression==='dataStore.setItem'||expression==='saveUsers'){
    const fn=outer(call);if(fn&&nameOf(fn)!=='trainerProfiles'){asyncFunctions.add(fn);awaitCalls.add(call);}
  }}
  let changed=true;
  while(changed){changed=false;const names=new Set([...asyncFunctions].map(nameOf).filter(Boolean));
    for(const call of calls){if(!ts.isIdentifier(call.expression)||!names.has(call.expression.text)||awaitCalls.has(call))continue;
      const fn=outer(call);if(fn&&nameOf(fn)!=='trainerProfiles'){awaitCalls.add(call);if(!asyncFunctions.has(fn)){asyncFunctions.add(fn);changed=true;}}
    }
  }
  const edits=[];
  for(const fn of asyncFunctions){if(fn.modifiers?.some(m=>m.kind===ts.SyntaxKind.AsyncKeyword))continue;
    if(ts.isFunctionDeclaration(fn)||ts.isFunctionExpression(fn)){const start=source.indexOf('function',fn.getStart(ast));edits.push([start,'async ']);}
    else edits.push([fn.getStart(ast),'async ']);
  }
  for(const call of awaitCalls){if(ts.isAwaitExpression(parents.get(call)))continue;edits.push([call.getStart(ast),'await ']);}
  for(const [offset,text] of edits.sort((a,b)=>b[0]-a[0]))source=source.slice(0,offset)+text+source.slice(offset);
  fs.writeFileSync(file,source);
  console.log(`Connected ${filename}; ${asyncFunctions.size} save handlers await database persistence.`);
}
