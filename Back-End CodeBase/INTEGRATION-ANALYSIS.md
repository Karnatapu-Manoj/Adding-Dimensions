# Integration status and reference mapping

The refreshed upstream frontend at df60a43 is integrated with Ocelot, UserAPI,
BatchAPI, ReportAPI and TeachersAPI, backed by PostgreSQL.
See README.md for startup, unchanged demo accounts, OTP testing and validation commands.
This document replaces the earlier pre-implementation analysis.

## References used

- `../Reference Documents/design thinking Db and partition.xlsx`: 49 tables and six views.
- `../Reference Documents/Training-Tracker-Business-Requirements v2.docx`.
- `../Reference Documents/Queries and responses.docx`.
- `../Reference Documents/Adding Dimensions Dashboard Screen.png`.
- Existing frontend components and `../Front-End CodeBase/USER_MANUAL.md`.
- Existing NISM Sync controller/service, AES-GCM and response conventions.

No `user.md` file was found; the frontend's supplied role guide is `USER_MANUAL.md`.
Its eight roles and Demo1 through Demo8 credentials were retained.
The additional Demo9 through Demo13 accounts are also retained.

## Refreshed frontend integration (29 October 2026)

The upstream menu visibility, learning-library Forms tab, report chart/table views,
assessment form detail views, expanded registration layout and new batch identity
helpers are retained. Operational browser storage has been replaced with the API
data adapter; local storage holds only theme/session presentation information.
Initial loading retrieves the authorized workspace from UserAPI and dashboard/report
data from ReportAPI. Saves are awaited and database errors are shown to the user.

| Gateway prefix | Process | Port | Responsibility |
| --- | --- | --- | --- |
| /api/UserAPI | UserAPI | 5101 | Login/OTP, registration, users, schools, trainers, trainees, workspace |
| /api/BatchAPI | BatchAPI | 5102 | Plans, batches, attendance, learning resources, forms, certificates |
| /api/ReportAPI | ReportAPI | 5103 | Dashboard aggregates, report data, audits and eligibility |
| /api/TeacherAPI or /api/TeachersAPI | TeachersAPI | 5104 | Original teacher CRUD and original teacher authentication |

The browser uses only the Ocelot origin (localhost:5100); src/api.ts selects each
service prefix. Existing unprefixed gateway URLs remain available.

The expanded registration requires school, geography, gender, designation, classes,
subjects and teaching experience. UserAPI validates school membership and allowed
options, binds the profile to the encrypted OTP challenge, checks the code without
consuming it at the Verify step, then consumes it once at Accept & Submit.
Consent and batch capacity/window checks remain mandatory. Codes use the local
outbox; no fixed 123456 demo code is accepted. Typed trainee columns are added by
231_TraineeTeachingProfile.sql; 130_PortalPublic.sql persists those columns and
155_RegistrationVerification.sql supplies verification and batch-code migration.
The migration preserves previous batch codes as aliases so existing links still work.
The supplied Digital Teaching Pre-assessment and Teacher Training Feedback Form
definitions are imported through the backend seeder. Source sample submissions
are not imported as actual trainee results.

Feedback ratings are computed by the server from saved form options and stored
separately from assessment grades. Dashboard attendance uses saved marks rather
than the upstream hard-coded KPI. Certificate numbers are reserved under a database
transaction lock against all historical rows to prevent duplicate-number conflicts.

For an existing imported database, apply the latest source scripts using
`python Tools/DeployLocalDatabase.py` before starting the services.

Validation for this refresh: the solution builds with zero warnings/errors; the
frontend production build passes (Vite reports its existing large-bundle advisory).
The API regression passes 76 checks. Headless Google Chrome checks pass across 44
screens and 144 API responses for eight original roles. Separate browser checks
cover expanded registration/profile persistence, OTP verification/replay protection,
server-bound profile fields, four service routes, and the refreshed Forms tab.
Current evidence is in `.local/api-test-result.json`, `.local/browser-test-result.json`,
`.local/latest-registration-result.json` and `.local/latest-learning-result.json`.

## Delivered local flows

| Area | Server and database behavior |
| --- | --- |
| Authentication | Password verification, email-outbox OTP, single-use challenge, session JWT, logout, recovery and password reset |
| Role access | Eight database roles, collection permissions, project/geo/assigned-trainer scope, trainee ownership |
| Projects/plans/batches | Persisted CRUD, phases, reusable-plan associations, schedule and holiday validation |
| Registration | OTP-bound details, consent, duplicate/contact checks, capacity/window validation, account creation, review/approval |
| Attendance | Approved membership, scheduled dates, no future marking, amendment validation, exclusions and auditing |
| Assessments/feedback | Stored forms/questions, server start time, attempt limits, server scoring and non-graded feedback |
| Certificates | Stored templates, server completion checks, canonical trainee/template snapshots, reissue/revocation history |
| Resources | Stored metadata/files, session-scoped signed download links and access records |
| Dashboards/reports | Relational batch/enrollment/attendance/completion aggregates; no generated fake participant report rows |

Normalized workbook tables carry operational fields and relationships. Additional
presentation fields and external frontend IDs are retained alongside them; the
application is not persisted as one browser-state blob. All runtime C# database access
uses ADO.NET stored-procedure calls. Table and procedure scripts remain in separate folders.

## Decisions and boundaries

The latest user request enables login and open-registration OTP, superseding the earlier
instruction to defer OTP. Local email-outbox delivery was explicitly selected. Codes
expire in five minutes, permit three attempts, and lock the contact for 15 minutes after
three incorrect codes. Demo passwords remain unchanged and cannot be reset through the UI.

The frontend accepts one or more training days; this behavior is retained despite the
workbook's four-day remark. Plans are reusable without a mandatory project_id, per BRD v2.
Open registrations remain pending review to match the existing Registration Requests UI.

This is a local integrated build. A real OTP provider and production hosting are not
configured. Odoo/external courses use local staging/manual records. The current certificate
screen authorizes administrators to issue certificates; separate trainer-final approval,
advanced configurable PII exceptions/administration, and full production BRD acceptance
remain outside the implemented frontend-backed workflow. Do not represent local automated
checks as acceptance of every business requirement.

Automated results and screenshots are saved under `.local`; README lists the suites.
