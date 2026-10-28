const path=require('node:path'),fs=require('node:fs'),assert=require('node:assert/strict');
const {chromium}=require(path.join(__dirname,'../.local/browser-runner/node_modules/playwright'));
const {post}=require('./PortalIntegration.cjs');
const base='http://localhost:5173/TeacherTraining/';
async function codeFromOutbox(page,context){
 const href=await page.getByRole('link',{name:'Open local email outbox',exact:true}).getAttribute('href');
 const response=await context.request.get(href);assert.equal(response.status(),200);
 return /OTP: (\d{6})/.exec(await response.text())[1];
}
async function signIn(page,context,user,password){
 await page.goto(base+'login');await page.locator('#login-identity').fill(user);await page.locator('#login-password').fill(password);
 await page.getByRole('button',{name:'Sign in',exact:true}).click();await page.locator('#login-otp').waitFor();
 await page.locator('#login-otp').fill(await codeFromOutbox(page,context));
 await page.getByRole('button',{name:'Verify and sign in',exact:true}).click();await page.waitForURL(base);
}
async function main(){
 const browser=await chromium.launch({channel:'chrome',headless:true});const errors=[];let checks=0;
 const context=await browser.newContext({viewport:{width:1600,height:1000}});const page=await context.newPage();
 page.setDefaultTimeout(15000);page.on('pageerror',e=>errors.push(e.message));page.on('dialog',async d=>{errors.push(d.message());await d.accept();});
 try{
  await signIn(page,context,'Demo2','demo1@123');checks++;
  await page.getByRole('link',{name:'Training Plans',exact:true}).click();await page.waitForURL(base+'training-plans');checks++;
  const name='Sample workshop '+Date.now();
  await page.getByLabel('Training plan name').fill(name);await page.getByLabel('Number of training days').fill('4');
  await page.getByRole('button',{name:'Create training plan',exact:true}).click();
  await page.getByText(name,{exact:true}).waitFor();await page.reload();await page.getByText(name,{exact:true}).waitFor();checks++;
  const token=await page.evaluate(()=>sessionStorage.getItem('teacher-training-api-token'));
  const snapshot=await post('Workspace/GetData',{},token);
  assert(snapshot['teacher-training-plans'].some(p=>p.name===name && p.days===4));checks++;
  await page.getByRole('link',{name:'Projects',exact:true}).click();await page.waitForURL(base+'projects');checks++;
  const publicContext=await browser.newContext({viewport:{width:1400,height:1000}});const registration=await publicContext.newPage();
  registration.on('pageerror',e=>errors.push(e.message));registration.setDefaultTimeout(15000);
  await registration.goto(base+'register?batch=BATCH-DEMO-NOV');
  const personName='Sample registered teacher '+Date.now(),email='browser-'+Date.now()+'@example.test';
  await registration.getByLabel('Full name').fill(personName);await registration.getByLabel('Email address',{exact:true}).fill(email);
  await registration.getByRole('checkbox',{name:'I consent to using my contact details for training registration and verification.'}).check();
  await registration.getByRole('button',{name:'Request verification code',exact:true}).click();await registration.getByLabel('Verification code').waitFor();checks++;
  await registration.getByLabel('Verification code').fill(await codeFromOutbox(registration,publicContext));
  await registration.getByRole('button',{name:'Verify and submit registration',exact:true}).click();
  const details=registration.getByRole('link',{name:'View initial login details in local email outbox'});await details.waitFor();checks++;
  const mail=await (await publicContext.request.get(await details.getAttribute('href'))).text();
  const user=/Trainee ID: (.+)/.exec(mail)[1].trim(),password=/Initial password: (.+)/.exec(mail)[1].trim();
  await registration.screenshot({path:path.join(__dirname,'../.local/screenshots/open-registration-success.png'),fullPage:true});
  await signIn(registration,publicContext,user,password);checks++;
  await registration.getByText('BATCH-DEMO-NOV',{exact:true}).first().waitFor();
  await registration.reload();await registration.getByText('BATCH-DEMO-NOV',{exact:true}).first().waitFor();checks++;
  await registration.screenshot({path:path.join(__dirname,'../.local/screenshots/registered-trainee-dashboard.png'),fullPage:true});
  const after=await post('Workspace/GetData',{},token);
  assert(after['teacher-training-trainees'].some(t=>t.name===personName && t.email===email));checks++;
  await registration.goto(base+'login');await registration.locator('#login-identity').fill(email);
  await registration.getByRole('button',{name:'Forgot password?',exact:true}).click();
  await registration.getByRole('button',{name:'Send reset code',exact:true}).click();await registration.locator('#login-otp').waitFor();
  await registration.locator('#new-password').fill('LocalBrowserVerification!123');
  await registration.locator('#login-otp').fill(await codeFromOutbox(registration,publicContext));
  await registration.getByRole('button',{name:'Verify and reset password',exact:true}).click();
  await registration.getByRole('button',{name:'Sign in',exact:true}).waitFor();checks++;
  await signIn(registration,publicContext,user,'LocalBrowserVerification!123');checks++;
  assert.equal(errors.length,0,errors.join('\n'));checks++;
  const result={passed:true,checks,samplePlan:name,sampleTraineeId:user,time:new Date().toISOString()};
  fs.writeFileSync(path.join(__dirname,'../.local/flow-test-result.json'),JSON.stringify(result,null,2));
  console.log(`PASS: ${checks} Chrome login, navigation, plan save/reload, OTP registration and new trainee login checks.`);
  await publicContext.close();
 }catch(error){await page.screenshot({path:path.join(__dirname,'../.local/screenshots/flow-failure.png'),fullPage:true}).catch(()=>{});throw error;}
 finally{await browser.close();}
}
main().catch(error=>{console.error(error.stack);process.exitCode=1;});
