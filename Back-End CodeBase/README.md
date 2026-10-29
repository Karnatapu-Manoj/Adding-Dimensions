# Adding Dimensions - local integrated application

The existing React frontend connects to four independent .NET 10 API projects through Ocelot: UserAPI, BatchAPI, ReportAPI and TeachersAPI.
PostgreSQL `adding_dimensions` holds operational data. The frontend layout,
styles, assets and folder structure are retained; authentication, data access and
screen handlers now use the API. New OTP controls use the existing screen styling.

## Run on this machine

From `Back-End CodeBase`:

```powershell
.\Start-Local.ps1 -OpenChrome
```

If the project is already running, use `Stop-Local.ps1` before rebuilding or restarting.
The script runs the four APIs, gateway and frontend in hidden processes and opens Chrome when requested.

| Service | Local URL |
| --- | --- |
| Frontend | http://localhost:5173/TeacherTraining/login |
| Open registration | http://localhost:5173/TeacherTraining/register?batch=BATCH-DEMO-NOV |
| Ocelot gateway | http://localhost:5100 |
| UserAPI Swagger | http://localhost:5101/swagger |
| BatchAPI Swagger | http://localhost:5102/swagger |
| ReportAPI Swagger | http://localhost:5103/swagger |
| TeachersAPI Swagger | http://localhost:5104/swagger |
| Database readiness | http://localhost:5100/api/Health/ready |

Swagger UI and its OpenAPI document are enabled for TeachersAPI in the `Development`
and `Local` environments. Run either launch profile from `Back-End CodeBase`:

```powershell
dotnet run --project .\Microservices\TeachersAPI --launch-profile http
# Or use the Local environment:
dotnet run --project .\Microservices\TeachersAPI --launch-profile Local
```

Open http://localhost:5101/swagger (the launch profiles also open it when launched
from an IDE). The OpenAPI document is at http://localhost:5101/swagger/v1/swagger.json.
Other environments, including Production and Staging, do not expose Swagger.
Use the Development profile or `Start-Local.ps1` for the full local application,
including its Development-only OTP outbox.

The ignored `Microservices/TeachersAPI/appsettings.Local.json` contains the application
connection, JWT and encryption settings. Ocelot has its own ignored local configuration.
`Start-Local.ps1` synchronizes the frontend's ignored `.env.local` encryption settings.
The application uses a dedicated PostgreSQL login, not the server administrator.
The local database is also visible in pgAdmin under `adding_dimensions > Schemas > public`.

## Demo sign-in and OTP

The existing password is **`demo1@123` for all eight demo IDs**. Their passwords are
preserved by seeding and protected from the password-reset flow.

| User ID | Role |
| --- | --- |
| Demo1 | Sponsor Admin |
| Demo2 | Schoolnet Super Admin |
| Demo3 | Schoolnet Project Admin |
| Demo4 | State Admin |
| Demo5 | School Admin |
| Demo6 | Trainer |
| Demo7 | Trainee |
| Demo8 | Reporting/Audit User |

The additional role-based demo accounts use the same password, **`demo1@123`**:

| User ID | Sample name | Role |
| --- | --- | --- |
| Demo9 | Aarav Sharma | School Admin |
| Demo10 | Meera Iyer | School Admin |
| Demo11 | Rohan Kulkarni | Trainer |
| Demo12 | Kavya Nair | Trainer |
| Demo13 | Arjun Reddy | Trainee |

Enter the demo ID and password, select **Sign in**, then **Open local email outbox**.
Copy the six-digit code into the verification field and select **Verify and sign in**.
A JWT is issued only after successful verification. Existing sessions are invalidated
by logout, password reset, account/role changes, or a newer login to the same account.

OTP delivery is a **local email outbox**, as requested. Messages are `.eml` files in
`.local/mail-outbox`; a request-specific link opens the relevant message in the browser.
This viewer requires Development and a loopback connection. Production OTP requests
are disabled until a real email/SMS provider is configured. Codes are not returned in
API JSON. Database challenges contain a keyed hash, an encrypted payload, expiry and
attempt counters. Codes expire after five minutes, are single-use, and lock verification
for 15 minutes after three incorrect attempts. Request throttling also applies.

**Open registration:** use `BATCH-DEMO-NOV`, provide name/contact/category and consent,
request a code, and verify it. The server atomically checks the registration window,
capacity and duplicates, then creates the trainee/account/enrollment and records consent.
New registrations await review on **Registration Requests**. New account details appear
in a separate local email; existing accounts and their passwords are preserved.
The seeded window is 27-Oct to 10-Nov-2026. To test later, edit a batch's dates/window
using an authorized account rather than bypassing server validation.

**Forgot your Trainee ID?** verifies a registered contact through OTP before returning
an ID. **Forgot password?** verifies an account through OTP and allows a new password
of at least ten characters; active sessions are then revoked. Demo IDs retain their
original password.

## Database-backed screens

Projects/phases, reusable training plans and project associations, batches, trainer
profiles/availability, trainees, registrations/approvals, attendance/exclusions,
assessment forms and attempts, feedback, certificate templates/records, holidays,
users, school assignments, learning resources/progress, external-course records,
dashboards and MIS reports use server data. Browser storage retains presentation
preferences and session information; operational records are loaded from PostgreSQL.
Empty collections remain empty instead of producing fabricated report rows.

The seed includes all eight roles, 750 supplied school records, a project with phases,
a reusable plan, past/upcoming batches, a trainer, trainee registrations, attendance,
five learning files, sample forms, certificate templates and Odoo staging examples.
Additional sample plans/trainees created by the browser checks are retained for review.
No mock certificates or completed assessments are invented for trainees.

## Code and database structure

```text
Microservices/UserAPI/      Login, accounts, users, schools, teachers, trainers and trainees
Microservices/BatchAPI/     Batches, plans, attendance, learning, assessments and certificates
Microservices/ReportAPI/    Audits and eligibility/reporting endpoints
Microservices/TeachersAPI/  Retained original teacher CRUD/auth API and maintenance seed tools (port 5104)
JwtAuthenticationManager/ JWT/session validation and ADO.NET SqlHelper
OcelotGateWay/             Gateway routes, authentication and local CORS
DB Scripts/
  Table Creations/        Workbook tables, keys, views and BRD extensions
  Stored Procedures/      All application data operations
Tools/                    Deployment, seed export and development helpers
Tests/                    API, OTP and Chrome integration checks
```

Controllers decrypt AES-GCM requests, deserialize/validate models and return encrypted
`Message<T>` responses. Services create typed Npgsql parameters. `SqlHelper` uses
`CommandType.StoredProcedure`; there are no inline runtime SQL queries in C#.
The 49 workbook table definitions and six workbook views are implemented. Extensions
support reusable plans, phases, associations, sessions, OTP, timed assessment attempts,
attendance exclusions, eligibility and certificate reissue history. Typed keys, dates,
statuses and relationships are stored in relational columns; `ui_data` retains the
existing screen contracts. Email/mobile are encrypted at rest and masked by role.

The server checks role/scope, optimistic row versions, registration rules, attendance
dates, assessment membership, attempt limits, time limits and scores. Certificate
issuance checks completion criteria and uses stored trainee/template data. Resource
bytes live under `.local/resources`; signed links verify session, scope and expiry.

## Database deployment and sample seeding

```powershell
python .\Tools\DeployLocalDatabase.py
node .\Tools\ExportFrontendDemo.cjs
$env:ASPNETCORE_ENVIRONMENT='Development'
$env:PORTAL_DEMO_SOURCE=(Resolve-Path '.local/frontend-demo.json').Path
dotnet run --project .\Microservices\TeachersAPI -- --seed-portal-demo
```

Seeding fills missing demo records and does not overwrite existing demo passwords or
records. Initial database/bootstrap configuration is handled by
`DB Scripts/ConfigureLocalDatabase.py`. Configuration and local test artifacts are ignored.
Use `DB Scripts/GenerateWorkbookSchema.py` only to regenerate the source workbook DDL;
review the separate extension scripts before changing database structures.

## Verification

```powershell
.\Tests\RunLocalChecks.ps1
```

The runner checks encrypted API authorization and persistence, OTP/recovery/reset,
open registration/approval, real Chrome login/navigation, and UI save/reload behavior.
It waits between suites to respect the login rate limit. Chrome/Playwright test support
is installed under `.local/browser-runner`; these packages are test tools only.
`Microservices/TeachersAPI/Tests/SmokeTest.ps1` separately checks the original Teachers
API against an isolated temporary PostgreSQL instance. Results/screenshots are in `.local`.

Local implementation is not a production deployment or a complete BRD acceptance
sign-off. Real OTP delivery and live Odoo/external-course connectors are not configured.
Odoo currently uses local staging, as specified. Certificate issuance follows the
existing administrator screen; a separate trainer-final-approval UI/workflow, advanced
privacy administration and production hosting require their own acceptance/configuration.

Each new project contains Controllers, Services, Models, Utility, Properties,
Program.cs, appsettings.json and its own .csproj, and references JwtAuthenticationManager.
Each builds and runs independently. The existing ADO.NET stored procedures,
AES-GCM, JWT/session checks, response contracts and PostgreSQL database are retained.
Application service/model implementations currently exist in each project; changes
to common workflows must be kept consistent across these copies.

Ocelot routes the existing `/api/{Controller}/*` URLs to the owning service:
UserAPI on 5101, BatchAPI on 5102, ReportAPI on 5103 and TeachersAPI on 5104. It also accepts the
`/api/UserAPI/*`, `/api/BatchAPI/*`, `/api/ReportAPI/*` and `/api/TeacherAPI/*` aliases.
The frontend continues using its existing URLs through port 5100.
`Start-Local.ps1` starts all four services, Ocelot and Vite; `Stop-Local.ps1`
stops the tracked processes. TeachersAPI now runs on port 5104 and is started by the integrated launcher. The service-local ignored settings use the
same database, JWT, transport and PII keys; resource files and the OTP outbox
remain in the backend's shared .local directory.

The refreshed upstream frontend is integrated as described in INTEGRATION-ANALYSIS.md.
After importing an older database, run `python Tools/DeployLocalDatabase.py` to
apply the latest teaching-profile, OTP-verification, rating and batch-code scripts.
The new browser regression can be run with `node Tests/LatestRegistrationBrowser.cjs`.
