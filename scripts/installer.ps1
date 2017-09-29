Param([string]$ip = "http://172.28.133.250:8000", [string]$domain = "evil.corp", [string]$gpo = "false")

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName PresentationFramework
$rootfolder = "C:/programdata/logsetup"

# Downloads url sent
function download($url)
{
	$filename = $url.split("/")[-1]
	$output = "$rootfolder\$filename"
	Invoke-WebRequest -Uri $url -Outfile $output
}

function Unzip($zipfile)
{
	$filename = $zipfile[-4]
	$outpath = "$rootfolder\$filename"
	[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function winlogbeat
{
	if ((Get-Service winlogbeat).status -eq 'Running')
	{
		return	
	}
	$urls = @("https://live.sysinternals.com/tools/sysmon64.exe",
			  "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml",
			  "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-5.6.1-windows-x86_64.zip",
			  "$ip/winlogbeat.yml")
	
	# Downloads all necessary files
	foreach ($url in $urls) {
		download($url)
	}

	if (!(test-path "$rootfolder\winlogbeat.yml"))
	{
		cp "\\file\share\logsetup\winlogbeat.yml" "$rootfolder\winlogbeat.yml"					
	}

	# Builds the setup stuff
	if ((Get-Service sysmon).status -ne 'Running') 
	{
		$sysmonpath = $rootfolder+'\sysmon64.exe'
		& $sysmonpath -i $rootfolder\sysmonconfig-export.xml -accepteula
	}

	Unzip("$rootfolder\winlogbeat-5.6.1-windows-x86_64.zip")

	rm "$rootfolder\winlogbeat-5.6.1-windows-x86_64.zip"
	rm "$rootfolder\winlogbeat-5.6.1-windows-x86_64/winlogbeat.yml"

	mv "$rootfolder\winlogbeat.yml" "$rootfolder\winlogbeat-5.6.1-windows-x86_64/winlogbeat.yml"
	powershell -file $rootfolder\winlogbeat-5.6.1-windows-x86_64/install-service-winlogbeat.ps1
	Start-Service winlogbeat
}

# Workaround for winpcap
function installchoco
{
	iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Workaround for winpcap
function uninstallchoco
{
	Remove-Item -Recurse -Force "$env:ChocolateyInstall" -Whatif
}

# Sets up packetbeat
function packetbeat
{
	if ((Get-Service packetbeat).status -eq 'Running'))
	{
		return
	}
	$urls = @(
		"https://artifacts.elastic.co/downloads/beats/packetbeat/packetbeat-5.6.1-windows-x86_64.zip",
		"$ip/packetbeat.yml")
	foreach ($url in $urls) {
		download($url)
	}

	if (!(test-path "$rootfolder\packetbeat.yml"))
	{
		cp "\\file\share\logsetup\packetbeat.yml" "$rootfolder\packetbeat.yml"					
	}

	unzip("$rootfolder\packetbeat-5.6.1-windows-x86_64.zip")
	rm "$rootfolder\packetbeat-5.6.1-windows-x86_64/packetbeat.yml"
	mv "$rootfolder\packetbeat.yml" "$rootfolder\packetbeat-5.6.1-windows-x86_64/packetbeat.yml"
	powershell -file $rootfolder\packetbeat-5.6.1-windows-x86_64/install-service-packetbeat.ps1

	installchoco
	choco install winpcap -y
	Start-Service packetbeat
	uninstallchoco

	rm "$rootfolder\packetbeat-5.6.1-windows-x86_64.zip"
}

function createfolder($folderpath)
{
	if (!(Test-Path $folderpath))
	{
		mkdir $folderpath
	}
}

# Adds powershell logging to local machine GPO
# Not in use for domain awareness stuff
function PowershellGPOSetup 
{
	Install-Module PolicyFileEditor
	Import-Module PolicyFileEditor

	download("$ip/registry.pol")

	if (!(test-path "$rootfolder\registry.pol"))
	{
		cp "\\file\share\logsetup\registry.pol" "$rootfolder\registry.pol"					
	}

	# Change this directory
	$PolTemplateFile = "$rootfolder\Registry.pol"
	$MachineDir = "$env:windir\system32\GroupPolicy\Machine\registry.pol"

	foreach ($item in Get-PolicyFileEntry -Path $PolTemplateFile -All)
	{
		$RegPath = $item.key
		$RegName = $item.ValueName
		$RegData = $item.data
		$RegType = $item.Type

		Set-PolicyFileEntry -Path $MachineDir -Key $RegPath -ValueName $RegName -Data $RegData -Type $RegType

	}
	rm $PolTemplateFile	
}

# Installs nuget
function installnuget
{
	Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
}

# Creates a folder (needs credentials - try to bypass)
# Not yet working
function checkfileshare
{
	# Check if already mounted and grab the drive thingy
	if((Get-WmiObject Win32_ComputerSystem).domain -eq $domain)
	{
		New-PSDrive -Name F -PSProvider FileSystem -Root \\file\share -persist 
		# Get-PSDrive (use .root or something)
		#-Credential EVIL\username
	}
}

# Needs to be in evil.corp domain. Might make it a param for generic usage
function verifydomain
{
	# Finds the explicit domain
	if ((Get-WmiObject win32_computersystem).domain -ne $domain)
	{
		[System.Windows.MessageBox]::Show("It seems like you are not logged into the $domain domain", "Domain is not set up.")
		exit
	} 

	# Username not in domain
	if ((Get-WmiObject win32_computersystem).username.split("\")[0].ToUpper() -ne $domain.split(".")[0].toUpper())
	{
		[System.Windows.MessageBox]::Show("You need to be logged into a domain user.", "Domain is not set up.")
		exit
	} 
}

# Runs stuff
function setup
{
	verifydomain
	createfolder($rootfolder)
	installnuget
	Set-PSRepository -name "PSGallery" -InstallationPolicy Trusted

	# Flag for configuring gpo
	# I dunno how booleans work
	if ($gpo -eq "true")
	{
		PowershellGPOSetup	
	}

	winlogbeat
	packetbeat
}

setup
# Installation:
# iex ((New-Object System.Net.WebClient).DownloadString('$ip/installer.ps1')
# FIX - Grab from shared folder
