"""Deploy reviewed SQL files using the ignored local application connection."""
import json,os,subprocess
from pathlib import Path
root=Path(__file__).resolve().parent.parent
config=json.loads((root/'Microservices/TeachersAPI/appsettings.Local.json').read_text())
connection=dict(part.split('=',1) for part in config['ConnectionStrings']['DBConnection'].split(';') if part)
env=os.environ.copy();env['PGPASSWORD']=connection['Password']
args=[r'C:\Program Files\PostgreSQL\18\bin\psql.exe','-X','-w','-h',connection['Host'],'-p',connection['Port'],
      '-U',connection['Username'],'-d',connection['Database'],'-v','ON_ERROR_STOP=1','--single-transaction']
for folder in ['Table Creations','Stored Procedures']:
 for file in sorted((root/'DB Scripts'/folder).glob('*.sql')):args+=['-f',str(file)]
result=subprocess.run(args,capture_output=True,text=True,env=env)
(root/'.local').mkdir(exist_ok=True)
(root/'.local/database-deploy.log').write_text(result.stdout+result.stderr,encoding='utf-8')
if result.returncode:print('\n'.join(result.stderr.splitlines()[-15:]));raise SystemExit(result.returncode)
print('Local database scripts deployed successfully in one transaction.')
