const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium}=require(path.join(__dirname,'../.local/browser-runner/node_modules/playwright'));
const {post,loginWithOtp}=require('./PortalIntegration.cjs');
async function main(){
 const login=await loginWithOtp('Demo1');const snapshot=await post('Workspace/GetData',{},login.jwtToken);
 const batches=snapshot._dashboard.batches,daily=new Map();let present=0,marked=0;
 for(const batch of batches){present+=batch.teacherMetrics.attendancePresent;marked+=batch.teacherMetrics.attendanceMarked;
  for(const day of batch.attendanceDays.filter(d=>d.audience==='Teacher')){const total=daily.get(day.date)||{present:0,marked:0};total.present+=day.present;total.marked+=day.marked;daily.set(day.date,total);}}
 const expected=[...daily.entries()].sort(([a],[b])=>a.localeCompare(b)).slice(-4).map(([,day])=>(100*day.present/day.marked).toFixed(1)+'%');
 const browser=await chromium.launch({channel:'chrome',headless:true});const errors=[];
 try{const page=await browser.newPage({viewport:{width:1920,height:1080}});page.on('pageerror',error=>errors.push(error.message));
  await page.goto('http://localhost:5173/TeacherTraining/login');
  await page.evaluate(({token,user})=>{sessionStorage.setItem('teacher-training-api-token',token);localStorage.setItem('teacher-training-session',JSON.stringify(user));},{token:login.jwtToken,user:login.user});
  await page.goto('http://localhost:5173/TeacherTraining/');await page.waitForFunction(()=>document.querySelector('#attendance .line-chart')?.getAttribute('aria-label')?.includes('saved daily attendance'));
  assert.deepEqual(await page.locator('#attendance .line-value text').allTextContents(),expected);
  assert((await page.locator('.kpi').filter({hasText:'Attendance Rate'}).innerText()).includes((100*present/marked).toFixed(1)+'%'));
  await page.getByRole('button',{name:'Student',exact:true}).click();assert.equal(await page.locator('#attendance .line-dot').count(),0);
  assert(await page.locator('[data-attendance-empty]').isVisible());
  await page.getByRole('button',{name:'Teacher',exact:true}).click();assert.deepEqual(await page.locator('#attendance .line-value text').allTextContents(),expected);
  await page.screenshot({path:path.join(__dirname,'../.local/screenshots/Demo1-dashboard.png'),fullPage:true});
  assert.equal(errors.length,0,errors.join('\n'));
  fs.writeFileSync(path.join(__dirname,'../.local/dashboard-test-result.json'),JSON.stringify({passed:true,checks:6,time:new Date().toISOString()},null,2));
  console.log('PASS: 6 Chrome checks for real daily attendance, KPI totals and empty-data audience switching.');
 }finally{await browser.close();}
}
main().catch(error=>{console.error(error.stack);process.exitCode=1;});
