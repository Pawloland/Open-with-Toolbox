$THIS_SCRIPT_NAME = $MyInvocation.MyCommand.Name

function echowrapper($str) {
	Write-Output "[ $THIS_SCRIPT_NAME ]: $str"
}

# clears registry entries created by previous runs of this script
function clear_registry_entries {
	#background (desktop and explorer folder background)
	# HKEY_CLASSES_ROOT\Directory\Background\shell\VSMenuJetBrainsToolbox
	# 	[REG_SZ] ExtendedSubCommandsKey = Directory\ContextMenus\MenuJetBrainsToolbox
	# 	[REG_SZ] Icon = %LOCALAPPDATA%\JetBrains\Toolbox\bin\jetbrains-toolbox.exe
	# 	[REG_SZ] MUIVerb = Open with Toolbox
	#
	echowrapper "Removing background entries..."
	Remove-Item -Path "registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSMenuJetBrainsToolbox\" -Recurse -ErrorAction SilentlyContinue
	echowrapper "Removing background entries done."


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
	echowrapper "Removing directory entries..."
	Remove-Item -Path "registry::HKEY_CLASSES_ROOT\Directory\ContextMenus\MenuJetBrainsToolbox\" -Recurse -ErrorAction SilentlyContinue
	Remove-Item -Path "registry::HKEY_CLASSES_ROOT\Directory\shell\VSMenuJetBrainsToolbox\" -Recurse -ErrorAction SilentlyContinue
	echowrapper "Removing directory entries done."

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
	# 			[REG_SZ] Icon = %LOCALAPPDATA%\JetBrains\Toolbox\apps\IDEA-U\ch-0\223.8617.56\bin\idea64.exe
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
	echowrapper "Removing files entries..."
	Remove-Item -Path "registry::HKEY_CLASSES_ROOT\``*\ContextMenus\MenuJetBrainsToolbox\" -Recurse -ErrorAction SilentlyContinue
	Remove-Item -Path "registry::HKEY_CLASSES_ROOT\``*\shell\VSMenuJetBrainsToolbox\" -Recurse -ErrorAction SilentlyContinue
	echowrapper "Removing files entries done."
}

echowrapper "Clearing registry..."
clear_registry_entries
echowrapper "Clearing registry done."
echowrapper "Refreshing icons..."
ie4uinit.exe -show
echowrapper "Refreshing icons done."