$sourceFolder = '.\source'
$backupFolder = '.\backup'
$restoredFolder = '.\restored'
$email = 'COIT11241@cqu.com'
$name = 'Test Admin'
$passphrase = 'COIT11241'

#Install GPG
function  installGPG() {

	#Install GPG
	choco install gpg4win -y

	#Add gpg to PATH variable for easier execution
	$gpgInstallPath = "C:\Program Files (x86)\GnuPG"
	$currentPATH = [Environment]::GetEnvironmentVariable("PATH", "Machine")
	$newPath = "$currentPATH;$gpgInstallPath"
	[Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")

	#Refresh environment variable for current session
	Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1
	RefreshEnv
}

#Set up GPG key with prepared credential
function setupGPG() {
	gpg --batch --passphrase "$passphrase" --quick-generate-key "$name <$email>"
}

# Backup files from source folder with prepared credential
function backup {
	# Iterate through each file in the source folder
	Get-ChildItem -Path $sourceFolder | ForEach-Object {
		$sourceFilePath = $_.FullName
		$backupFileName = $_.Name + ".gpg"
		$backupFilePath = Join-Path -Path $backupFolder -ChildPath $backupFileName

		gpg --output $backupFilePath --encrypt --recipient $email $sourceFilePath
		# Check if encryption was successful and display message
		if ($LASTEXITCODE -eq 0) {
			Write-Output "Backup of $($sourceFilePath) successful."
		}
		else {
			Write-Output "Failed to backup $($sourceFilePath)."
		}
	}
}


#Restore the backup folder with prepared credential
function restore () {
	# Iterate through files in the backup folder
	Get-ChildItem $BackupFolder | ForEach-Object {
		if ($_.Extension -eq ".gpg") {
			$backupFilePath = $_.FullName
			$restoredFileName = Join-Path -Path $restoredFolder -ChildPath $_.BaseName

			gpg --recipient "$email" --output "$restoredFileName" --decrypt "$backupFilePath"
			if ($LASTEXITCODE -eq 0) {
				Write-Output "Restored '$($_.Name)' to '$restoredFileName'"
			}
			else {
				Write-Output "Failed to backup $($sourceFilePath)."
			}
		}
	}
}

# Check if any arguments were provided
if ($args.Count -gt 0) {
	$firstArgument = $args[0]
	switch ($firstArgument) {
		{ $firstArgument -eq "installGPG" } { installGPG }
		{ $firstArgument -eq "setupGPG" } { setupGPG }
		{ $firstArgument -eq "backup" } { backup }
		{ $firstArgument -eq "restore" } { restore }
		default { "The first argument is unknown." }
	}
}
else {
	Write-Output "No arguments provided."
}

