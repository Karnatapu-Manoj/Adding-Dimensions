"""Create the local application database and ignored development configuration.

Supply the PostgreSQL administrator password through AD_POSTGRES_ADMIN_PASSWORD.
The administrator password is never written into application configuration.
"""
import json
import os
import secrets
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PSQL = Path(os.environ.get("POSTGRES_BIN", r"C:\Program Files\PostgreSQL\18\bin")) / "psql.exe"
API_CONFIG = ROOT / "Microservices/TeachersAPI/appsettings.Local.json"
GATEWAY_CONFIG = ROOT / "OcelotGateWay/appsettings.Local.json"
SERVICE_CONFIGS = tuple(ROOT / 'Microservices' / name / 'appsettings.Local.json'
                        for name in ('UserAPI', 'BatchAPI', 'ReportAPI'))


def run_psql(arguments, password, input_text=None, username="postgres"):
    environment = os.environ.copy()
    environment["PGPASSWORD"] = password
    result = subprocess.run([str(PSQL), "-X", "-w", "-h", "localhost", "-U", username,
                             "-v", "ON_ERROR_STOP=1", *arguments], input=input_text,
                            text=True, capture_output=True, env=environment,
                            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    if result.returncode:
        # psql diagnostics name scripts and database errors; do not print input SQL or secrets.
        raise RuntimeError(result.stderr.strip())
    return result.stdout


def main():
    admin_password = os.environ.get("AD_POSTGRES_ADMIN_PASSWORD")
    if not admin_password:
        raise SystemExit("Set AD_POSTGRES_ADMIN_PASSWORD for this process before running setup.")
    if not PSQL.is_file():
        raise SystemExit("psql.exe not found. Set POSTGRES_BIN to the PostgreSQL bin directory.")
    if any(path.exists() for path in (API_CONFIG, GATEWAY_CONFIG, *SERVICE_CONFIGS)):
        raise SystemExit("Local configuration already exists. Setup will not overwrite existing secrets.")

    application_password = secrets.token_urlsafe(36)
    create_script = (ROOT / "DB Scripts/CreateApplicationDatabase.sql").read_text(encoding="utf-8")
    bootstrap = "\\set application_password '" + application_password + "'\n" + create_script
    run_psql(["-d", "postgres"], admin_password, bootstrap)

    arguments = ["-d", "adding_dimensions", "--single-transaction"]
    for folder in ("Table Creations", "Stored Procedures"):
        for script in sorted((ROOT / "DB Scripts" / folder).glob("*.sql")):
            arguments.extend(["-f", str(script)])
    run_psql(arguments, application_password, username="adding_dimensions")

    connection = ("Host=localhost;Port=5432;Database=adding_dimensions;"
                  "Username=adding_dimensions;Password=" + application_password)
    # Verify the non-superuser application credentials before saving them.
    environment = os.environ.copy()
    environment["PGPASSWORD"] = application_password
    checked = subprocess.run([str(PSQL), "-X", "-w", "-h", "localhost", "-U", "adding_dimensions",
                              "-d", "adding_dimensions", "-c", "\\conninfo"],
                             capture_output=True, text=True, env=environment,
                             creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
    if checked.returncode:
        raise RuntimeError("Application login verification failed. Existing credentials were not modified.")

    config = {
        "ConnectionStrings": {"DBConnection": connection},
        "Jwt": {"SecurityKey": secrets.token_urlsafe(48)},
        "AESPassword": secrets.token_urlsafe(48),
        "Cors": {"AllowedOrigins": ["http://localhost:5173", "http://127.0.0.1:5173",
                                    "http://localhost:3000", "http://localhost:4200"]}
    }
    for path in (API_CONFIG, GATEWAY_CONFIG, *SERVICE_CONFIGS):
        # Exclusive creation prevents replacing an existing configuration.
        with path.open("x", encoding="utf-8") as output:
            json.dump(config, output, indent=2)
            output.write("\n")
    print("Created adding_dimensions database and verified its dedicated non-superuser login.")
    print("Deployed table and stored procedure scripts.")
    print("Saved matching secrets in ignored appsettings.Local.json files for TeachersAPI and OcelotGateWay.")
    print("No administrator password was saved in application configuration.")


if __name__ == "__main__":
    main()
