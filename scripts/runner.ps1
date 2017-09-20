Add-Type -AssemblyName System.IO.Compression.FileSystem

Write-Host "Started syslog setup!\nDownload all the thing \o/"

function download($url)
{
	$filename = $url.split("/")[-1]
	$output = "$PSScriptRoot\$filename"
	Write-Host $output
	Invoke-WebRequest -Uri $url -Outfile $output
}

function Unzip($zipfile)
{
	$filename = $zipfile[-4]
	$outpath = "$PSScriptRoot\$filename"
	[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

# FIX - Add .yml files - Currently uses python SimpleHTTPServer - github?
$urls = @("https://live.sysinternals.com/tools/sysmon64.exe",
		  "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml",
		  "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-5.6.1-windows-x86_64.zip",
		  "http://raw.githubusercontent.com/frikky/autoelk/winlogbeat.yml")


# Downloads all necessary files
foreach ($url in $urls) {
	download($url)
}

# Builds folder structure etc
Write-Host "Finished downloads. Moving files"

.\sysmon64.exe -accepteula -i sysmonconfig-export.xml
Unzip("winlogbeat-5.6.1-windows-x86_64.zip")

rm "winlogbeat-5.6.1-windows-x86_64.zip"
rm "winlogbeat-5.6.1-windows-x86_64/winlogbeat.yml"

Write-Host "Adding IP to winlogbeat.yml"
mv "winlogbeat.yml" "winlogbeat-5.6.1-windows-x86_64/winlogbeat.yml"
.\winlogbeat-5.6.1-windows-x86_64/install-service-winlogbeat.ps1
Write-Host "Starting service winlogbeat"
Start-Service winlogbeat

Write-Host "Might be done with setup! Check Kibana \o/"
Write-Host "If logs aren't forwarded:\n Edit \"output.logstash\" in winlogbeat-5.6.1-windows-x86_64 to have the correct IP." 
