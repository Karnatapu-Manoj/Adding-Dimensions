from pathlib import Path
root=Path(__file__).resolve().parent.parent.parent/'Front-End CodeBase'
if 'export let batchRecords' in (root/'src/data/reportData.ts').read_text(encoding='utf-8'):
 print('The dashboard data migration is already applied. No files changed.')
 raise SystemExit(0)

p=root/'src/data/reportData.ts';s=p.read_text();start=s.index('export const batchRecords:');end=s.index('export const isoDate',start)
s=s[:start]+'''export let batchRecords: BatchRecord[] = [];
window.addEventListener('portal:hydrated', event => {
  const detail = (event as CustomEvent).detail;
  const batches = (detail?._dashboard?.batches ?? []) as Record<string, any>[];
  batchRecords = batches.map((row, index) => ({
    index, batch: row.batch, udise: row.udise, school: row.school, state: row.state,
    district: row.district, plan: row.plan, trainer: row.trainer,
    startDate: new Date(`${row.startDate}T00:00:00`), endDate: row.endDate ? new Date(`${row.endDate}T00:00:00`) : null,
    dateText: row.date, capacity: row.capacity, registered: row.registered, attended: row.attended,
    completed: row.completed, attendance: row.attendance,
    status: row.status === 'upcoming' ? 'Scheduled' : row.status === 'completed' ? 'Completed' : 'Ongoing'
  }));
});
''' + s[end:];p.write_text(s)

p=root/'src/reports/Reports.tsx';s=p.read_text();start=s.index('const firstNames =');end=s.index('function AttendanceReport()',start)
s=s[:start]+'''let attendanceRows: AttendanceRow[] = [];
window.addEventListener('portal:hydrated', event => {
  const detail = (event as CustomEvent).detail;
  const batches = (detail?._dashboard?.batches ?? []) as Record<string, any>[];
  attendanceRows = (detail?.['teacher-training-attendance-records'] ?? []).flatMap((mark: Record<string, any>) => {
    const batch = batches.find(item => item.externalId === mark.batchId || item.batch === mark.batchCode);
    if (!batch) return [];
    const date = new Date(`${String(mark.trainingDate).slice(0, 10)}T00:00:00`);
    const present = mark.status === 'Present';
    return [{ batch: batch.batch, batchIndex: batch.index, plan: asPlanLabel(batch.plan), state: batch.state,
      district: batch.district, trainer: batch.trainer, date, dateText: formatDate(date), present,
      totalDays: 1, daysPresent: present ? 1 : 0, attendance: present ? 100 : 0, name: mark.traineeName || mark.traineeId }];
  });
});
''' + s[end:]
if "import { formatDate }" not in s:s="import { formatDate } from '../dateFormat';\n"+s
s=s.replace('750 batch records from the Phasewise Dashboard. UDISE codes and end dates are not provided in that data.','Batch records from the training database using your authorized project scope.')
s=s.replace('Figures use the 750 Phasewise Dashboard batches. Certified trainee data is not provided and is shown as -.','Figures use saved training batches, registrations, attendance, and completion records.')
p.write_text(s)

p=root/'public/legacy-dashboard.js';s=p.read_text();start=s.index('  const batchData=Array.from');end=s.index('  let selectedAudience=',start)
s=s[:start]+"  const batchData=window.PORTAL_DASHBOARD?.batches || [];\n"+s[end:]
start=s.index('  function audienceMetrics(');end=s.index('  const batchModalLayer=',start)
s=s[:start]+'''  function audienceMetrics(batch,audience=selectedAudience){
    if(audience==='Student')return {planned:0,registered:0,approved:0,attended:0,completed:0,certified:0,attendanceRate:0,completionRate:0};
    return {planned:batch.capacity,registered:batch.registered,approved:batch.approved,attended:batch.attended,
      completed:batch.completed,certified:batch.certified,attendanceRate:batch.attendance,completionRate:batch.completion};
  }
''' + s[end:]
s=s.replace("const targetParticipants=selectedAudience==='Teacher'?7500:75000;","const targetParticipants=totals.planned;")
start=s.index('  function participantRowsFor(');end=s.index('  let activeParticipantRows=',start)
s=s[:start]+'''  function participantRowsFor(batch){
    return (batch.participantRows || []).filter(row=>row.type===selectedAudience).map(row=>({...row,
      state:row.status,mobile:row.mobile || '—',email:row.email || '—'}));
  }
''' + s[end:]
s=s.replace('batchData.forEach((batch,index)=>locationSchoolNodes[index]?.assignedBatches.push(batch));',
    'batchData.forEach(batch=>{const index=kgbvSchools.findIndex(school=>school.udise===batch.udise);locationSchoolNodes[index]?.assignedBatches.push(batch);});')
s=s.replace('Location Performance uses the 750 schools listed in KGBV sample school list, Table 1.','Location Performance uses the school master and saved batches in your authorized scope.')
s=s.replace('This demo uses static sample data.','Dashboard data comes from the local training database.').replace('Showing all sample dashboard data.','Showing all authorized dashboard data.')
p.write_text(s)

p=root/'src/components/OpenRegistration.tsx';s=p.read_text();s="import { apiPost } from '../api';\n"+s
start=s.index('    if (!byEmail && !byPhone) await dataStore.setItem');end=s.index('\n  }',start)
s=s[:start]+'''    const formElement = event.currentTarget as HTMLFormElement;
    try {
      const result = await apiPost<{ traineeId: string; message: string }>('Public/Register', {
        batchCode: batch.batchCode || batch.id, name, email, phone, category
      });
      setNotice(`${result.message} Your Trainee ID is ${result.traineeId}.`);
      formElement.reset();
    } catch (reason) { setError(reason instanceof Error ? reason.message : 'Registration could not be saved.'); }
''' + s[end:];p.write_text(s)

p=root/'src/components/RecoverTraineeId.tsx';s=p.read_text();s="import { apiPost } from '../api';\n"+s
s='\n'.join(line for line in s.splitlines() if not line.startswith('const recoveryApi =') and 'if (!recoveryApi) {' not in line)
s=s.replace('if (!recoveryApi || !requestId) return;','if (!requestId) return;')
start=s.index('      const response = await fetch(`${recoveryApi}/request-otp`');end=s.index('      setRequestId(',start)
s=s[:start]+"      const payload = await apiPost<{ requestId: string; message: string }>('Public/RequestRecovery', { contact: contact.trim() });\n"+s[end:]
s=s.replace("setMessage('If a trainee record matches that contact, a verification code has been sent. Enter it below.');","setMessage(payload.message);")
start=s.index('      const response = await fetch(`${recoveryApi}/verify-otp`');end=s.index('      setTraineeId(',start)
s=s[:start]+"      const payload = await apiPost<{ verified: boolean; traineeIds: string[] }>('Public/VerifyRecovery', { requestId, otp: otp.trim() });\n"+s[end:]
s=s.replace('String(payload.traineeId)','String(payload.traineeIds[0])');p.write_text(s+'\n')
print('Connected dashboard, MIS, public registration, and recovery data without changing page layouts.')
