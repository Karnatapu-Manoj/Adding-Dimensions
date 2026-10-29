"""Restore the Adding Dimensions handover into a new local PostgreSQL database.

Uses only the Python standard library and PostgreSQL command-line utilities.
Existing databases, roles, local settings and resource files are never overwritten.
"""
import argparse
import getpass
import hashlib
import json
import os
from pathlib import Path
import re
import secrets
import shutil
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--backend', required=True, type=Path)
    parser.add_argument('--package', type=Path, default=Path(__file__).resolve().parent)
    parser.add_argument('--postgres-bin', type=Path, default=Path(r'C:\Program Files\PostgreSQL\18\bin'))
    parser.add_argument('--host', default='localhost')
    parser.add_argument('--port', type=int, default=5432)
    parser.add_argument('--database', default='adding_dimensions')
    parser.add_argument('--app-user', default='adding_dimensions_app')
    parser.add_argument('--admin-user', default='postgres')
    parser.add_argument('--maintenance-db', default='postgres')
    parser.add_argument('--configure-only', action='store_true', help='Configure a database already restored manually; prompts for its application password.')
    args = parser.parse_args()
    backend = args.backend.resolve()
    package = args.package.resolve()
    for value in (args.database, args.app_user, args.admin_user, args.maintenance_db):
        if not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]{0,62}', value):
            raise ValueError('Database and role names must use letters, digits and underscores; maximum 63 characters.')
    if not re.fullmatch(r'[A-Za-z0-9.:_-]+', args.host) or not 1 <= args.port <= 65535:
        raise ValueError('Invalid host or port.')
    api = backend / 'Microservices/TeachersAPI'
    gateway = backend / 'OcelotGateWay'
    for project in (api/'TeachersAPI.csproj', gateway/'OcelotGateWay.csproj'):
        if not project.is_file():
            raise ValueError('Copy the Back-End CodeBase source folder first. Missing: '+str(project))
    configs = [api/'appsettings.Local.json', gateway/'appsettings.Local.json']
    configs += [api.parent/name/'appsettings.Local.json' for name in ['UserAPI','BatchAPI','ReportAPI'] if (api.parent/name).is_dir()]
    if any(path.exists() for path in configs):
        raise ValueError('Local configuration already exists. Choose a fresh checkout/folder. Existing settings will not be replaced.')
    resources = backend/'.local/resources'
    if resources.exists() and any(resources.iterdir()):
        raise ValueError('The target .local/resources directory is not empty. Use a fresh backend folder.')
    manifest = json.loads((package/'manifest.json').read_text(encoding='utf-8'))
    for relative, expected in manifest['sha256'].items():
        target = (package/relative).resolve()
        if not target.is_relative_to(package) or not target.is_file():
            raise ValueError('A package file is missing or invalid: '+relative)
        digest = hashlib.file_digest(target.open('rb'), 'sha256').hexdigest()
        if digest != expected:
            raise ValueError('Package checksum mismatch: '+relative)
    keys = json.loads((package/'application-encryption.private.json').read_text(encoding='utf-8'))['Pii']
    if not keys.get('EncryptionKey') or not keys.get('BlindIndexKey'):
        raise ValueError('The exported database encryption keys are missing.')
    suffix = '.exe' if os.name == 'nt' else ''
    def executable(name):
        candidate = args.postgres_bin/(name+suffix)
        found = str(candidate) if candidate.is_file() else shutil.which(name)
        if not found:
            raise ValueError(name+' was not found. Set --postgres-bin to the PostgreSQL 18 bin directory.')
        return found
    psql, restore = executable('psql'), executable('pg_restore')
    def run(command, password, input_text=None):
        environment = os.environ.copy()
        environment['PGPASSWORD'] = password
        environment['PGCLIENTENCODING'] = 'UTF8'
        result = subprocess.run(command, input=input_text, text=True, encoding='utf-8',
            errors='replace', env=environment, capture_output=True,
            creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
        if result.returncode:
            # Do not print SQL input, connection strings, passwords, or configuration contents.
            raise RuntimeError('PostgreSQL operation failed. '+result.stderr[-1800:])
        return result.stdout.strip()
    def query(database, user, password, sql):
        return run([psql, '-X', '-w', '-A', '-t', '-h', args.host, '-p', str(args.port),
            '-U', user, '-d', database, '-v', 'ON_ERROR_STOP=1'], password, sql)

    if args.configure_only:
        app_password = os.environ.get('AD_POSTGRES_APP_PASSWORD') or getpass.getpass('Restored database application password: ')
        query(args.database, args.app_user, app_password, 'CALL public.usp_check_database_health();')
    else:
        admin_password = os.environ.get('AD_POSTGRES_ADMIN_PASSWORD') or getpass.getpass('PostgreSQL administrator password on THIS machine: ')
        exists = query(args.maintenance_db, args.admin_user, admin_password,
            f"SELECT count(*) FROM pg_database WHERE datname='{args.database}';")
        if exists != '0':
            raise ValueError('The target database already exists. Choose a NEW --database; nothing was overwritten.')
        exists = query(args.maintenance_db, args.admin_user, admin_password,
            f"SELECT count(*) FROM pg_roles WHERE rolname='{args.app_user}';")
        if exists != '0':
            raise ValueError('The application role already exists. Choose a NEW --app-user; its password was not changed.')
        app_password = secrets.token_urlsafe(36)
        query(args.maintenance_db, args.admin_user, admin_password,
            f'CREATE ROLE "{args.app_user}" LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD \'{app_password}\';\n'
            f'CREATE DATABASE "{args.database}" OWNER "{args.app_user}" TEMPLATE template0 ENCODING \'UTF8\';')
        run([restore, '-w', '-h', args.host, '-p', str(args.port), '-U', args.app_user, '-d', args.database,
            '--no-owner', '--no-privileges', '--clean', '--if-exists', '--exit-on-error', '--single-transaction',
            str(package/'AddingDimensions.backup')], app_password)
        query(args.database, args.app_user, app_password,
            'UPDATE public.app_user SET failed_login_count=0,locked_until=NULL;\n'
            'CALL public.usp_check_database_health();')
        print('Restored database '+args.database+' with a dedicated non-superuser owner.')

    # Restore verification precedes writing configuration, so unusable credentials are not saved.
    objects = query(args.database, args.app_user, app_password,
        "SELECT count(*) FROM pg_tables WHERE schemaname='public';")
    if int(objects) != manifest['database']['tableCount']:
        raise ValueError('Restored table count differs from the package manifest.')
    def quote_connection(value):
        return '"'+value.replace('"','""')+'"' if any(c in value for c in ';"') or value!=value.strip() else value
    connection = ';'.join(key+'='+quote_connection(value) for key,value in {
        'Host':args.host, 'Port':str(args.port), 'Database':args.database,
        'Username':args.app_user, 'Password':app_password}.items())
    configuration = {
        'ConnectionStrings': {'DBConnection':connection},
        'Jwt': {'SecurityKey':secrets.token_urlsafe(48)},
        'AESPassword':secrets.token_urlsafe(48),
        'Pii':keys,
        'BusinessTimeZone':'Asia/Kolkata',
        'GatewayBaseUrl':'http://localhost:5100',
        'Cors': {'AllowedOrigins':['http://localhost:5173','http://127.0.0.1:5173']}
    }
    resources.mkdir(parents=True, exist_ok=True)
    for file in (package/'resources').iterdir():
        if file.is_file():
            shutil.copy2(file, resources/file.name)
    for path in configs:
        with path.open('x', encoding='utf-8') as output:
            json.dump(configuration, output, indent=2)
            output.write('\n')
    print('Saved matching ignored local settings for TeachersAPI and OcelotGateWay.')
    print('Copied learning files. Original demo account passwords are unchanged.')
    print('Next: npm ci in Front-End CodeBase, then Start-Local.ps1 in Back-End CodeBase.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, RuntimeError, OSError, KeyError) as error:
        print('Setup stopped: '+str(error), file=sys.stderr)
        sys.exit(1)
