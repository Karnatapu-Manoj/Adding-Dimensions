const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict');
const config=JSON.parse(fs.readFileSync(process.env.PORTABLE_TEST_CONFIG,'utf8'));
const base=process.env.PORTABLE_TEST_URL,backend=process.env.PORTABLE_TEST_BACKEND;
function encrypt(body){const salt=crypto.randomBytes(16),nonce=crypto.randomBytes(12),key=crypto.pbkdf2Sync(config.AESPassword,salt,1000,32,'sha256');const cipher=crypto.createCipheriv('aes-256-gcm',key,nonce);const data=Buffer.concat([cipher.update(JSON.stringify(body)),cipher.final()]);return{data:data.toString('base64'),salt:salt.toString('base64'),nonce:nonce.toString('base64'),tag:cipher.getAuthTag().toString('base64')};}
function decrypt(body){const key=crypto.pbkdf2Sync(config.AESPassword,Buffer.from(body.salt,'base64'),1000,32,'sha256');const cipher=crypto.createDecipheriv('aes-256-gcm',key,Buffer.from(body.nonce,'base64'));cipher.setAuthTag(Buffer.from(body.tag,'base64'));return JSON.parse(Buffer.concat([cipher.update(Buffer.from(body.encryptedData,'base64')),cipher.final()]).toString());}
async function post(route,body,token){const response=await fetch(base+'/api/'+route,{method:'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:'Bearer '+token}:{})},body:JSON.stringify(encrypt(body))});const result=decrypt(await response.json());assert.equal(response.status,200,route+': '+result.returnMessage);assert(result.isSuccess);return result.data;}
async function main(){
 let admin;
 for(let n=1;n<=8;n++){
  const pending=await post('Account/Login',{userName:'Demo'+n,password:'demo1@123'});assert(pending.requiresOtp&&!pending.jwtToken);
  const mail=fs.readFileSync(path.join(backend,'.local/mail-outbox',pending.challengeId+'.eml'),'utf8');
  const login=await post('Account/VerifyLogin',{challengeId:pending.challengeId,otp:/OTP: (\d{6})/.exec(mail)[1]});
  assert.equal(login.user.userId,'Demo'+n);if(n===2)admin=login.jwtToken;
 }
 const workspace=await post('Workspace/GetData',{},admin);assert.equal(workspace['teacher-training-schools'].length,750);
 assert(workspace['teacher-training-trainees'].some(row=>row.email?.includes('@')&&!row.email.includes('*')),'Existing encrypted contacts must decrypt.');
 const resource=workspace['teacher-training-learning-resources'].find(row=>row.id==='manual');
 const response=await fetch(resource.url);assert.equal(response.status,200);assert((await response.arrayBuffer()).byteLength>100);
 console.log('Portable runtime verification passed.');
}
main().catch(error=>{console.error(error.message);process.exitCode=1;});
