"""Verify handover restoration using an isolated temporary PostgreSQL cluster and API."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request

ROOT=Path(__file__).resolve().parent.parent
PG=Path(r'C:\Program Files\PostgreSQL\18\bin')


def free_port():
    with socket.socket() as connection:
        connection.bind(('127.0.0.1',0))
        return connection.getsockname()[1]


def main():
    package=ROOT.parent/'Database Import'
    work=Path(tempfile.mkdtemp(prefix='adding-dimensions-portable-'))
    backend=work/'Back-End CodeBase'
    pgdata=work/'postgres'
    pg_port,api_port=free_port(),free_port()
    hidden=getattr(subprocess,'CREATE_NO_WINDOW',0)
    started=False;api_process=None;api_log=None
    def run(command,env=None,input_text=None):
        # Windows pg_ctl starts a helper that can retain inherited pipe handles.
        # File redirection lets us wait for pg_ctl itself without waiting for the server to exit.
        if Path(command[0]).name=='pg_ctl.exe':
            log=work/'pg-control.log'
            with log.open('w',encoding='utf-8') as output:
                result=subprocess.run([str(x) for x in command],env=env,stdout=output,stderr=subprocess.STDOUT,creationflags=hidden)
            content=log.read_text(encoding='utf-8',errors='replace')
            if result.returncode:raise RuntimeError(content[-2500:])
            return content
        result=subprocess.run([str(x) for x in command],env=env,input=input_text,capture_output=True,
            text=True,encoding='utf-8',errors='replace',creationflags=hidden)
        if result.returncode:raise RuntimeError(result.stderr[-2500:]+result.stdout[-1500:])
        return result.stdout.strip()
    try:
        run([PG/'initdb.exe','-D',pgdata,'-U','postgres','-A','trust','--no-locale','-E','UTF8'])
        run([PG/'pg_ctl.exe','-D',pgdata,'-l',work/'postgres.log','-o',f'-h 127.0.0.1 -p {pg_port}','-w','start'])
        started=True
        for relative in ['Microservices/TeachersAPI/TeachersAPI.csproj','Microservices/TeachersAPI/appsettings.json',
                         'OcelotGateWay/OcelotGateWay.csproj','OcelotGateWay/appsettings.json']:
            target=backend/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/relative,target)
        environment=os.environ.copy();environment['AD_POSTGRES_ADMIN_PASSWORD']='isolated-trust-cluster'
        command=[sys.executable,package/'setup_local.py','--backend',backend,'--host','127.0.0.1',
            '--port',str(pg_port),'--database','adding_dimensions_restore_check','--app-user','adding_dimensions_restore_app']
        run(command,environment)
        print('PASS: custom archive restored into a new database with new local settings and learning files.',flush=True)
        config_path=backend/'Microservices/TeachersAPI/appsettings.Local.json'
        config=json.loads(config_path.read_text())
        connection=dict(part.split('=',1) for part in config['ConnectionStrings']['DBConnection'].split(';') if part)
        db_env=os.environ.copy();db_env['PGPASSWORD']=connection['Password']
        common=['-X','-w','-A','-t','-h','127.0.0.1','-p',str(pg_port),'-U',connection['Username']]
        def query(sql,database=connection['Database']):
            return run([PG/'psql.exe',*common,'-d',database,'-v','ON_ERROR_STOP=1'],db_env,sql)
        manifest=json.loads((package/'manifest.json').read_text())
        for table in manifest['excludedTableData']:
            if query('SELECT count(*) FROM '+table+';')!='0':raise RuntimeError('Transient data was restored unexpectedly: '+table)
        source_keys=json.loads((package/'application-encryption.private.json').read_text())['Pii']
        if config['Pii']!=source_keys:raise RuntimeError('Imported encryption keys differ.')
        for file in (package/'resources').iterdir():
            if hashlib.file_digest(file.open('rb'),'sha256').hexdigest()!=hashlib.file_digest((backend/'.local/resources'/file.name).open('rb'),'sha256').hexdigest():
                raise RuntimeError('A resource differs after restoration.')
        print('PASS: original PII keys and file bytes preserved; sessions, OTPs and in-progress starts are empty.',flush=True)
        refusal=subprocess.run([str(x) for x in command],env=environment,capture_output=True,text=True,creationflags=hidden)
        if refusal.returncode==0 or 'already exists' not in refusal.stderr:raise RuntimeError('Existing local settings were not protected.')
        run([PG/'psql.exe','-X','-w','-h','127.0.0.1','-p',str(pg_port),'-U','postgres','-d','postgres',
            '-v','ON_ERROR_STOP=1'],input_text='CREATE DATABASE adding_dimensions_sql_check OWNER adding_dimensions_restore_app TEMPLATE template0;')
        run([PG/'psql.exe',*common,'-d','adding_dimensions_sql_check','-v','ON_ERROR_STOP=1','--single-transaction',
            '-f',package/'AddingDimensions.sql'],db_env)
        if int(query("SELECT count(*) FROM pg_tables WHERE schemaname='public';",'adding_dimensions_sql_check'))!=manifest['database']['tableCount']:
            raise RuntimeError('Plain SQL table inventory differs.')
        if query("SELECT count(*) FROM public.app_user WHERE login_id ~ '^Demo[1-8]$';",'adding_dimensions_sql_check')!='8':
            raise RuntimeError('Demo accounts are missing from SQL restore.')
        manual_backend=work/'Manual SQL Back-End CodeBase'
        for relative in ['Microservices/TeachersAPI/TeachersAPI.csproj','Microservices/TeachersAPI/appsettings.json',
                         'OcelotGateWay/OcelotGateWay.csproj','OcelotGateWay/appsettings.json']:
            target=manual_backend/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/relative,target)
        manual_env=environment.copy();manual_env['AD_POSTGRES_APP_PASSWORD']=connection['Password']
        run([sys.executable,package/'setup_local.py','--configure-only','--backend',manual_backend,
            '--host','127.0.0.1','--port',str(pg_port),'--database','adding_dimensions_sql_check',
            '--app-user','adding_dimensions_restore_app'],manual_env)
        if not (manual_backend/'OcelotGateWay/appsettings.Local.json').is_file():
            raise RuntimeError('Configure-only did not write gateway settings.')
        print('PASS: plain SQL import and configure-only succeeded; existing settings are protected.',flush=True)
        api_env=os.environ.copy();api_env['ASPNETCORE_ENVIRONMENT']='Development'
        api_env['ASPNETCORE_URLS']=f'http://127.0.0.1:{api_port}'
        api_env['GatewayBaseUrl']=f'http://127.0.0.1:{api_port}'
        api_log=(work/'api.log').open('w',encoding='utf-8')
        api_process=subprocess.Popen(['dotnet',str(ROOT/'Microservices/TeachersAPI/bin/Release/net10.0/TeachersAPI.dll'),
            '--contentRoot',str(backend/'Microservices/TeachersAPI')],cwd=backend/'Microservices/TeachersAPI',
            env=api_env,stdout=api_log,stderr=subprocess.STDOUT,creationflags=hidden)
        url=f'http://127.0.0.1:{api_port}'
        for _ in range(100):
            if api_process.poll() is not None:raise RuntimeError('Restored API failed startup. See '+str(work/'api.log'))
            try:
                with urllib.request.urlopen(url+'/api/Health/ready',timeout=1) as response:
                    if response.status==200:break
            except OSError:time.sleep(.2)
        else:raise RuntimeError('Restored API readiness timed out.')
        client=ROOT/'Tests/VerifyPortableRuntime.cjs'
        run_env=os.environ.copy();run_env['PORTABLE_TEST_CONFIG']=str(config_path)
        run_env['PORTABLE_TEST_URL']=url;run_env['PORTABLE_TEST_BACKEND']=str(backend)
        run(['node',client],run_env)
        print('PASS: restored API verified all eight original passwords, login OTP, decrypted contacts and a signed resource download.',flush=True)
        result={'passed':True,'customArchive':True,'plainSql':True,'demoPasswords':8,'otpLogin':True,
            'encryptedContacts':True,'resourceDownload':True,'configureOnly':True,'existingSettingsProtected':True,'transientRowsExcluded':True,
            'tableCount':manifest['database']['tableCount'],'viewCount':manifest['database']['viewCount'],
            'testDirectory':str(work),'timeUtc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())}
        (ROOT/'.local/portable-restore-test-result.json').write_text(json.dumps(result,indent=2))
    finally:
        if api_process is not None and api_process.poll() is None:
            api_process.terminate();api_process.wait(timeout=15)
        if api_log is not None:api_log.close()
        if started:run([PG/'pg_ctl.exe','-D',pgdata,'-m','fast','-w','stop'])
        print('Isolated verification files: '+str(work),flush=True)


if __name__=='__main__':main()
