$THIS_SCRIPT_NAME = $MyInvocation.MyCommand.Name
$THIS_SCRIPT_PATH = ($MyInvocation.MyCommand.Path -split "\\$THIS_SCRIPT_NAME")[0]
$VBS_SCRIPT_PATH = "$THIS_SCRIPT_PATH\nowindow.vbs"


function echowrapper($str) {
	Write-Output "[ $THIS_SCRIPT_NAME ]: $str"
}


class Path {
	[string] $name
	[string] $script
	[string] $icon

	Path(
		[string] $n,
		[string] $s,
		[string] $i
	) {
		$this.name = $n
		$this.script = $s
		$this.icon = $i
	}

	[string] ToString() {
		return (($this | Format-List | Out-String).trim())
	}
	
}

$PATHS = @{}

function host_sanity_check {
	# check if vbs script exists
	if (!(Test-Path $VBS_SCRIPT_PATH)) {
		echowrapper "VBS script not found in a default location: $VBS_SCRIPT_PATH"
		throw "VBS script not found error."
	}

	#get install location of Toolbox
	$toolbox_path = "$Env:LOCALAPPDATA\JetBrains\Toolbox"
	if (Test-Path $toolbox_path) {
		echowrapper "JetBrains Toolbox was found installed in a default location: $toolbox_path"
		$PATHS.Add("toolbox", [Path]::new(
				"Toolbox", 
				"", 
				"$toolbox_path\bin\jetbrains-toolbox.exe"
			
			)
		) | out-null
	}
	else {
		#TODO: allow for custom install location of toolbox
		echowrapper "JetBrains Toolbox was not found installed in default location: $toolbox_path"
		throw "Toolbox not found error."
	}


	# Get all jetbrains scripts
	$scripts = Get-Childitem -Path "$toolbox_path\scripts" -Filter *.cmd
	foreach ($script in $scripts) {
		echowrapper "Found script: $script"
		# get name of jetbrains product from inside of a script, because sometimes user can have multiple versions of the same product like 
		# IntelliJ IDEA Community Edition and IntelliJ IDEA Ultimate
		$script_content = Get-Content "$toolbox_path\scripts\$script" -Tail 1
		$IDE_path = $script_content.trim().split("%")[2].trim()
		$tmp = ($IDE_path.trim() -split "\\apps\\")[1] -split "\\"
		$variant = $tmp[0]
		$script_name = ($script -split ".cmd")[0]
		#Hardcoded names for some jetbrains products
		$name = switch ($variant) {
			"AndroidStudio" { "Android Studio" }
			"IDEA-C" { "IntelliJ IDEA Community Edition" }
			"IDEA-U" { "IntelliJ IDEA Ultimate" }
			"PyCharm-C" { "PyCharm Community" }
			"PyCharm-P" { "PyCharm Professional" }
			Default { $variant }
		}
		# in windows registry any exe can be used as an icon, and windows will automatically extract the icon from the exe
		$icon = $IDE_path 

		$PATHS.Add($script_name , [Path]::new(
				$name, 
				"$toolbox_path\scripts\$script", 
				$icon
			)
		) | out-null
	}
	echowrapper "Full information about found scripts: `n$(( $PATHS | Format-List| Out-String).trim())"
}

function create_registry_entries {
	# create registry entries for each IDE

	# background (desktop and explorer folder background)
		# HKEY_CLASSES_ROOT\Directory\Background\shell\VSMenuJetBrainsToolbox
		# 	[REG_SZ] ExtendedSubCommandsKey = Directory\ContextMenus\MenuJetBrainsToolbox
		# 	[REG_SZ] Icon = %LOCALAPPDATA%\JetBrains\Toolbox\bin\jetbrains-toolbox.exe
		# 	[REG_SZ] MUIVerb = Open with Toolbox
	#
	echowrapper "Creating background entries..."
	New-Item -Path "registry::HKEY_CLASSES_ROOT\Directory\Background\shell\" -Name "VSMenuJetBrainsToolbox" | out-null
	New-ItemProperty -Path "registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSMenuJetBrainsToolbox\" -Name "ExtendedSubCommandsKey" -Value "Directory\ContextMenus\MenuJetBrainsToolbox" -PropertyType "String" | out-null
	New-ItemProperty -Path "registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSMenuJetBrainsToolbox\" -Name "Icon" -Value $PATHS.toolbox.icon -PropertyType "String" | out-null
	New-ItemProperty -Path "registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSMenuJetBrainsToolbox\" -Name "MUIVerb" -Value "Open with $($PATHS.toolbox.name)" -PropertyType "String" | out-null
	echowrapper "Creating background entries done."

	# directory (right click on dir icon)
	# HKEY_CLASSES_ROOT\Directory
	# 	\ContextMenus\MenuJetBrainsToolbox\shell
	#		\as
	#			[REG_SZ] Icon = %LOCALAPPDATA%\JetBrains\Toolbox\apps\AndroidStudio\ch-0\223.7571.182.2231.9532861\bin\studio64.exe
	#			[REG_SZ] MUIVerb = Android Studio
	#			\command
	# 				[REG_EXPAND_SZ] Default = "%windir%\system32\wscript.exe" "nowindow.vbs" "%LOCALAPPDATA%\JetBrains\Toolbox\scripts\studio.cmd" "%V"
	#		\intellij
	#			[REG_SZ] Icon = %LOCALAPPDATA%\JetBrains\Toolbox\apps\IDEA-U\ch-0\223.8617.56\bin\idea64.exe
	# 			[REG_SZ] MUIVerb = IntelliJ IDEA
	# 			\command
	# 				[REG_EXPAND_SZ] Default = "%windir%\system32\wscript.exe" "nowindow.vbs" "%LOCALAPPDATA%\JetBrains\Toolbox\scripts\idea.cmd" "%V"
	#		\pycharm
	# 			[REG_SZ] Icon = %LOCALAPPDATA%\JetBrains\Toolbox\apps\PyCharm-P\ch-0\223.8617.48\bin\pycharm64.exe
	# 			[REG_SZ] MUIVerb = PyCharm
	# 			\command
	#				[REG_EXPAND_SZ] Default = "%windir%\system32\wscript.exe" "nowindow.vbs" "%LOCALAPPDATA%\JetBrains\Toolbox\scripts\pycharm.cmd" "%V"
	#	\shell\VSMenuJetBrainsToolbox
	#		[REG_SZ] ExtendedSubCommandsKey = Directory\ContextMenus\MenuJetBrainsToolbox
	#		[REG_SZ] Icon = %LOCALAPPDATA%\JetBrains\Toolbox\bin\jetbrains-toolbox.exe
	#		[REG_SZ] MUIVerb = Open with Toolbox
	# 
	echowrapper "Creating directory entries..."
	New-Item -Path "registry::HKEY_CLASSES_ROOT\Directory\" -Name "ContextMenus" -ErrorAction SilentlyContinue | out-null # ignore error if already exists, because I use this path outside this script for different actions so it is never removed
	New-Item -Path "registry::HKEY_CLASSES_ROOT\Directory\ContextMenus\" -Name "MenuJetBrainsToolbox" | out-null
	New-Item -Path "registry::HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuJetBrainsToolbox\" -Name "shell" | out-null
	$BASE_PATH = "registry::HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuJetBrainsToolbox\shell\"
	echowrapper "	for:"
	foreach ($IDE in $PATHS.keys) {
		if ($IDE -eq "toolbox") { continue } #skip toolbox, it's not an IDE
		echowrapper ("	- $IDE...")
		New-Item -Path $BASE_PATH -Name $IDE | out-null
		New-ItemProperty -Path "$BASE_PATH\$IDE\" -Name "Icon" -Value $PATHS[$IDE].icon -PropertyType "String" | out-null
		New-ItemProperty -Path "$BASE_PATH\$IDE\" -Name "MUIVerb" -Value $PATHS[$IDE].name -PropertyType "String" | out-null
		New-Item -Path "$BASE_PATH\$IDE\"  -Name "command" | out-null
		New-ItemProperty -Path "$BASE_PATH\$IDE\command\" -Name "(Default)" -Value "`"%windir%\system32\wscript.exe`" `"$VBS_SCRIPT_PATH`"  `"$($PATHS[$IDE].script)`" `"%V`"" -PropertyType "ExpandString" | out-null
		echowrapper "	- $IDE Done."
	}
	New-Item -Path "registry::HKEY_CLASSES_ROOT\Directory\shell\" -Name "VSMenuJetBrainsToolbox" | out-null
	New-ItemProperty -Path "registry::HKEY_CLASSES_ROOT\Directory\shell\VSMenuJetBrainsToolbox\" -Name "ExtendedSubCommandsKey" -Value "Directory\ContextMenus\MenuJetBrainsToolbox" -PropertyType "String" | out-null
	New-ItemProperty -Path "registry::HKEY_CLASSES_ROOT\Directory\shell\VSMenuJetBrainsToolbox\" -Name "Icon" -Value "$($PATHS.toolbox.icon)" -PropertyType "String" | out-null
	New-ItemProperty -Path "registry::HKEY_CLASSES_ROOT\Directory\shell\VSMenuJetBrainsToolbox\" -Name "MUIVerb" -Value "Open with $($PATHS.toolbox.name)" -PropertyType "String" | out-null
	echowrapper "Creating directory entries done."


	# file (right click on file icon)
	# VsMenuJetBrainsToolbox - because when there is VSCode installed, I want the Toolbox entry to be bellow it
	# and it's easiest to do it alphabetically
	# 
	# HKEY_CLASSES_ROOT\*
	#	\ContextMenus\MenuJetBrainsToolbox\shell
	#		\as
	# 			[REG_SZ] Icon = %LOCALAPPDATA%\JetBrains\Toolbox\apps\AndroidStudio\ch-0\223.7571.182.2231.9532861\bin\studio64.exe
	# 			[REG_SZ] MUIVerb = Android Studio
	# 			\command
	#				[REG_EXPAND_SZ] Default = "%windir%\system32\wscript.exe" "nowindow.vbs" "%LOCALAPPDATA%\JetBrains\Toolbox\scripts\studio.cmd" "%1"
	# 		\intellij
	# 			[REG_SZ] Icon =%LOCALAPPDATA%\JetBrains\Toolbox\apps\IDEA-U\ch-0\223.8617.56\bin\idea64.exe
	# 			[REG_SZ] MUIVerb = IntelliJ IDEA
	# 			\command
	# 				[REG_EXPAND_SZ] Default = "%windir%\system32\wscript.exe" "nowindow.vbs" "%LOCALAPPDATA%\JetBrains\Toolbox\scripts\idea.cmd" "%1"
	# 		\pycharm
	# 			[REG_SZ] Icon = %LOCALAPPDATA%\JetBrains\Toolbox\apps\PyCharm-P\ch-0\223.8617.48\bin\pycharm64.exe
	# 			[REG_SZ] MUIVerb = PyCharm
	# 			\command
	# 				[REG_EXPAND_SZ] Default = "%windir%\system32\wscript.exe" "nowindow.vbs" "%LOCALAPPDATA%\JetBrains\Toolbox\scripts\pycharm.cmd" "%1"
	#	\shell\VSMenuJetBrainsToolbox
	# 		[REG_SZ] ExtendedSubCommandsKey = *\ContextMenus\MenuJetBrainsToolbox
	# 		[REG_SZ] Icon = %LOCALAPPDATA%\JetBrains\Toolbox\bin\jetbrains-toolbox.exe
	# 		[REG_SZ] MUIVerb = Open with Toolbox
	# 
	echowrapper "Creating file entries..."
	New-Item -Path "registry::HKEY_CLASSES_ROOT\``*\" -Name "ContextMenus" -ErrorAction SilentlyContinue | out-null # ignore error if already exists, because I use this path outside this script for different actions so it is never removed
	New-Item -Path "registry::HKEY_CLASSES_ROOT\``*\ContextMenus\" -Name "MenuJetBrainsToolbox" | out-null
	New-Item -Path "registry::HKEY_CLASSES_ROOT\``*\ContextMenus\MenuJetBrainsToolbox\" -Name "shell" | out-null
	$BASE_PATH = "registry::HKEY_CLASSES_ROOT\``*\ContextMenus\MenuJetBrainsToolbox\shell\"
	echowrapper "	for:"
	foreach ($IDE in $PATHS.keys) {
		if ($IDE -eq "toolbox") { continue } #skip toolbox, it's not an IDE
		echowrapper ("	- $IDE...")
		New-Item -Path $BASE_PATH -Name $IDE | out-null
		New-ItemProperty -Path "$BASE_PATH\$IDE\" -Name "Icon" -Value $PATHS[$IDE].icon -PropertyType "String" | out-null
		New-ItemProperty -Path "$BASE_PATH\$IDE\" -Name "MUIVerb" -Value $PATHS[$IDE].name -PropertyType "String" | out-null
		New-Item -Path "$BASE_PATH\$IDE\"  -Name "command" | out-null
		New-ItemProperty -Path "$BASE_PATH\$IDE\command\" -Name "(Default)" -Value "`"%windir%\system32\wscript.exe`" `"$VBS_SCRIPT_PATH`"  `"$($PATHS[$IDE].script)`" `"%1`"" -PropertyType "ExpandString" | out-null
		echowrapper "	- $IDE Done."
	}
	New-Item -Path "registry::HKEY_CLASSES_ROOT\``*\shell\" -Name "VSMenuJetBrainsToolbox" | out-null
	New-ItemProperty -Path "registry::HKEY_CLASSES_ROOT\``*\shell\VSMenuJetBrainsToolbox\" -Name "ExtendedSubCommandsKey" -Value "`*\ContextMenus\MenuJetBrainsToolbox" -PropertyType "String" | out-null
	New-ItemProperty -Path "registry::HKEY_CLASSES_ROOT\``*\shell\VSMenuJetBrainsToolbox\" -Name "Icon" -Value "$($PATHS.toolbox.icon)" -PropertyType "String" | out-null
	New-ItemProperty -Path "registry::HKEY_CLASSES_ROOT\``*\shell\VSMenuJetBrainsToolbox\" -Name "MUIVerb" -Value "Open with $($PATHS.toolbox.name)" -PropertyType "String" | out-null
	echowrapper "Creating file entries done."
}

echowrapper "Checking host configuration..."
host_sanity_check
echowrapper "Checking host configuration done."
./uninstall.ps1
echowrapper "Creating registry entries..."
create_registry_entries
echowrapper "Creating registry entries done."
echowrapper "Refreshing icons..."
ie4uinit.exe -show
echowrapper "Refreshing icons done."

