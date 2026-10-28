"""Run an explicitly selected SQL file under DB Scripts using ignored local credentials."""
import json, os, subprocess, sys
from pathlib import Path
root=Path(__file__).resolve().parent.parent
target=Path(sys.argv[1]).resolve()
if not target.is_relative_to(root/'DB Scripts') or target.suffix.lower()!='.sql':
    raise SystemExit('Choose an SQL file inside this project\'s DB Scripts directory.')
config=json.loads((root/'Microservices/TeachersAPI/appsettings.Local.json').read_text())
connection=dict(part.split('=',1) for part in config['ConnectionStrings']['DBConnection'].split(';') if part)
env=os.environ.copy();env['PGPASSWORD']=connection['Password']
result=subprocess.run([r'C:\Program Files\PostgreSQL\18\bin\psql.exe','-X','-w','-h',connection['Host'],
    '-p',connection['Port'],'-U',connection['Username'],'-d',connection['Database'],'-v','ON_ERROR_STOP=1',
    '--single-transaction','-f',str(target)],env=env,capture_output=True,text=True)
print(result.stdout,end='')
if result.returncode: print(result.stderr[-3000:]);raise SystemExit(result.returncode)
