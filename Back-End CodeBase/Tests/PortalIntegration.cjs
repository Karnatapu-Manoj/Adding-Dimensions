const fs=require('node:fs');const path=require('node:path');const crypto=require('node:crypto');const assert=require('node:assert/strict');
const config=JSON.parse(fs.readFileSync(path.join(__dirname,'../Microservices/TeachersAPI/appsettings.Local.json'),'utf8'));
const base='http://localhost:5100/api/';let checks=0;
function encrypt(body){const salt=crypto.randomBytes(16),nonce=crypto.randomBytes(12),key=crypto.pbkdf2Sync(config.AESPassword,salt,1000,32,'sha256');const cipher=crypto.createCipheriv('aes-256-gcm',key,nonce);const data=Buffer.concat([cipher.update(JSON.stringify(body)),cipher.final()]);return{data:data.toString('base64'),salt:salt.toString('base64'),nonce:nonce.toString('base64'),tag:cipher.getAuthTag().toString('base64')};}
function decrypt(body){if(!body.encryptedData)return body;const key=crypto.pbkdf2Sync(config.AESPassword,Buffer.from(body.salt,'base64'),1000,32,'sha256');const cipher=crypto.createDecipheriv('aes-256-gcm',key,Buffer.from(body.nonce,'base64'));cipher.setAuthTag(Buffer.from(body.tag,'base64'));return JSON.parse(Buffer.concat([cipher.update(Buffer.from(body.encryptedData,'base64')),cipher.final()]).toString());}
async function post(route,body={},token,expected=200){const response=await fetch(base+route,{method:'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:JSON.stringify(encrypt(body))});let message=decrypt(await response.json());assert.equal(response.status,expected,`${route}: ${message.returnMessage}`);checks++;if(expected<400)assert.equal(message.isSuccess,true);return message.data??message;}
const records=(snapshot,key)=>snapshot['teacher-training-'+key]??[];
async function save(route,rows,token,deletes=[],expected=200){return post(route+'/SaveData',{upserts:rows,deletes},token,expected);}
function readOtp(challengeId){const message=fs.readFileSync(path.join(__dirname,'../.local/mail-outbox',challengeId+'.eml'),'utf8');return /OTP: (\d{6})/.exec(message)[1];}
async function loginWithOtp(userName,password='demo1@123'){
 const challenge=await post('Account/Login',{userName,password});
 assert.equal(challenge.requiresOtp,true);assert(!challenge.jwtToken);
 return post('Account/VerifyLogin',{challengeId:challenge.challengeId,otp:readOtp(challenge.challengeId)});
}
async function main(){
 const cacheFile=path.join(__dirname,'../.local/integration-tokens.json');
 const tokens={};
 for(let n=1;n<=8;n++){if(tokens[n])continue;const login=await loginWithOtp('Demo'+n);assert.equal(login.user.userId,'Demo'+n);tokens[n]=login.jwtToken;fs.writeFileSync(cacheFile,JSON.stringify(tokens));}
 const admin=tokens[2],trainer=tokens[6],trainee=tokens[7],sponsor=tokens[1];
 let snapshot=await post('Workspace/GetData',{},admin);assert.equal(records(snapshot,'schools').length,750);checks++;
 assert.equal(records(snapshot,'learning-resources').length,5);checks++;
 assert.equal(records(snapshot,'plans')[0].name,'Digital Teaching Foundations');checks++;
 await post('Workspace/GetData',{},undefined,401);
 await save('Projects',[],sponsor,[],403);await save('Holidays',[],tokens[3],[],403);await save('Users',[],tokens[8],[],403);
 let own=await post('Workspace/GetData',{},trainee);
 assert(records(own,'trainees').every(row=>row.userId==='Demo7'));checks++;
 assert(records(own,'registrations').every(row=>row.userId==='Demo7'));checks++;
 assert(records(own,'assessment-form-master').every(form=>form.questions.every(q=>q.correctIndex===undefined)));checks++;
 const uid=crypto.randomBytes(5).toString('hex');const school=records(snapshot,'schools').find(row=>row.state==='Andhra Pradesh');
 const project={id:'TEST-PROJECT-'+uid,code:'TEST-'+uid,name:'Integration verification',odooReference:'TEST-'+uid,odooId:'TEST-'+uid,sponsor:'Test',startDate:'2026-01-01',endDate:'2027-12-31',description:'Automated integration fixture',states:[school.state],assignedUsers:['Demo2'],status:'Active',phases:[],trainingPlans:[]};
 snapshot=await save('Projects',[project],admin);
 const savedProject=records(snapshot,'projects').find(r=>r.id===project.id);assert(savedProject._dbId);checks++;
 let hidden=await post('Workspace/GetData',{},tokens[3]);assert(!records(hidden,'projects').some(r=>r.id===project.id));checks++;
 await save('Projects',[{...savedProject,name:'Stale',_version:0}],admin,[],409);
 snapshot=await save('Projects',[],admin,[{id:project.id,version:savedProject._version}]);
 assert(!records(snapshot,'projects').some(r=>r.id===project.id));checks++;
 const mainProject=records(snapshot,'projects').find(r=>r.id.startsWith('DEMO-SAMPLE-'));
 const plan={id:'TEST-PLAN-'+uid,code:'TST-'+uid,name:'Integration plan',type:'Classroom',description:'Verification',days:2,beneficiaries:['Teacher'],resources:[],resourceAssignments:[],learningResourceIds:[],completionCriteria:{minimumAttendancePercent:100,mandatoryTrainingDays:[],requireAssessments:true,minimumAssessmentMarks:1,requireFeedback:true,requireExternalCourse:false},status:'Active',createdAt:new Date().toISOString()};
 snapshot=await save('TrainingPlans',[plan],admin);
 const association={id:'TEST-ASSOC-'+uid,projectId:mainProject.id,trainingPlanId:plan.id,status:'Active',createdAt:new Date().toISOString(),updatedAt:new Date().toISOString()};
 snapshot=await save('ProjectPlans',[association],admin);
 const batch={id:'TEST-BATCH-'+uid,batchCode:'TST-B-'+uid,uniqueId:'TST-B-'+uid,projectId:mainProject.id,projectPlanAssociationId:association.id,name:'Integration batch',schoolUdiseVenue:school.udise,schoolName:school.school,state:school.state,district:school.district,location:school.school,trainingPlanCode:plan.code,trainingDuration:2,trainingStartDate:'2026-10-26',trainingEndAuto:'2026-10-27',trainingDates:['2026-10-26','2026-10-27'],trainingStartTime:'07:00',trainingEndTime:'08:00',trainerCode:'Demo6',trainerProfileCode:'TR-00001',openRegistration:false,registrationCapacity:30,status:'Ongoing',createdAt:new Date().toISOString(),createdBy:'Demo2'};
 const trainerProfile=records(snapshot,'trainer-profiles').find(r=>r.userId==='Demo6');batch.trainerProfileCode=trainerProfile.trainerCode;
 snapshot=await save('Batches',[batch],admin);
 const person=records(snapshot,'trainees').find(r=>r.userId==='Demo7');
 const registration={id:'TEST-REG-'+uid,batchId:batch.id,batchCode:batch.batchCode,projectId:mainProject.id,traineeId:person.id,userId:'Demo7',traineeName:person.name,name:person.name,status:'Approved',approvalStatus:'Approved',approved:true,source:'Integration verification',consentProvided:true};
 snapshot=await save('Registrations',[registration],admin);
 const mark={id:'TEST-ATT-'+uid,batchId:batch.id,batchCode:batch.batchCode,projectId:mainProject.id,traineeId:person.id,userId:'Demo7',traineeName:person.name,trainingDate:'2026-10-27',status:'Present'};
 let attendance=await save('Attendance',[mark],trainer);assert(records(attendance,'attendance-records').some(r=>r.id===mark.id));checks++;
 await save('Attendance',[{...mark,id:'TEST-FUTURE-'+uid,trainingDate:'2027-01-01'}],trainer,[],400);
 await save('Attendance',[{...mark,id:'TEST-NOACCESS-'+uid}],tokens[5],[],403);
 const form={id:'TEST-FORM-'+uid,title:'Integration assessment',kind:'assessment',grading:'graded',source:'native',planCode:plan.code,day:1,stage:'post',maxMarks:1,passMarks:1,attemptLimit:1,timeLimit:1,allowUnanswered:false,mandatory:true,comparable:true,questions:[{id:'q1',prompt:'Choose the correct option',options:['Correct','Wrong'],correctIndex:0,points:1,required:true}],createdAt:new Date().toISOString()};
 snapshot=await save('AssessmentForms',[form],admin);
 const attempt={id:'TEST-ATTEMPT-'+uid,formId:form.id,formTitle:form.title,batchId:batch.id,batchCode:batch.batchCode,registrationId:registration.id,traineeId:'Demo7',userId:'Demo7',planCode:plan.code,day:1,stage:'post',kind:'assessment',grading:'graded',completed:true,status:'Passed',score:999,maxMarks:999,answers:{q1:'0'},submittedAt:new Date().toISOString()};
 const started=await post('Assessments/Begin',{formId:form.id,batchId:batch.id},trainee);attempt.attemptToken=started.attemptToken;
 own=await save('Assessments',[attempt],trainee);const scored=records(own,'assessment-records').find(r=>r.id===attempt.id);assert.equal(scored.score,1);assert.equal(scored.maxMarks,1);checks+=2;
 await save('Assessments',[{...attempt,id:'TEST-RETAKE-'+uid}],trainee,[],400);
 const resource=records(snapshot,'learning-resources').find(r=>r.id==='manual');
 const download=await fetch(resource.url);assert.equal(download.status,200);assert((await download.arrayBuffer()).byteLength>100);checks+=2;
 const tampered=await fetch(resource.url+'x');assert.equal(tampered.status,401);checks++;
 await post('Account/Login',{userName:'NoSuchAccount',password:'incorrect'},undefined,401);
 await post('Account/Logout',{},tokens[8]);await post('Workspace/GetData',{},tokens[8],401);
 const feedback={...form,id:'TEST-FEEDBACK-'+uid,timeLimit:0,title:'Integration feedback',kind:'feedback',grading:'non-graded',stage:'feedback',passMarks:0,questions:[{id:'q1',prompt:'Was it useful?',options:['Yes','No'],points:0,required:true}]};
 snapshot=await save('AssessmentForms',[feedback],admin);
 const feedbackAttempt={...attempt,id:'TEST-FEEDBACK-ATT-'+uid,formId:feedback.id,kind:'feedback',grading:'non-graded',answers:{q1:'0'}};
 own=await save('Feedback',[feedbackAttempt],trainee);const feedbackResult=records(own,'feedback-records').find(r=>r.id===feedbackAttempt.id);assert.equal(feedbackResult.score,null);checks++;
 snapshot=await post('Workspace/GetData',{},admin);
 const template=records(snapshot,'certificate-templates').find(t=>t.mode==='Hybrid');
 const certificate={id:'TEST-CERT-'+uid,registrationId:registration.id,batchId:batch.id,traineeId:person.id,traineeName:'FORGED NAME',templateSnapshot:{...template,title:'FORGED TEMPLATE'},templateMode:'Hybrid',status:'Issued',issuedAt:new Date().toISOString(),certificateNumber:'FORGED-NUMBER'};
 await save('Certificates',[certificate],admin,[],400);
 await save('Attendance',[{...mark,id:'TEST-ATT-DAY1-'+uid,trainingDate:'2026-10-26'}],trainer);
 snapshot=await save('Certificates',[certificate],admin);
 const issued=records(snapshot,'certificates').find(c=>c.id===certificate.id);
 assert.equal(issued.traineeName,person.name);assert.equal(issued.templateSnapshot.title,template.title);assert.notEqual(issued.certificateNumber,'FORGED-NUMBER');checks+=3;
 snapshot=await save('Certificates',[{...issued,status:'Reissued'},{...certificate,id:'TEST-CERT-REISSUE-'+uid,reissueOf:issued.id,reason:'Integration verification'}],admin);
 const reissued=records(snapshot,'certificates').find(c=>c.id==='TEST-CERT-REISSUE-'+uid);
 assert(reissued && reissued.certificateNumber!==issued.certificateNumber);checks++;
 snapshot=await save('Certificates',[{...reissued,status:'Revoked',reason:'Integration verification cleanup'}],admin);
 assert.equal(records(snapshot,'certificates').find(c=>c.id===reissued.id).status,'Revoked');checks++;
 const freshBatch=records(snapshot,'batch-plan-uses').find(r=>r.id===batch.id);
 snapshot=await save('Batches',[{...freshBatch,status:'Cancelled'}],admin);
 const next=await loginWithOtp('Demo2');await post('Workspace/GetData',{},admin,401);
 await post('Workspace/GetData',{},next.jwtToken);
 console.log(`PASS: ${checks} encrypted API and database integration checks across all eight demo roles.`);
 fs.writeFileSync(path.join(__dirname,'../.local/api-test-result.json'),JSON.stringify({checks,passed:true,fixture:uid,time:new Date().toISOString()},null,2));
}
if(require.main===module)main().catch(error=>{console.error(error.message);process.exitCode=1;});
module.exports={encrypt,decrypt,post,config,readOtp,loginWithOtp};
