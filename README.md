# rti-scheduler-infinite-campus-attendance
This powershell script requests attendance for the current day via RTI Scheduler's Data Export API then converts it to a Pipe-delimited CSV that can be used to easily insert records into your IC database.

## Instructions
Set the config variables on rows 4-7. 
- rtiApiToken = your generated token under 'Data Sync API'
- rtiSchoolId = the RTI identifier for the school you intend to pull attendance from
- infiniteCampusSchoolId = The IC identifier for the school you intend to insert attendance for
- csvFileName = a known filename you can refer to in other processes
