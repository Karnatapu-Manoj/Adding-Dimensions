const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium}=require('../.local/browser-runner/node_modules/playwright');
const {loginWithOtp,post}=require('./PortalIntegration.cjs');
async function main(){
 const auth=await loginWithOtp('Demo2');
 const snapshot=await post('UserAPI/Workspace/GetData',{},auth.jwtToken);
 const forms=snapshot['teacher-training-assessment-form-master'];
 for(const title of ['Digital Teaching Pre-assessment','Teacher Training Feedback Form'])assert(forms.some(f=>f.title===title));
 const browser=await chromium.launch({channel:'chrome',headless:true});
 try{
  const context=await browser.newContext();
  await context.addInitScript(token=>{sessionStorage.setItem('teacher-training-api-token',token);localStorage.setItem('teacher-training-session',JSON.stringify({userId:'Demo2',role:'schoolnet-super-admin'}));},auth.jwtToken);
  const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto('http://localhost:5173/TeacherTraining/content-library');
  await page.getByRole('tab',{name:/^Forms/}).click();
  await page.getByText('Digital Teaching Pre-assessment',{exact:true}).waitFor();
  await page.getByText('Teacher Training Feedback Form',{exact:true}).waitFor();
  assert.deepEqual(errors,[]);
  await page.screenshot({path:path.join(__dirname,'../.local/screenshots/latest-learning-forms.png'),fullPage:true});
  fs.writeFileSync(path.join(__dirname,'../.local/latest-learning-result.json'),JSON.stringify({passed:true,formDefinitions:forms.length,time:new Date().toISOString()},null,2));
  console.log('PASS: refreshed pre-assessment and feedback definitions persist in PostgreSQL and appear in the learning-library Forms tab.');
 }finally{await browser.close();}
}
main().catch(e=>{console.error(e.stack);process.exitCode=1;});
