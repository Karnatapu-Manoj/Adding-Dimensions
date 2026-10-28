"""Export a portable development database plus the keys/files needed by the app."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT=Path(__file__).resolve().parent.parent
TRANSIENT=['app_auth_session','teacher_auth_tokens','portal_otp_challenge','portal_recovery_request','assessment_start']


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=ROOT.parent/'Database Import')
    parser.add_argument('--postgres-bin',type=Path,default=Path(r'C:\Program Files\PostgreSQL\18\bin'))
    args=parser.parse_args();out=args.output.resolve()
    if out.exists() and any(out.iterdir()):
        raise SystemExit('The export directory is not empty. Choose a new --output directory.')
    out.mkdir(parents=True,exist_ok=True)
    config=json.loads((ROOT/'Microservices/TeachersAPI/appsettings.Local.json').read_text(encoding='utf-8'))
    connection=dict(part.split('=',1) for part in config['ConnectionStrings']['DBConnection'].split(';') if part)
    env=os.environ.copy();env['PGPASSWORD']=connection['Password'];env['PGCLIENTENCODING']='UTF8'
    def run(command):
        result=subprocess.run(command,env=env,capture_output=True,text=True,encoding='utf-8',errors='replace',
            creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
        if result.returncode:raise RuntimeError(result.stderr[-2000:])
        return result.stdout
    common=['-w','-h',connection['Host'],'-p',connection.get('Port','5432'),'-U',connection['Username']]
    dump=[str(args.postgres_bin/'pg_dump.exe'),*common,'-d',connection['Database'],
        '--format=custom','--no-owner','--no-privileges','--file',str(out/'AddingDimensions.backup')]
    for table in TRANSIENT:dump+=['--exclude-table-data=public.'+table]
    run(dump)
    run([str(args.postgres_bin/'pg_restore.exe'),'--no-owner','--no-privileges',
        '--file',str(out/'AddingDimensions.sql'),str(out/'AddingDimensions.backup')])
    inventory_sql="""SELECT jsonb_build_object(
        'serverVersion',current_setting('server_version'),
        'tableCount',(SELECT count(*) FROM pg_tables WHERE schemaname='public'),
        'viewCount',(SELECT count(*) FROM pg_views WHERE schemaname='public'),
        'collectionCount',(SELECT count(*) FROM public.portal_collection),
        'tables',(SELECT jsonb_agg(jsonb_build_object('name',t.tablename,'columnCount',
            (SELECT count(*) FROM information_schema.columns c WHERE c.table_schema='public' AND c.table_name=t.tablename))
            ORDER BY t.tablename) FROM pg_tables t WHERE t.schemaname='public'),
        'views',(SELECT jsonb_agg(viewname ORDER BY viewname) FROM pg_views WHERE schemaname='public'),
        'procedures',(SELECT jsonb_agg(p.proname ORDER BY p.proname) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prokind='p'),
        'functions',(SELECT jsonb_agg(p.proname ORDER BY p.proname) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prokind='f'),
        'sampleCounts',jsonb_build_object('schools',(SELECT count(*) FROM public.m_school WHERE NOT portal_deleted),
            'projects',(SELECT count(*) FROM public.project WHERE NOT portal_deleted),
            'plans',(SELECT count(*) FROM public.training_plan WHERE NOT portal_deleted),
            'batches',(SELECT count(*) FROM public.training_batch WHERE NOT portal_deleted),
            'trainees',(SELECT count(*) FROM public.trainee WHERE NOT portal_deleted),
            'registrations',(SELECT count(*) FROM public.batch_enrollment WHERE NOT portal_deleted),
            'attendance',(SELECT count(*) FROM public.attendance WHERE NOT portal_deleted),
            'resources',(SELECT count(*) FROM public.learning_resource WHERE portal_collection='teacher-training-learning-resources' AND NOT portal_deleted))
    );"""
    database=json.loads(run([str(args.postgres_bin/'psql.exe'),'-X','-A','-t',*common,'-d',connection['Database'],'-c',inventory_sql]))
    shutil.copy2(ROOT/'Tools/PortableSetup.py',out/'setup_local.py')
    resources=out/'resources';resources.mkdir()
    for file in sorted((ROOT/'.local/resources').iterdir()):
        if file.is_file():shutil.copy2(file,resources/file.name)
    (out/'application-encryption.private.json').write_text(json.dumps({'Pii':config['Pii']},indent=2)+'\n',encoding='utf-8')
    (out/'.gitignore').write_text('*\n!.gitignore\n',encoding='utf-8')
    (out/'START HERE.txt').write_text(
        'ADDING DIMENSIONS - PORTABLE LOCAL SETUP\n\n'
        'Read Project Review.docx or Project Review.pdf in the parent folder.\n'
        'Install PostgreSQL 18, the pinned .NET 10 SDK, Node.js 24 and Python 3.11+.\n'
        'Copy Front-End CodeBase and Back-End CodeBase as siblings on the new machine.\n'
        'Do not copy source-machine appsettings.Local.json files or .env.local.\n'
        'In PowerShell, from the copied Adding Dimensions folder, run:\n\n'
        'python ".\\Database Import\\setup_local.py" --backend ".\\Back-End CodeBase"\n\n'
        'The script securely prompts for YOUR local PostgreSQL admin password. It creates a\n'
        'new database/application role, restores data and files, and writes local settings.\n'
        'Existing database/role/settings are never overwritten. Use --database and --app-user\n'
        'to choose fresh names if needed. Use --help for all options. Then:\n\n'
        'Set-Location ".\\Front-End CodeBase"\n'
        'npm.cmd ci\n'
        'npm.cmd run build\n'
        'Set-Location "..\\Back-End CodeBase"\n'
        'dotnet restore .\\AddingDimensions.sln\n'
        '.\\Start-Local.ps1\n\n'
        'Open http://localhost:5173/TeacherTraining/login\n'
        'Demo1 through Demo8 use password demo1@123 and local email-outbox OTP.\n\n'
        'PRIVATE MATERIAL: The database contains development data and password hashes.\n'
        'application-encryption.private.json is REQUIRED to decrypt existing contacts and\n'
        'match their blind indexes. Transfer it privately with the backup; do not publish it.\n'
        'No original PostgreSQL admin/application password or JWT/transport secret is included.\n'
        'Active sessions, OTPs and in-progress assessment starts are excluded; sign in again.\n'
        'Learning files are separate from SQL and are included in resources/.\n',encoding='utf-8')
    files={str(file.relative_to(out)).replace('\\','/'):hashlib.file_digest(file.open('rb'),'sha256').hexdigest()
        for file in sorted(out.rglob('*')) if file.is_file()}
    manifest={'createdUtc':datetime.now(timezone.utc).isoformat(),'formatVersion':1,
        'database':database,'excludedTableData':['public.'+name for name in TRANSIENT],
        'sha256':files,'note':'Development handover snapshot. PII encryption keys are private; source database credentials are not exported.'}
    (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    print('Created database archive, SQL import, private data-encryption key file, resources and local setup helper.')
    print('Export: '+str(out))
    print(f"Objects: {database['tableCount']} tables, {database['viewCount']} views, {len(database['procedures'])} procedures.")


if __name__=='__main__':main()
