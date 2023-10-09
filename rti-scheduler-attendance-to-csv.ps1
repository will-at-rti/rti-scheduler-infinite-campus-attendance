## RTI Scheduler Attendance Export

## You should only need to set these three values
$rtiApiToken = '<your-rti-api-token-here>'
$rtiSchoolId = '<your-rti-school-id-here>'
$infiniteCampusSchoolId = '<your-infinite-campus-school-id-here>'
$csvFileName = '<your-known-filename-here>.csv'


## The following lines shouldn't need to be adjusted school-to-school
$preUrl = 'https://rtischeduler.com/data-export-api/schools/' + $rtiSchoolId +'/attendance?absencesOnly=true&date='
$date = (get-date).ToString("yyyy-MM-dd")

# If you are trying to test this and there is no attendance in RTI Scheduler for today, 
# you can hardcode a date with known absences for testing.
$testDate = '2023-10-05' 

#If testing, change this next line to: $Url = $preUrl + $testDate
$Url = $preUrl + $date 

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("rti-api-token", "$rtiApiToken")
$params = @{
    Uri         = $Url
    Headers     = $headers
    Method      = 'GET'
    Body        = $jsonSample
    ContentType = 'application/json'
    }
	
$results =  Invoke-RestMethod @params  

## Manipulate each row of the results retrieved from RTI Scheduler
foreach ($absenceRecord in $results){
	## removes all commas from every value on this row (Is this some sort of requirement?)
	$absenceRecord | ForEach-Object { $_ -replace ',',' ' } 
	
	## adds the IC school ID
    $absenceRecord | Add-Member -MemberType NoteProperty $infiniteCampusSchoolId -Name 'school'
}

## Export the specified columns into a file with a pipe delimiter 
$results | Select studentId,attendanceCode,period,attendanceDate,sessionName,attendanceTakenByUserEmail,school | Export-Csv -Path $csvFileName -NoTypeInformation -Delimiter '|'