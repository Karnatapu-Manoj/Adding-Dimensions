
  const infoPopup=document.querySelector('#info-popup');
  document.querySelectorAll('.kpi').forEach(card=>{
    const label=card.querySelector('.kpi-label')?.textContent.trim();
    if(['Upcoming Batches','Active Batches','Completed Batches'].includes(label))card.classList.add('kpi-hidden');
  });
  let activeInfoButton=null;
  function showInfo(button){
    activeInfoButton=button;
    document.querySelector('#info-popup-title').textContent=button.dataset.infoTitle;
    document.querySelector('#info-popup-text').textContent=button.dataset.info;
    infoPopup.hidden=false;
    const rect=button.getBoundingClientRect();
    const popupRect=infoPopup.getBoundingClientRect();
    const left=Math.max(12,Math.min(rect.right-popupRect.width,window.innerWidth-popupRect.width-12));
    let top=rect.bottom+8;
    if(top+popupRect.height>window.innerHeight-12)top=rect.top-popupRect.height-8;
    infoPopup.style.left=`${left}px`;infoPopup.style.top=`${Math.max(12,top)}px`;
  }
  function hideInfo(button){if(activeInfoButton===button){infoPopup.hidden=true;activeInfoButton=null}}
  document.querySelectorAll('.info-button').forEach(button=>{
    button.addEventListener('mouseenter',()=>showInfo(button));
    button.addEventListener('mouseleave',()=>hideInfo(button));
    button.addEventListener('focus',()=>showInfo(button));
    button.addEventListener('blur',()=>hideInfo(button));
  });
  window.addEventListener('scroll',()=>{infoPopup.hidden=true;activeInfoButton=null},{passive:true});
  const toast = document.querySelector('#toast');
  let toastTimer;
  function showToast(text){toast.textContent=text;toast.classList.add('show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>toast.classList.remove('show'),2800)}

  document.querySelectorAll('.side-link').forEach(link=>link.addEventListener('click',()=>{
    document.querySelectorAll('.side-link').forEach(item=>{item.classList.remove('active');item.removeAttribute('aria-current')});
    link.classList.add('active');link.setAttribute('aria-current','page');
  }));

  document.querySelectorAll('.filter select').forEach(select=>select.addEventListener('change',()=>{
    const count=[...document.querySelectorAll('.filter select')].filter(item=>item.selectedIndex>0).length;
    const badge=document.querySelector('#filter-count');badge.textContent=count;badge.classList.toggle('visible',count>0);
    showToast(count ? `${count} filter${count===1?'':'s'} selected. Dashboard data comes from the local training database.` : 'Showing all authorized dashboard data.');
  }));

  const filterTrigger=document.querySelector('#filter-trigger');
  const filterPopover=document.querySelector('#filter-popover');
  filterTrigger.addEventListener('click',()=>{
    const open=filterTrigger.getAttribute('aria-expanded')==='true';
    filterTrigger.setAttribute('aria-expanded',String(!open));filterPopover.classList.toggle('open',!open);
  });
  document.addEventListener('click',event=>{
    if(!event.target.closest('.filter-control')){filterTrigger.setAttribute('aria-expanded','false');filterPopover.classList.remove('open')}
  });
  document.addEventListener('keydown',event=>{
    if(event.key==='Escape'){filterTrigger.setAttribute('aria-expanded','false');filterPopover.classList.remove('open');filterTrigger.focus()}
  });
  document.querySelector('#clear-filters').addEventListener('click',()=>{
    document.querySelectorAll('.filter select').forEach(select=>{select.selectedIndex=0});
    const badge=document.querySelector('#filter-count');badge.textContent='0';badge.classList.remove('visible');showToast('Filters cleared.');
  });
  const batchStatusLabels={upcoming:'Upcoming',ongoing:'Ongoing',completed:'Completed'};
  const kgbvSchools=Array.isArray(window.KGBV_SCHOOLS)?window.KGBV_SCHOOLS:[];
  const batchPhases=['Orientation','Device & Content Use','Digital Skills','Refresher I','Refresher II'];
  const batchTrainers=['Asha Reddy','Ravi Kumar','Meera Nair','Suresh Rao','Kavitha Devi','Arun Das','Neha Sharma','Vikram Singh','Farah Khan','Joseph Mathew','Pooja Iyer','Mohan Das'];
  const escapeHtml=value=>String(value??'').replace(/[&<>"']/g,character=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[character]));
  const displaySafe=value=>typeof value==='string'?escapeHtml(value):Array.isArray(value)?value.map(displaySafe):value&&typeof value==='object'?Object.fromEntries(Object.entries(value).map(([key,item])=>[key,displaySafe(item)])):value;
  const batchData=(window.PORTAL_DASHBOARD?.batches || []).map(displaySafe);
  const phases=window.PORTAL_DASHBOARD?.phases || [];
  document.querySelectorAll('.phase-card').forEach((card,index)=>{
    const phase=phases[index];
    card.classList.remove('completed','current','upcoming');
    card.classList.add(phase?.status==='Completed'?'completed':phase?.status==='In Progress'?'current':'upcoming');
    card.querySelector('h3').textContent=phase?.name || 'No phase configured';
    card.querySelector('.phase-status').textContent=phase?.status || 'Not configured';
    const facts=card.querySelectorAll('.phase-fact span');
    if(facts[0])facts[0].textContent=phase?`${phase.startDate} to ${phase.endDate}`:'';
    if(facts[1])facts[1].textContent='';
    if(!phase){card.setAttribute('aria-disabled','true');card.tabIndex=-1;}
  });
  const filterFields={project:'project',state:'state',district:'district',school:'school',plan:'plan',batch:'id'};
  for(const [id,field] of Object.entries(filterFields)){
    const select=document.querySelector(`#${id}`);if(!select)continue;
    const label=select.options[0]?.textContent || 'All';select.replaceChildren(new Option(label,''));
    for(const value of [...new Set(batchData.map(batch=>batch[field]).filter(Boolean))].sort()){
      const option=new Option(value,value);select.add(option);
    }
  }
  const range=document.querySelector('#date-range');
  if(range){range.replaceChildren(new Option('All dates',''),new Option('This month','month'),new Option('This year','year'));}

  let selectedAudience=document.querySelector('.audience-button[aria-pressed="true"]')?.dataset.audience||'Student';
  const currentPhaseCard=document.querySelector('.phase-card.current');
  let selectedPhase=null;
  document.querySelectorAll('.phase-card, .student-module-card').forEach(card=>{
    const isCurrent=false;
    card.classList.toggle('selected',isCurrent);
    card.setAttribute('aria-pressed',String(isCurrent));
  });
  const studentModuleNames=['Cyber Safety and Digital Responsibility','Digital Creativity','AI Awareness'];
  const selectedPhaseLabel=()=>selectedPhase?(selectedAudience==='Student'?studentModuleNames[selectedPhase-1]:`Phase ${selectedPhase}: ${phases.find(phase=>phase.number===selectedPhase)?.name||batchPhases[selectedPhase-1]}`):'';
  const dashboardBatches=()=>batchData.filter(batch=>{
    if(selectedPhase && batch.phaseNumber!==selectedPhase)return false;
    for(const [id,field] of Object.entries(filterFields)){
      const value=document.querySelector(`#${id}`)?.value;if(value && batch[field]!==value)return false;
    }
    const period=range?.value,now=new Date(),date=new Date(batch.startDate);
    return !period || date.getFullYear()===now.getFullYear() && (period!=='month' || date.getMonth()===now.getMonth());
  });
  const audienceSize=(batch,audience=selectedAudience)=>audienceMetrics(batch,audience).registered;
  function audienceMetrics(batch,audience=selectedAudience){
    return (audience==='Student'?batch.studentMetrics:batch.teacherMetrics) || {planned:0,registered:0,approved:0,attended:0,completed:0,certified:0,attendanceRate:0,completionRate:0};
  }
  const batchModalLayer=document.querySelector('#batch-modal-layer');
  const participantModalLayer=document.querySelector('#participant-modal-layer');
  const batchModalList=document.querySelector('#batch-modal-list');
  const participantList=document.querySelector('#participant-list');
  const batchPageSize=24;
  let activeBatchStatus='upcoming',batchPage=1,activeStatusTrigger=null,activeBatchTrigger=null,selectedBatch=null;
  function renderBatchStatusTotals(){
    const batchesInView=dashboardBatches();
    const phaseContext=selectedPhase?` for ${selectedPhaseLabel()}`:'';
    const totals=batchesInView.reduce((sum,batch)=>{const m=audienceMetrics(batch);for(const key of Object.keys(sum))sum[key]+=m[key];return sum},{planned:0,registered:0,approved:0,attended:0,completed:0,certified:0});
    const totalParticipants=totals.planned,totalAttended=totals.attended,totalCompleted=totals.completed;
    const completionPercent=totalParticipants?totalCompleted/totalParticipants*100:0;
    const marked=batchesInView.reduce((sum,batch)=>sum+(audienceMetrics(batch).attendanceMarked||0),0);
    const present=batchesInView.reduce((sum,batch)=>sum+(audienceMetrics(batch).attendancePresent||0),0);
    const attendancePercent=marked?100*present/marked:0;
    const batchStatusSummaries={};
    for(const status of Object.keys(batchStatusLabels)){
      const matchingBatches=batchesInView.filter(batch=>batch.status===status);
      const participantCount=matchingBatches.reduce((sum,batch)=>sum+audienceSize(batch),0);
      const batchPercent=batchesInView.length?matchingBatches.length/batchesInView.length*100:0;
      document.querySelector(`[data-status-count="${status}"]`).textContent=`${matchingBatches.length.toLocaleString('en-IN')} (${batchPercent.toFixed(0)}%)`;
      document.querySelector(`[data-participant-total="${status}"]`).textContent=`${participantCount.toLocaleString('en-IN')} participants`;
      batchStatusSummaries[status]=`${participantCount.toLocaleString('en-IN')} participants`;
    }
    function updateKpi(label,value,sub){
      const card=[...document.querySelectorAll('.kpi')].find(item=>item.querySelector('.kpi-label')?.textContent.trim()===label);
      if(!card)return;
      card.querySelector('.kpi-value').textContent=value;
      if(sub!==null){const element=card.querySelector('.kpi-sub');if(element){element.textContent=sub;element.classList.toggle('target-breakdown',label==='Target Participants');element.classList.toggle('batch-breakdown',['Active Batches','Completed Batches','Upcoming Batches'].includes(label))}}
    }
    const trainedText=totalCompleted.toLocaleString('en-IN');
    const targetParticipants=totals.planned;
    const formattedTarget=targetParticipants.toLocaleString('en-IN');
    updateKpi('Training Progress',`${completionPercent.toFixed(1)}%`,null);
    document.querySelector('.kpi-sub .meter span').style.width=`${completionPercent}%`;
    updateKpi('Target Participants',formattedTarget,`${selectedAudience} target`);
    updateKpi('Participants Registered',totals.registered.toLocaleString('en-IN'),'Registered participants');
    updateKpi('Participants Trained',trainedText,`${completionPercent.toFixed(1)}% of target`);
    updateKpi('Attendance Rate',attendancePercent.toFixed(1)+'%','Attendance');
    // Batch counts are shown in the Batch Status panel instead of the KPI row.
    const progressValues={planned:totals.planned,registered:totals.registered,approved:totals.approved,attended:totals.attended,completed:totals.completed,certified:totals.certified};
    document.querySelectorAll('#training-progress .progress-row').forEach(row=>{
      const stage=row.firstElementChild.textContent.trim().toLowerCase(),value=progressValues[stage],percent=totalParticipants?value/totalParticipants*100:0;
      const fill=row.querySelector('.progress-fill');if(fill)fill.style.width=`${percent}%`;
      row.querySelector('.progress-value').innerHTML=`${value.toLocaleString('en-IN')} <span>(${percent.toFixed(1)}%)</span>`;
    });
    const targetChart=document.querySelector('#target-trained .v-chart');
    const chartValues=targetChart.querySelectorAll('.chart-value'),trainedRatio=targetParticipants?Math.min(1,totalCompleted/targetParticipants):0;
    chartValues[0].textContent=formattedTarget;chartValues[1].textContent=trainedText;
    targetChart.setAttribute('aria-label',`Bar chart comparing the target of ${formattedTarget} ${selectedAudience.toLowerCase()} with ${trainedText} participants trained`);
    const bars=targetChart.querySelectorAll('rect'),trainedHeight=140*trainedRatio;
    bars[0].setAttribute('y','24');bars[0].setAttribute('height','140');bars[1].setAttribute('y',String(164-trainedHeight));bars[1].setAttribute('height',String(trainedHeight));
    chartValues[0].setAttribute('y','17');chartValues[1].setAttribute('y',String(157-trainedHeight));
    const tickLabels=targetChart.querySelectorAll('g.chart-label')[0]?.querySelectorAll('text')??[];
    tickLabels.forEach((tick,index)=>tick.textContent=(targetParticipants*index/5).toLocaleString('en-IN'));
    const achievement=targetChart.closest('.target-layout').querySelector('.donut-center');
    achievement.textContent=`${completionPercent.toFixed(1)}%`;
    const donutCircles=targetChart.closest('.target-layout').querySelectorAll('.donut circle');
    const arc=2.827*completionPercent;donutCircles[1].setAttribute('stroke-dasharray',`${arc} ${282.7-arc}`);donutCircles[2].setAttribute('stroke-dasharray',`${282.7-arc} ${arc}`);donutCircles[2].setAttribute('stroke-dashoffset',String(-arc));
    const donut=targetChart.closest('.target-layout').querySelector('.donut');
    donut.setAttribute('aria-label',`${selectedAudience} achievement ${completionPercent.toFixed(1)} percent`);
    renderAudienceAttendance(attendancePercent);
  }
  function renderAudienceAttendance(attendancePercent){
    const svg=document.querySelector('#attendance .line-chart'),daily=new Map();
    for(const batch of dashboardBatches())for(const day of batch.attendanceDays||[]){
      if(day.audience!==selectedAudience)continue;
      const total=daily.get(day.date)||{marked:0,present:0};
      total.marked+=Number(day.marked);total.present+=Number(day.present);daily.set(day.date,total);
    }
    const days=[...daily.entries()].sort(([a],[b])=>a.localeCompare(b)).slice(-4);
    const dots=svg.querySelector('[data-attendance-dots]')||svg.querySelector('.line-dot')?.parentElement;
    dots.setAttribute('data-attendance-dots','');dots.replaceChildren();
    const values=svg.querySelector('.line-value'),labels=svg.querySelector('.line-label');values.replaceChildren();labels.replaceChildren();
    const points=days.map(([date,total],index)=>({date,rate:total.marked?100*total.present/total.marked:0,x:days.length===1?178:50+256*index/(days.length-1)}));
    const create=(tag,attributes,text)=>{const element=document.createElementNS('http://www.w3.org/2000/svg',tag);for(const [key,value] of Object.entries(attributes))element.setAttribute(key,String(value));if(text!==undefined)element.textContent=text;return element;};
    const coords=points.map(point=>`${point.x} ${145-point.rate*1.2}`);
    svg.querySelector('.line-path').setAttribute('d',points.length?'M'+coords.join(' L'):'');
    svg.querySelector('.line-area').setAttribute('d',points.length?`M${coords.join(' L')} L${points.at(-1).x} 145 H${points[0].x} Z`:'');
    for(const point of points){
      dots.append(create('circle',{class:'line-dot',cx:point.x,cy:145-point.rate*1.2,r:5}));
      values.append(create('text',{x:point.x,y:135-point.rate*1.2},`${point.rate.toFixed(1)}%`));
      labels.append(create('text',{x:point.x,y:164},new Date(point.date+'T00:00:00').toLocaleDateString('en-GB',{day:'2-digit',month:'short'})));
    }
    let empty=svg.querySelector('[data-attendance-empty]');
    if(!empty){empty=create('text',{'data-attendance-empty':'',x:178,y:85,'text-anchor':'middle',class:'chart-label'},'No attendance recorded');svg.append(empty);}
    empty.style.display=points.length?'none':'';
    svg.setAttribute('aria-label',`${selectedAudience} saved daily attendance, ${attendancePercent.toFixed(1)} percent overall`);
    document.querySelector('#attendance .panel-title').lastChild.textContent='Attendance Trend';
  }
  function renderBatchModal(){
    const search=document.querySelector('#batch-search').value.trim().toLocaleLowerCase();
    const matches=dashboardBatches().filter(batch=>batch.status===activeBatchStatus&&(!search||`${batch.id} ${batch.phase} ${batch.location} ${batch.school} ${batch.trainer}`.toLocaleLowerCase().includes(search)));
    const pageCount=Math.max(1,Math.ceil(matches.length/batchPageSize));batchPage=Math.min(batchPage,pageCount);
    const start=(batchPage-1)*batchPageSize,visible=matches.slice(start,start+batchPageSize);
    document.querySelector('#batch-modal-title').textContent=`${selectedPhase?`${selectedPhaseLabel()} · `:''}${batchStatusLabels[activeBatchStatus]} batches`;
    document.querySelector('#batch-modal-summary').textContent=`${matches.length.toLocaleString('en-IN')} assigned batches · ${matches.reduce((sum,batch)=>sum+audienceSize(batch),0).toLocaleString('en-IN')} participants`;
    document.querySelector('#batch-page-info').textContent=matches.length?`Showing ${(start+1).toLocaleString('en-IN')}–${Math.min(start+batchPageSize,matches.length).toLocaleString('en-IN')} of ${matches.length.toLocaleString('en-IN')} batches · Page ${batchPage} of ${pageCount}`:'No matching batches';
    document.querySelector('#batch-page-prev').disabled=batchPage<=1;
    document.querySelector('#batch-page-next').disabled=batchPage>=pageCount;
    batchModalList.innerHTML=visible.length?visible.map(batch=>`<button class="modal-batch-item" type="button" data-batch-index="${batch.index}" aria-label="Open participants for ${batch.id}, ${audienceSize(batch)} participants"><span class="modal-batch-main"><span class="modal-batch-id">${batch.id}<span class="modal-status-tag ${batch.status}">${batchStatusLabels[batch.status]}</span></span><span class="modal-batch-location">${batch.school} · ${batch.location}</span><span class="batch-modal-breakdown">Trainer Name: ${batch.trainer} · Batch Start Date: ${batch.date}</span></span><span class="modal-batch-stats"><strong>${audienceSize(batch).toLocaleString('en-IN')}</strong><span>participants</span></span></button>`).join(''):'<div class="modal-empty">No batches match your search. Try a batch ID, school, location, or trainer.</div>';
  }
  function openBatchModal(status,trigger){
    activeBatchStatus=status;activeStatusTrigger=trigger;batchPage=1;
    document.querySelector('#batch-search').value='';renderBatchModal();batchModalLayer.hidden=false;
    document.body.style.overflow='hidden';document.querySelector('#batch-search').focus();
  }
  function closeParticipantModal(restoreFocus=true){
    participantModalLayer.hidden=true;selectedBatch=null;
    if(restoreFocus&&activeBatchTrigger?.isConnected)activeBatchTrigger.focus();
  }
  function closeBatchModal(){
    participantModalLayer.hidden=true;batchModalLayer.hidden=true;selectedBatch=null;document.body.style.overflow='';
    if(activeStatusTrigger?.isConnected)activeStatusTrigger.focus();
  }
  function participantRowsFor(batch){
    return (batch.participantRows || []).filter(row=>row.type===selectedAudience).map(row=>({...row,
      state:row.status,mobile:row.mobile || '—',email:row.email || '—'}));
  }
  let activeParticipantRows=[];
  function renderParticipantList(){
    const search=document.querySelector('#participant-search').value.trim().toLocaleLowerCase();
    const matches=activeParticipantRows.filter(row=>`${row.name} ${row.id} ${row.school} ${row.state}`.toLocaleLowerCase().includes(search));
    document.querySelector('#participant-filter-count').textContent=`${matches.length} of ${activeParticipantRows.length} participants`;
    participantList.innerHTML=matches.length?matches.map(row=>`<div class="participant-row"><div class="participant-details"><span class="participant-name">${row.name}</span><span class="participant-id">${row.id}</span><div class="participant-contact"><span>Mobile Number: ${row.mobile}</span><span>Email ID: ${row.email}</span></div></div><span class="participant-school">${row.school}</span><span class="participant-state ${row.state==='Completed'?'done':row.state==='Registration pending'||row.state==='Needs follow-up'?'pending':''}">${row.state}</span></div>`).join(''):'<div class="modal-empty">No participants match your search.</div>';
  }
  function openParticipantModal(batch,trigger){
    selectedBatch=batch;activeBatchTrigger=trigger;activeParticipantRows=participantRowsFor(batch);
    document.querySelector('#participant-modal-title').textContent=`Phase ${batch.phaseNumber} · ${batch.id} participants`;
    document.querySelector('#participant-modal-summary').textContent=`Phase ${batch.phaseNumber}: ${batch.phase} · ${batch.school} · ${batch.location} · ${selectedAudience} participants · Trainer ${batch.trainer}`;
    document.querySelector('#participant-search').value='';
    renderParticipantList();participantModalLayer.hidden=false;document.querySelector('#participant-search').focus();
  }
  document.querySelectorAll('[data-batch-status]').forEach(button=>button.addEventListener('click',()=>openBatchModal(button.dataset.batchStatus,button)));
  document.querySelector('#batch-search').addEventListener('input',()=>{batchPage=1;renderBatchModal()});
  document.querySelector('#participant-search').addEventListener('input',renderParticipantList);
  document.querySelector('#batch-page-prev').addEventListener('click',()=>{batchPage--;renderBatchModal()});
  document.querySelector('#batch-page-next').addEventListener('click',()=>{batchPage++;renderBatchModal()});
  batchModalList.addEventListener('click',event=>{
    const button=event.target.closest('[data-batch-index]');if(!button)return;
    const batch=batchData[Number(button.dataset.batchIndex)];openParticipantModal(batch,button);
  });
  document.querySelectorAll('[data-close-batch-modal]').forEach(button=>button.addEventListener('click',closeBatchModal));
  document.querySelectorAll('[data-close-participant-modal]').forEach(button=>button.addEventListener('click',()=>closeParticipantModal()));
  document.querySelector('#participant-back').addEventListener('click',()=>closeParticipantModal());
  batchModalLayer.addEventListener('click',event=>{if(event.target===batchModalLayer)closeBatchModal()});
  participantModalLayer.addEventListener('click',event=>{if(event.target===participantModalLayer)closeParticipantModal()});
  document.addEventListener('keydown',event=>{
    const layer=participantModalLayer.hidden?(batchModalLayer.hidden?null:batchModalLayer):participantModalLayer;
    if(!layer)return;
    if(event.key==='Escape'){event.preventDefault();event.stopImmediatePropagation();if(layer===participantModalLayer)closeParticipantModal();else closeBatchModal();return}
    if(event.key==='Tab'){
      const focusable=[...layer.querySelectorAll('button:not(:disabled),input:not(:disabled)')];
      if(!focusable.length)return;
      const first=focusable[0],last=focusable[focusable.length-1];
      if(event.shiftKey&&document.activeElement===first){event.preventDefault();last.focus()}
      else if(!event.shiftKey&&document.activeElement===last){event.preventDefault();first.focus()}
    }
  },true);
  renderBatchStatusTotals();

  const makeLocationNode=name=>({name,children:[],assignedBatches:[]});
  const getOrCreateLocationNode=(parent,name)=>{
    let node=parent.find(item=>item.name===name);
    if(!node){node=makeLocationNode(name);parent.push(node)}
    return node;
  };
  const locationTree=[],locationSchoolNodes=[];
  kgbvSchools.forEach(sourceSchool=>{
    const stateNode=getOrCreateLocationNode(locationTree,sourceSchool.state);
    const districtNode=getOrCreateLocationNode(stateNode.children,sourceSchool.district);
    const blockNode=getOrCreateLocationNode(districtNode.children,sourceSchool.block);
    locationSchoolNodes.push(getOrCreateLocationNode(blockNode.children,sourceSchool.school));
  });
  document.querySelector('#locations .info-button').dataset.info='Location Performance uses the school master and saved batches in your authorized scope. Click State, District, or Block rows to drill down to schools.';
  batchData.forEach(batch=>{const index=kgbvSchools.findIndex(school=>school.udise===batch.udise);locationSchoolNodes[index]?.assignedBatches.push(batch);});
  function locationTotals(node){
    if(!node.children.length){
      const batches=node.assignedBatches.filter(batch=>!selectedPhase||batch.phaseNumber===selectedPhase),completedBatches=batches.filter(batch=>batch.status==='completed').length;
      const metrics=batches.reduce((sum,batch)=>{const current=audienceMetrics(batch);for(const key of ['planned','registered','completed'])sum[key]+=current[key];return sum},{planned:0,registered:0,completed:0});
      return {batches:batches.length,scheduled:batches.filter(batch=>batch.status==='upcoming').length,ongoing:batches.filter(batch=>batch.status==='ongoing').length,completedBatches,plannedUsers:metrics.planned,registeredUsers:metrics.registered,completedUsers:metrics.completed};
    }
    return node.children.map(locationTotals).reduce((sum,item)=>({batches:sum.batches+item.batches,scheduled:sum.scheduled+item.scheduled,ongoing:sum.ongoing+item.ongoing,completedBatches:sum.completedBatches+item.completedBatches,plannedUsers:sum.plannedUsers+item.plannedUsers,registeredUsers:sum.registeredUsers+item.registeredUsers,completedUsers:sum.completedUsers+item.completedUsers}),{batches:0,scheduled:0,ongoing:0,completedBatches:0,plannedUsers:0,registeredUsers:0,completedUsers:0});
  }
  let locationPath=[];
  let locationSortDirection='desc';
  let locationSortKey='completedPercent';
  const locationRows=document.querySelector('#location-rows'),locationSortBy=document.querySelector('#location-sort-by'),locationLabels=['State','District','Block','School'];
  function renderLocations(){
    const level=locationPath.length,nodes=level===0?locationTree:locationPath[level-1].children;
    document.querySelector('#location-level-heading').textContent=locationLabels[level];
    document.querySelector('#location-note').textContent=`${selectedAudience==='Teacher'?'Teachers':'Students'}, ${selectedPhaseLabel()||'all phases'}`;
    const breadcrumb=document.querySelector('#location-breadcrumb');
    const crumbs=[{label:'All states',index:0},...locationPath.map((node,index)=>({label:node.name,index:index+1}))];
    breadcrumb.innerHTML=crumbs.map((crumb,index)=>`<li><button type="button" class="location-crumb" data-crumb-depth="${crumb.index}" ${index===crumbs.length-1?'aria-current="page"':''}>${crumb.label}</button></li>`).join('');
    const meter=(percent,tone='')=>`<span class="cell-meter"><span class="meter ${tone}"><span style="width:${percent.toFixed(1)}%"></span></span><b>${percent.toFixed(1)}%</b></span>`;
    const sortedNodes=nodes.map((node,index)=>{
      const stats=locationTotals(node),batchCompletionPercent=stats.batches?stats.completedBatches/stats.batches*100:0,completedPercent=stats.plannedUsers?stats.completedUsers/stats.plannedUsers*100:0;
      const sortValue=locationSortKey==='batchCompletionPercent'?batchCompletionPercent:locationSortKey==='completedPercent'?completedPercent:stats[locationSortKey];
      return {node,index,stats,batchCompletionPercent,completedPercent,sortValue};
    }).sort((a,b)=>{
      if(locationSortKey==='state')return locationSortDirection==='asc'?a.node.name.localeCompare(b.node.name):b.node.name.localeCompare(a.node.name);
      return locationSortDirection==='asc'?a.sortValue-b.sortValue||a.node.name.localeCompare(b.node.name):b.sortValue-a.sortValue||a.node.name.localeCompare(b.node.name);
    });
    locationRows.innerHTML=sortedNodes.map(({node,index,stats,batchCompletionPercent,completedPercent})=>{
      const name=level<3?`<button type="button" class="location-name-button" data-location-index="${index}" aria-label="Show ${locationLabels[level+1]} locations for ${node.name}">${node.name}</button>`:node.name;
      return `<tr><td>${name}</td><td>${stats.scheduled.toLocaleString('en-IN')}</td><td>${stats.ongoing.toLocaleString('en-IN')}</td><td>${stats.completedBatches.toLocaleString('en-IN')}</td><td>${meter(batchCompletionPercent)}</td><td>${stats.plannedUsers.toLocaleString('en-IN')}</td><td>${stats.registeredUsers.toLocaleString('en-IN')}</td><td>${stats.completedUsers.toLocaleString('en-IN')}</td><td>${meter(completedPercent,'orange')}</td></tr>`;
    }).join('');
  }
  document.querySelectorAll('[data-location-sort]').forEach(button=>button.addEventListener('click',()=>{
    locationSortDirection=button.dataset.locationSort;
    document.querySelectorAll('[data-location-sort]').forEach(toggle=>toggle.setAttribute('aria-pressed',String(toggle===button)));
    renderLocations();
  }));
  locationSortBy.addEventListener('change',()=>{locationSortKey=locationSortBy.value;renderLocations()});
  locationRows.addEventListener('click',event=>{
    const button=event.target.closest('[data-location-index]');if(!button)return;
    const nodes=locationPath.length?locationPath[locationPath.length-1].children:locationTree;
    locationPath.push(nodes[Number(button.dataset.locationIndex)]);renderLocations();
  });
  document.querySelector('#location-breadcrumb').addEventListener('click',event=>{
    const button=event.target.closest('[data-crumb-depth]');if(!button||button.getAttribute('aria-current')==='page')return;
    locationPath=locationPath.slice(0,Number(button.dataset.crumbDepth));renderLocations();
  });
  document.querySelectorAll('.audience-button').forEach(button=>button.addEventListener('click',()=>{
    if(selectedAudience===button.dataset.audience)return;
    selectedAudience=button.dataset.audience;
    selectedPhase=null;
    document.querySelectorAll('.phase-card, .student-module-card').forEach(card=>{
      const cardPhase=Number(card.querySelector('.phase-number')?.textContent.match(/\d+/)?.[0]);
      const selected=selectedPhase!==null&&cardPhase===selectedPhase;
      card.classList.toggle('selected',selected);
      card.setAttribute('aria-pressed',String(selected));
    });
    document.querySelectorAll('.audience-button').forEach(toggle=>toggle.setAttribute('aria-pressed',String(toggle===button)));
    renderBatchStatusTotals();renderLocations();
    if(!batchModalLayer.hidden)renderBatchModal();
    if(!participantModalLayer.hidden&&selectedBatch)openParticipantModal(selectedBatch,activeBatchTrigger);
  }));
  renderLocations();

  document.querySelectorAll('[data-export]').forEach(button=>button.addEventListener('click',()=>{
    const section=button.closest('.panel');
    const rows=[...section.querySelectorAll('tr')].map(row=>[...row.children].map(cell=>'"'+cell.innerText.trim().replaceAll('"','""')+'"').join(','));
    if(!rows.length){showToast('This chart is ready to export from a connected data source.');return}
    const blob=new Blob([rows.join('\r\n')],{type:'text/csv;charset=utf-8'});
    const url=URL.createObjectURL(blob);const anchor=document.createElement('a');anchor.href=url;anchor.download=`${button.dataset.export}-report.csv`;anchor.click();URL.revokeObjectURL(url);showToast('Report downloaded as CSV.');
  }));

  document.querySelector('#notifications').addEventListener('click',()=>showToast('You’re all caught up on dashboard notifications.'));
  document.querySelector('#profile-button').addEventListener('click',()=>showToast('Signed in as Project Sponsor.'));
  function selectPhase(phase){
    if(phase.getAttribute('aria-disabled')==='true')return;
    const phaseNumber=Number(phase.querySelector('.phase-number').textContent.match(/\d+/)?.[0]);
    selectedPhase=selectedPhase===phaseNumber?null:phaseNumber;
    document.querySelectorAll('.phase-card, .student-module-card').forEach(card=>{
      const cardPhaseNumber=Number(card.querySelector('.phase-number').textContent.match(/\d+/)?.[0]);
      const selected=selectedPhase!==null&&cardPhaseNumber===selectedPhase;
      card.classList.toggle('selected',selected);
      card.setAttribute('aria-pressed',String(selected));
    });
    renderBatchStatusTotals();
    renderLocations();
    if(!batchModalLayer.hidden)renderBatchModal();
    if(!participantModalLayer.hidden&&selectedBatch)openParticipantModal(selectedBatch,activeBatchTrigger);
  }
  document.querySelectorAll('.phase-card, .student-module-card').forEach(phase=>{
    phase.addEventListener('click',()=>selectPhase(phase));
    phase.addEventListener('keydown',event=>{
      if(event.key==='Enter'||event.key===' '){event.preventDefault();selectPhase(phase)}
    });
  });

  document.querySelectorAll('.filter select').forEach(select=>select.addEventListener('change',()=>{locationPath=[];renderBatchStatusTotals();renderLocations();}));
  document.querySelector('#clear-filters').addEventListener('click',()=>{locationPath=[];renderBatchStatusTotals();renderLocations();});
