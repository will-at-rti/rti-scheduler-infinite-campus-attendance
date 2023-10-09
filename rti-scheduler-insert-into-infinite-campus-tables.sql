

--RTI Scheduler Insert to Attendance and Notification


--remove duplicate rows as house keeping item if duplicates ever created
with rti as (
select
studentid,
attendanceDate,
period,
sessionname,
attendanceDescription,
attendanceCode,
attendanceTakenByUserEmail,
school,
row_number() over (partition by studentid,
attendanceDate,
period,
sessionname,
attendanceDescription,
attendanceCode,
attendanceTakenByUserEmail,
school order by studentid) rn
from
<Custom Table Name Here> --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
 rti)
delete from rti where rn>1


;

--create endyear variable
DECLARE @endyear INT;
set @endyear = (select endyear from schoolyear where active = 1);

;
---create parent portal notification
insert into [Notification]
(userID,creationTimestamp, notificationTypeID, [read], notificationText, condenseKey, workspaceContext)
select
distinct
ua.userID,
getdate() as creationTimestamp,
2 as notificationTypeID,
0 as [Read],

concat(i.firstname,case when right(i.firstname,1) = 's' then '''' else '''s' end,' attendance on ',convert(varchar,getdate(),101),' has been updated.') as notificationtext,
CONCAT('studentID=',p.personid,'&date=',convert(varchar,getdate(),101)) as condenseKey,
concat('?studentID=',p.personid,'&date=',convert(varchar,getdate(),101),'&notification=true&notificationType=attendance&structureID=',e.structureID,'&userType=parent') as workspaceContext


from
<Custom Table Name Here> --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
rti
join person p on p.studentNumber = rti.studentId
join [Identity] i on i.identityID = p.currentIdentityID
join school sl on sl.number = cast(rti.School as numeric)
join calendar cl on cl.endYear = @endyear and cl.schoolid = sl.schoolID and cl.[sequence] = 1
join Enrollment e on e.personID = p.personid and e.calendarID = cl.calendarID
join day d on d.calendarID = cl.calendarID and d.[date] = cast(left(rti.attendanceDate,10) as date) and d.instruction = 1
join PeriodSchedule ps on ps.periodScheduleID = d.periodScheduleID
join period pd on pd.periodScheduleID = ps.periodScheduleID and pd.name = rti.period
left join Attendance a on a.[date] = d.[date] and a.periodID = pd.periodID and a.personID = p.personID

join TermSchedule tms on tms.structureID = d.structureID
join term tm on tm.termScheduleID = tms.termScheduleID and tm.startDate <= d.[date] and tm.endDate >= d.[date]
join roster r on r.personID = p.personID
join section s on s.sectionid = r.sectionID
join course c on c.courseid = s.courseID and c.calendarID = cl.calendarID
join trial tl on tl.trialID = r.trialID and tl.active = 1
join SectionPlacement sp on sp.sectionID = s.sectionID and sp.periodID = pd.periodID and sp.termID = tm.termID
join relatedpair rp on rp.personid1 = p.personid and rp.enddate is null and rp.guardian = 1
join useraccount ua on ua.personid = rp.personid2 and ua.homepage = 'nav-wrapper/parent/portal/parent' --nav-wrapper/student/portal/student
left join NotificationSubscription ns on ns.userid = ua.userid and ns.notificationtypeID = 2 and ns.receivenotifications = 0


WHERE
1=1
and a.personID is null
and e.startDate <= d.[date]
and isnull(e.endDate,'2050-01-01') >= d.[date]
and isnull(r.startDate,'2000-01-01') <= d.[date]
and isnull(r.endDate,'2050-01-01') >= d.[date]
and cast(left(rti.attendanceDate,10) as date) = cast(GETDATE() as date)
and ns.userID is null --exclude those who do not want attendance notifications
;

--create student notification
insert into [Notification]
(userID,creationTimestamp, notificationTypeID, [read], notificationText, condenseKey, workspaceContext)
select
distinct
ua.userID,
getdate() as creationTimestamp,
2 as notificationTypeID,
0 as [Read],

concat(i.firstname,case when right(i.firstname,1) = 's' then '''' else '''s' end,' attendance on ',convert(varchar,getdate(),101),' has been updated.') as notificationtext,
CONCAT('studentID=',p.personid,'&date=',convert(varchar,getdate(),101)) as condenseKey,
concat('?studentID=',p.personid,'&date=',convert(varchar,getdate(),101),'&notification=true&notificationType=attendance&structureID=',e.structureID,'&userType=student') as workspaceContext


from
<Custom Table Name Here> --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
rti
join person p on p.studentNumber = rti.studentId
join [Identity] i on i.identityID = p.currentIdentityID
join school sl on sl.number = cast(rti.School as numeric)
join calendar cl on cl.endYear = @endyear and cl.schoolid = sl.schoolID and cl.[sequence] = 1
join Enrollment e on e.personID = p.personid and e.calendarID = cl.calendarID
join day d on d.calendarID = cl.calendarID and d.[date] = cast(left(rti.attendanceDate,10) as date) and d.instruction = 1
join PeriodSchedule ps on ps.periodScheduleID = d.periodScheduleID
join period pd on pd.periodScheduleID = ps.periodScheduleID and pd.name = rti.period
left join Attendance a on a.[date] = d.[date] and a.periodID = pd.periodID and a.personID = p.personID

join TermSchedule tms on tms.structureID = d.structureID
join term tm on tm.termScheduleID = tms.termScheduleID and tm.startDate <= d.[date] and tm.endDate >= d.[date]
join roster r on r.personID = p.personID
join section s on s.sectionid = r.sectionID
join course c on c.courseid = s.courseID and c.calendarID = cl.calendarID
join trial tl on tl.trialID = r.trialID and tl.active = 1
join SectionPlacement sp on sp.sectionID = s.sectionID and sp.periodID = pd.periodID and sp.termID = tm.termID
join useraccount ua on ua.personid = p.personID and ua.homepage = 'nav-wrapper/student/portal/student'
left join NotificationSubscription ns on ns.userid = ua.userid and ns.notificationtypeID = 2 and ns.receivenotifications = 0


WHERE
1=1
and a.personID is null
and e.startDate <= d.[date]
and isnull(e.endDate,'2050-01-01') >= d.[date]
and isnull(r.startDate,'2000-01-01') <= d.[date]
and isnull(r.endDate,'2050-01-01') >= d.[date]
and cast(left(rti.attendanceDate,10) as date) = cast(GETDATE() as date)
and ns.userID is null --exclude those who do not want attendance notifications
;


--Insert attendance
insert into Attendance
(calendarID, personID, periodID, [date], [status], modifiedDate, modifiedByID)
select
distinct
d.calendarid, p.personid, pd.periodid, d.date, rti.attendanceCode, cast(left(rti.attendanceDate,10) as date), '11118'

from
<Custom Table Name Here> --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
rti
join person p on p.studentNumber = rti.studentId
join school sl on sl.number = cast(rti.School as numeric)
join calendar cl on cl.endYear = @endyear and cl.schoolid = sl.schoolID and cl.[sequence] = 1
join Enrollment e on e.personID = p.personid and e.calendarID = cl.calendarID
join day d on d.calendarID = cl.calendarID and d.[date] = cast(left(rti.attendanceDate,10) as date) and d.instruction = 1
join PeriodSchedule ps on ps.periodScheduleID = d.periodScheduleID
join period pd on pd.periodScheduleID = ps.periodScheduleID and pd.name = rti.period
left join Attendance a on a.[date] = d.[date] and a.periodID = pd.periodID and a.personID = p.personID

join TermSchedule tms on tms.structureID = d.structureID
join term tm on tm.termScheduleID = tms.termScheduleID and tm.startDate <= d.[date] and tm.endDate >= d.[date]
join roster r on r.personID = p.personID
join section s on s.sectionid = r.sectionID
join course c on c.courseid = s.courseID and c.calendarID = cl.calendarID
join trial tl on tl.trialID = r.trialID and tl.active = 1
join SectionPlacement sp on sp.sectionID = s.sectionID and sp.periodID = pd.periodID and sp.termID = tm.termID

WHERE
1=1
and a.personID is null
and e.startDate <= d.[date]
and isnull(e.endDate,'2050-01-01') >= d.[date]
and isnull(r.startDate,'2000-01-01') <= d.[date]
and isnull(r.endDate,'2050-01-01') >= d.[date]
and cast(left(rti.attendanceDate,10) as date) = cast(GETDATE() as date)
;

