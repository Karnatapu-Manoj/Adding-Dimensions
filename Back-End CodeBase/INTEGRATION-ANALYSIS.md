# Integration status and reference mapping

The local React -> Ocelot -> TeachersAPI -> PostgreSQL integration is implemented.
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
