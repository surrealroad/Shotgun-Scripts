# Shotgun Scripts Launcher

## Purpose
This application provides a convenient way to bundle scripts using the [Shotgun Python API](https://github.com/shotgunsoftware/python-api), any of which can optionally be used as Action Menu Items.

## Usage
1. Clone or download the repo
1. Open in Xcode
1. Build for release

### Adding custom scripts
Once built, the launcher has no scripts by default. To add some, copy them into the `Scripts` folder, found within the `Resources` folder in the application bundle.

#### Custom Script requirements
To set options for the scripts, include one or more of the following somewhere in the code:

```
@SGS_NAME: Name of the script
@SGS_DESCRIPTION: Description for the script
@SGS_CHOOSEFOLDER: YES
@SGS_CHOOSEFILE: NO
@SGS_SAVEFILE: NO
@SGS_QUITAFTER: NO
@SGS_NOTIFYAFTER: YES
@SGS_VISIBLE: NO
@SGS_USERAUTHENTICATION: YES
@SGS_SITEURL: https://yoursite.shotgunstudio.com
```

Explanation of each:
- `SGS_NAME` (string) - the name of the script, as displayed in the dropdown
- `SGS_DESCRIPTION` (string) - the description of the script, which will be displayed in the window when the script is selected
- `SGS_CHOOSEFOLDER` (bool) - will prompt for a folder when the script runs
- `SGS_CHOOSEFILE` (bool) - will prompt for a file when the script runs
- `SGS_SAVEFILE` (bool) - will prompt to save a file when the script runs
- `SGS_QUITAFTER` (bool) - will quit the app when the script has completed
- `SGS_NOTIFYAFTER` (bool) - will show an alert when the script has completed
- `SGS_VISIBLE` (bool) - will hide the script from the dropdown (it can only be activated as an AMI)
- `SGS_USERAUTHENTICATION` (bool) - will prompt for login credentials, otherwise a script key must be used inside the script (this requires @SGS_SITEURL to be set)
- `SGS_SITEURL` (string) - provides a site URL when prompting for a username and password

Custom scripts must have a function called `process_action()`. This will be called when the script is executed, and passed with any parameters in the following order (in the event you provide more than one):

1. Site URL
1. Session token
1. Path to user-selected folder
1. Path to user-selected file
1. Path to user-selected file to create


### Resigning
After making changes to the files inside the bundle, the app must be resigned.

```
sudo xattr -rc /path/to/app
codesign -f -s "Developer ID Application certificate" /path/to/app
```

### Action Menu Items
To use a script as an Action Menu Item (AMI) configure the AMI to use the URL `sgscripts://your_script_name`

A JSON-encoded string will be sent to the script as a parameter with the arguments from Shotgun. Make sure to set `SGS_VISIBLE` to `NO` to prevent users from accidentally running it via the UI (unless you specifically compose the script to allow for that).

### Logging script output
Any `print` (or other `stdout`) statements will be output to the log window. Any `stderr` output will also be output, but in red text.


## Deprecated options

## scripts.plist

Previously it was possible to create and configure the `scripts.plist` file in the `Resources` folder with options for each script. This will no longer be supported due to the inherent complexity of setting it up. Instead, use the keywords in each script as described above.

#### scripts.plist options
The plist root should have an array called `scripts`. This array should contain dictionaries for each script. The dictionary can have the following keys:

- `name` (string)
- `description` (string)
- `filename` (string)
- `chooseFolder` (bool)
- `chooseFile` (bool)
- `saveFile` (bool)
- `quitAfter` (bool)
- `notifyAfter` (bool)
- `visible` (bool)
- `userAuthentication` (bool)
- `siteURL` (string)
- `arguments` (array)
