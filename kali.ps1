<#
Kali is a PGP daemon that will cipher & decipher all defined files on specific directories.
It's designed to run 24/7 on any specific scheduler.
Please refer to the different comments in the code for more information.
#>

# 1. First Definitions
## Let's define an specific date format for the log file with middle scores;
$datestring = (Get-Date).ToString("s").Replace(":","-")
## Here a quick function that will allow to append onto the defined log a defined string.
Function LogWrite {
   Param ([string]$logstring)
   Add-content $log_in -value $logstring
}

# 2. Incoming files (from any external company to ours)
## The below one is the incoming file that will contain the list of the folders that are allowed for the cipher process with the following logic:
## Column A: Full Win64 path of the folder in where the received PGP files are received
## Column B: Full Win64 path of the folder in where we want to store the deciphered files.
## Column C: PGP key located for the client. i.e. 0x4B4C7090
## ... with one line per client.
$csvFilename_in = "C:\Users\home_user\pgp_keys\folder_list_in.csv"
## Now we'll define how we'll parse this file - aka CSV with semicolons per separator with the previous logic.
$csv_in = Import-Csv $csvFilename_in -Delimiter ";" -Header @("directory_input","directory_output","key_input")
## Now let's generate an specific log file for this deciphers.
$log_in = "C:\Users\home_user\pgp_keys\files_ciphered_in_$datestring.log"

## Now let's go for each of the lines of this input CSV file to check if there is any file to be deciphered.
foreach ($line_in in $csv_in) {
    ## We'll define some specific variables for each of the columns
	  $directory_input = $line_in.directory_input
	  $directory_output = $line_in.directory_output
	  $key_input = $line_in.key_input

    # Now, let's enter recusively to the input folder...
	  Get-ChildItem $directory_input -Recurse | ? { $_.PSIsContainer } | ForEach-Object {
      # ... and let's enter to that folder and cycle for each *.pgp file...
		  $directoryName = $_.FullName
		  cd $directoryName
      Get-ChildItem -Path * -Force -Include *.pgp | Foreach-Object {
        # ... we'll get the full name of the PGP file, and decipher it.
			  $File = Get-Item -Path $_.FullName
    		$FileName = $File.Name
        Invoke-Expression -Command "pgp --home-dir "C:\Users\home_user\Documents\PGP" --decrypt $FileName --passphrase ' ' "
        # Once done, we'll move the deciphered file to the output directory.
			  Move-Item $directoryName\$FileName* $directory_output\
        # ... and we'll write on the logfile the details.
			  LogWrite "$((Get-Date).ToString()) ~ Deciphered File: $directoryName\$FileName - Moved to $directory_output"
		  }
	  }
 }

# 3. Outgoing files (from our company to any external one)
## The below one is the outgoing file that will contain the list of the folders that are allowed for the cipher process with the following logic:
## Column A: Full Win64 path of the folder in where the files we want to share are deposited by the final user
## Column B: Full Win64 path of the folder in where we want to store the ciphered files.
## Column C: PGP key located for the client. i.e. 0x4B4C7090
## ... with one line per client.
$csvFilename_out = "C:\Users\home_user\pgp_keys\folder_list_out.csv"
## Now we'll define how we'll parse this file - aka CSV with semicolons per separator with the previous logic.
$csv_out = Import-Csv $csvFilename_in -Delimiter ";" -Header @("directory_output","directory_input","key_output")
## Now let's generate an specific log file for this deciphers.
$log_out = "C:\Users\home_user\pgp_keys\files_ciphered_out_$datestring.log"

## Now let's go for each of the lines of this input CSV file to check if there is any file to be deciphered.
foreach ($line_out in $csv_out) {
    ## We'll define some specific variables for each of the columns
	  $directory_output = $line_out.directory_output
	  $directory_input = $line_out.directory_input
	  $key_output = $line_out.key_output

    # Now, let's enter recusively to the input folder...
	  Get-ChildItem $directory_output -Recurse | ? { $_.PSIsContainer } | ForEach-Object {
      # ... and let's enter to that folder and cycle for each mon-PGP file...
		  $directoryName = $_.FullName
		  cd $directoryName
  		Get-ChildItem -Path * -Force -Exclude *.pgp | Foreach-Object {
        # ... we'll get the full name of the non-PGP file, and cipher it.
        $File = Get-Item -Path $_.FullName
    		$FileName = $File.Name
        Invoke-Expression -Command "pgp --home-dir "C:\Users\home_user\Documents\PGP" -e $FileName -r $key_output --output $FileName.pgp"
        # Once done, we'll move the ciphered file to the output directory.
        Move-Item $directoryName\$FileName.pgp $directory_input\
        # ... and we'll write on the logfile the details.
			  LogWrite "$((Get-Date).ToString()) ~ Ciphered File: $directoryName\$FileName - Moved to $directory_input"
		  }
	  }
}
