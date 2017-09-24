Add-Type -AssemblyName System.IO.Compression.FileSystem

Write-Host "Started syslog setup! Download all the things \o/"

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

function winlogbeat
{
	# FIX - Add .yml files - Currently uses python SimpleHTTPServer - github?
	$urls = @("https://live.sysinternals.com/tools/sysmon64.exe",
			  "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml",
			  "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-5.6.1-windows-x86_64.zip",
			  "https://raw.githubusercontent.com/frikky/autoelk/master/scripts/winlogbeat.yml")


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
	Write-Host "If logs aren't forwarded:"
	Write-Host "Edit \'output.logstash\' in winlogbeat-5.6.1-windows-x86_64 to have the correct IP." 
}

# Workaround for winpcap
function installchoco
{
	Set-ExecutionPolicy AllSigned; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Workaround for winpcap
function uninstallchoco
{
	Remove-Item -Recurse -Force "$env:ChocolateyInstall" -Whatif
}

# Sets up packetbeat
function packetbeat
{
	Write-Host "Starting packetbeat setup"
	$urls = @(
		"https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-5.6.1-windows-x86_64.zip",
		"https://raw.githubusercontent.com/frikky/autoelk/master/scripts/packetbeat.yml")
	foreach ($url in $urls) {
		download($url)
	}

	unzip("packetbeat-5.6.1-windows-x86_64.zip")
	mv "packetbeat.yml" "packetbeat-5.6.1-windows-x86_64"
	.\packetbeat-5.6.1-windows-x86_64/install-service-packetbeat.ps1

	installchoco
	choco install winpcap
	uninstallchoco

	Start-Service packetbeat
}

packetbeat()
