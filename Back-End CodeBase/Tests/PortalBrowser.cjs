const path=require('node:path'),fs=require('node:fs'),assert=require('node:assert/strict');
const {chromium}=require(path.join(__dirname,'../.local/browser-runner/node_modules/playwright'));
const base='http://localhost:5173/TeacherTraining/';
const roles={1:'Sponsor Admin',2:'Schoolnet Super Admin',3:'Schoolnet Project Admin',4:'State Admin',5:'School Admin',6:'Trainer',7:'Trainee',8:'Reporting/Audit User'};
const routes={1:['','projects','certificates','reports/batch-performance','reports/training-summary','reports/attendance-report'],
 2:['','projects','training-plans','batches','attendance','trainers','registration-requests','content-library','assessments','certificates','holiday-master','reports/assessment-feedback'],
 3:['','projects','training-plans','batches','trainers'],4:['','projects','batches','reports/batch-performance'],
 5:['','projects','batches','content-library'],6:['','batches','attendance','trainers','registration-requests'],
 7:['','projects','training-plans','assessments','content-library'],8:['','projects','reports/attendance-report']};
async function main(){
 const browser=await chromium.launch({channel:'chrome',headless:true});let screens=0,networkCalls=0;const problems=[];
 fs.mkdirSync(path.join(__dirname,'../.local/screenshots'),{recursive:true});
 try{
  for(let n=1;n<=8;n++){
   const context=await browser.newContext({viewport:{width:1920,height:1080}});const page=await context.newPage();
   page.on('pageerror',error=>problems.push(`Demo${n}: ${error.message}`));
   page.on('dialog',async dialog=>{problems.push(`Demo${n}: ${dialog.message()}`);await dialog.accept();});
   page.on('response',response=>{if(response.url().startsWith('http://localhost:5100/api/')){networkCalls++;if(response.status()>=400)problems.push(`Demo${n}: HTTP ${response.status()} ${response.url()}`);}});
   await page.goto(base+'login');await page.getByLabel('Email address or mobile number').fill('Demo'+n);
   await page.locator('#login-password').fill('demo1@123');await page.getByRole('button',{name:'Sign in',exact:true}).click();
   await page.getByLabel('Verification code').waitFor();
   const outbox=await page.getByRole('link',{name:'Open local email outbox'}).getAttribute('href');
   const mail=await (await context.request.get(outbox)).text();
   await page.getByLabel('Verification code').fill(/OTP: (\d{6})/.exec(mail)[1]);
   await page.getByRole('button',{name:'Verify and sign in',exact:true}).click();
   await page.waitForURL(base,{timeout:30000});await page.waitForTimeout(400);assert((await page.title()).includes(roles[n]));
   for(const route of routes[n]){
    await page.goto(base+route);await page.waitForLoadState('networkidle');
    assert(!await page.getByRole('button',{name:'Sign in',exact:true}).isVisible(),`Demo${n} lost authentication on ${route}`);
    assert((await page.locator('body').innerText()).length>150);screens++;
    if(!route)await page.screenshot({path:path.join(__dirname,`../.local/screenshots/Demo${n}-dashboard.png`),fullPage:true});
   }
   await context.close();console.log(`Verified Demo${n}: ${routes[n].length} screens in Google Chrome.`);
  }
  assert.equal(problems.length,0,problems.join('\n'));assert(networkCalls>screens);
  console.log(`PASS: ${screens} screens, ${networkCalls} real API responses, all eight demo roles in Google Chrome.`);
  fs.writeFileSync(path.join(__dirname,'../.local/browser-test-result.json'),JSON.stringify({passed:true,screens,networkCalls,problems,time:new Date().toISOString()},null,2));
 }finally{await browser.close();}
}
main().catch(error=>{console.error(error.stack);process.exitCode=1;});
