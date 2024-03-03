# CanaryShell
( ![298313196-019162ce-a988-4be8-9fbd-3c6dc37f9640](https://github.com/Zigul1/CanaryShell/assets/157254375/98e4d648-c4c9-440f-84d4-3c6513dcd349)
 la versione in italiano è "*CanaryShell-ita.ps1*"; come guida c'è questo articolo)

This PowerShell script allows you to create another customizable script that is able to monitor a "canary file" (that can be any file) and its folder. The **general purpose** is to stop malwares (like ransomwares) or attackers from deleting or copying the content of that folder, or at least the script should alert the user while it's happening. The monitoring **resources consumption** is almost null, the script just check few small data periodically.

### USAGE
The procedure is simple:
1. create a file that will act as a disguised sentinel for its folder (name it with an appealing name and don't leave it empty)
2. run *CanaryShell.ps1* and follow its instructions to set: the action you want as an alarm, how often the "canary file" have to be checked, etc. at the end of the quick process, a PowerShell script (named as you want) will be generated
3. set the created PowerShell script as a task that runs at Windows startup, or when a certain user logs in, or at set time intervals, or in a folder to be launched manually.

### MONITORED CHANGES
The monitoring scripts looks for:
- change of "canary file" last access time (it's not always updated in real time by Windows)
- canary existence (changing its name or its folder name are also not allowed)
- canary or its folder are copied
- canary or its folder are mentioned in PowerShell command history

### ACTIONS
When the monitoring scripts it's running, any time the "canary file" or its folder are **copied, deleted, moved, renamed**, using keys shortcuts or Explorer, or even cited in a command executed in a PowerShell terminal, the chosen alert action will be triggered. So it's crucial to remember to don't look even in the "canary file" properties tab, because it will change its last access time, which is monitored by the generated script. Also coping the folder is suppossed to happen after having turn off the monitoring activity (how? well, it depends if it's a scheduled task or it's run manually). It's obviously possible to **keep using, opening, changing all the *other* files, or create new ones**, inside the monitored folder; just avoid doing it using PowerShell terminal, because if you mention the *full* folder path or the "canary file" name and exstension, the alarm will be triggered.
**Alarm actions** can be like: USB drives and networks disconnection then a user logoff, to isolate the folder and stop malicious local or remote processes; a forced PC shutdown to then access the disk in a passive way; anything you decide to set as **custom alert**, can be a simple command that open an empty Notepad or a link to a script that executes predefined actions accordingly to some conditions. Remember to evaluate carefully other folders permissions, when admin rights are required and then set actions accordingly.

## ! WARNING !
When you set the alert action and the interval between monitoring check, remember to look out for **infinte loops**: for example, if the script starts at every user logon, the interval is set to 5 seconds and the alarm action is "logoff", it means that if something triggers the alarm changing an info that is compared with a permanent one in the monitoring script (like last access to the "canary file"), what will happens is that any time you will try to log on, you will have 5 seconds to block the scripts execution (in task manager) before you get logged off again. You will be however able to access the PC with **other user profiles** (unelss you set the task to run with any user), or using CMD in recovery mode, or maybe with live OS (if the disk is not encrypted), to better investigate what triggered the alarm and if anything happened to your folder. Just consider (and test carefully) your settings choice, always leaving a way to react to the alarm action after it got initiated.
