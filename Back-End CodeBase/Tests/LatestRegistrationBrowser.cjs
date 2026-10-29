const path=require('node:path'),fs=require('node:fs'),assert=require('node:assert/strict');
const {chromium}=require('../.local/browser-runner/node_modules/playwright');
const {post,loginWithOtp}=require('./PortalIntegration.cjs');
async function main(){
 const publicData=await post('UserAPI/Public/GetData');
 const school=publicData['teacher-training-schools'].find(s=>s.state==='Andhra Pradesh'&&s.block);
 const batch=publicData['teacher-training-batch-plan-uses'].find(b=>b.openRegistration&&b.legacyBatchCodes?.includes('BATCH-DEMO-NOV'));
 assert(school&&batch,'Expected the open sample batch and school master.');
 assert.match(batch.batchCode,/^TTB-\d{4}-[A-F0-9]{20}$/);
 const unique=Date.now(),name='Integration Teacher '+unique;
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const context=await browser.newContext();const page=await context.newPage();const errors=[];
 page.setDefaultTimeout(15000);page.on('pageerror',e=>errors.push(e.message));
 try{
  await page.goto('http://localhost:5173/TeacherTraining/register?batch='+batch.batchCode);
  async function select(label,value,multiple=false){await page.getByRole('combobox',{name:label,exact:true}).click();await page.getByRole('option',{name:value,exact:true}).click();if(multiple)await page.keyboard.press('Escape');}
  await select('State',school.state);await select('District',school.district);await select('Block',school.block);
  const autocomplete=page.getByRole('combobox',{name:'Search school with UDISE / KGBV / School Name'});
  await autocomplete.fill(school.udise);await page.getByRole('option').filter({hasText:school.udise}).first().click();
  await page.locator('input[name="name"]').fill(name);
  await page.locator('input[name="phone"]').fill('9'+String(unique).slice(-9));
  await page.locator('input[name="email"]').fill('teacher-'+unique+'@example.test');
  await select('Gender','Female');await select('Designation Role','Teacher');
  await select('Class Taught','Class 6',true);await select('Subject(s) Taught','Science',true);
  await select('Total Teaching Experience','6-10 Years');
  await page.getByRole('button',{name:'Request OTP',exact:true}).click();
  const link=page.getByRole('link',{name:'Open local email outbox',exact:true});await link.waitFor();
  const mail=await(await context.request.get(await link.getAttribute('href'))).text();
  await page.getByLabel('Verification code',{exact:true}).fill(/OTP: (\d{6})/.exec(mail)[1]);
  await page.getByRole('button',{name:'Verify OTP',exact:true}).click();
  await page.getByRole('checkbox',{name:'I accept and confirm that the details provided are correct.'}).check();
  await page.getByRole('button',{name:'Accept & Submit Registration',exact:true}).click();
  await page.getByText(/Your Trainee ID is TR-/).waitFor();
  const admin=await loginWithOtp('Demo2');
  const snapshot=await post('UserAPI/Workspace/GetData',{},admin.jwtToken);
  const trainee=snapshot['teacher-training-trainees'].find(t=>t.name===name);assert(trainee);
  assert.equal(trainee.schoolUdise,school.udise);assert.equal(trainee.gender,'Female');
  assert.deepEqual(trainee.classesTaught,['Class 6']);assert.deepEqual(trainee.subjectsTaught,['Science']);
  assert.equal(trainee.teachingExperience,'6-10 Years');
  const registration=snapshot['teacher-training-registrations'].find(t=>t.traineeId===trainee.traineeId&&t.batchId===batch.id);
  assert.equal(registration.status,'Pending');
  const payload={batchCode:batch.batchCode,name:'Bound profile '+unique,email:'bound-'+unique+'@example.test',phone:'8'+String(unique).slice(-9),profileVersion:2,
   category:'Teacher',schoolUdise:school.udise,state:school.state,district:school.district,block:school.block,gender:'Female',designation:'Teacher',
   classesTaught:['Class 6'],subjectsTaught:['Science'],teachingExperience:'6-10 Years'};
  await post('UserAPI/Public/RequestRegistration',{...payload,schoolUdise:'INVALID-SCHOOL'},undefined,400);
  const challenge=await post('UserAPI/Public/RequestRegistration',payload);
  const code=/OTP: (\d{6})/.exec(fs.readFileSync(path.join(__dirname,'../.local/mail-outbox',challenge.challengeId+'.eml'),'utf8'))[1];
  await post('UserAPI/Public/VerifyRegistration',{challengeId:challenge.challengeId,otp:code==='000000'?'000001':'000000'},undefined,400);
  for(let n=0;n<2;n++)await post('UserAPI/Public/VerifyRegistration',{challengeId:challenge.challengeId,otp:code});
  const bound=await post('UserAPI/Public/Register',{challengeId:challenge.challengeId,otp:code,consentProvided:true,name:'Tampered',schoolUdise:'INVALID-SCHOOL'});
  await post('UserAPI/Public/Register',{challengeId:challenge.challengeId,otp:code,consentProvided:true},undefined,400);
  const saved=await post('UserAPI/Workspace/GetData',{},admin.jwtToken);
  const boundPerson=saved['teacher-training-trainees'].find(t=>t.traineeId===bound.traineeId);
  assert.equal(boundPerson.name,payload.name);assert.equal(boundPerson.schoolUdise,school.udise);
  const reports=await post('ReportAPI/Reports/GetData',{},admin.jwtToken);assert(reports._dashboard);
  await post('BatchAPI/Batches/GetData',{},admin.jwtToken);
  const teacherHealth=await fetch('http://localhost:5100/api/TeacherAPI/Health/ready');assert.equal(teacherHealth.status,200);
  assert.deepEqual(errors,[]);
  await page.screenshot({path:path.join(__dirname,'../.local/screenshots/latest-registration.png'),fullPage:true});
  fs.writeFileSync(path.join(__dirname,'../.local/latest-registration-result.json'),JSON.stringify({passed:true,profilePersisted:true,otp:true,services:4,time:new Date().toISOString()},null,2));
  console.log('PASS: expanded school/teaching profile, outbox OTP verification, registration persistence and all four service routes.');
 }finally{await browser.close();}
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
