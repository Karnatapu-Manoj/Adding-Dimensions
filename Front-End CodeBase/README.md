# ERNet Dashboard (React)

React + TypeScript + MUI recreation of the Phasewise Dashboard, Content Library, and MIS Reports.

## Local API integration

Requests use Ocelot at `http://localhost:5100`. `src/api.ts` selects UserAPI (5101),
BatchAPI (5102), ReportAPI (5103), or the original TeachersAPI (5104).
Operational data comes from PostgreSQL. OTP delivery uses the local email outbox.

After configuring the backend database and installing frontend packages with
`npm ci`, start the integrated application from the sibling backend directory:

```powershell
cd '..\Back-End CodeBase'
.\Start-Local.ps1
```

Open `http://localhost:5173/TeacherTraining/login`. The launcher generates the
matching ignored `.env.local` settings. Backend setup and Demo1–Demo13 credentials
are documented in the backend README. The refreshed design, menus and folder
structure are retained. Integrated mode loads database records rather than browser
demo seeds; supplied form definitions are imported through the backend seeder.

The app uses the shared sidebar, topbar, and footer. MIS report pages share the `ReportTable` and `ReportFilterPanel` components, while retaining their report-specific columns, filters, dialogs, and pagination.

## Routes

- `/login` — ERNet sign-in screen
- `/holiday-master` — Holiday calendar and access administration (Demo1 administrator)
- `/` — Phasewise dashboard
- `/content-library` — Content Library
- `/reports/batch-performance` — Batch Performance
- `/reports/training-summary` — Training Summary
- `/reports/attendance-report` — Attendance Report

## Development

- `npm install` — install dependencies
- `npm run dev` — start the Vite development server
- `npm run build` — type-check and build the production bundle
- `npm run preview` — serve the production bundle locally

Set `VITE_BUSINESS_TIME_ZONE` to an IANA time zone (for example, `Asia/Kolkata`) to define the business date used by daily attendance. The attendance page defaults to `Asia/Kolkata` when the variable is not set.
