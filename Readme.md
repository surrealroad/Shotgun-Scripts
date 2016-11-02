# Shotgun Scripts Launcher

## Purpose
This application provides a convenient way to bundle scripts using the [Shotgun Python API](https://github.com/shotgunsoftware/python-api), any of which can optionally be used as Action Menu Items.

## Usage
1. Clone or download the repo
1. Open in Xcode
1. Correct the path to the `shotgun_api3` so that it points to a local copy of 
1. Build for release

### Adding custom scripts
Once built, the launcher has no scripts by default. To add some, copy them into the `Resources` folder within the application bundle.

Next you need to create and configure the `scripts.plist` file in that folder with options for each script.

#### Custom Script requirements
Custom scripts must have a function called `process_action()`. This will be called when the script is executed, and passed with any parameters.

#### scripts.plist options
The plist root should have an array called `scripts`. This array should contain dictionaries for each script. The dictionary can have the following keys:

- `name` (string) - the name of the script, as displayed in the dropdown
- `description` (string) - the description of the script, which will be displayed in the window when the script is selected
- `filename` (string) - the filename of the script, without the extension
- `chooseFolder` (bool) - will prompt for a folder when the script runs
- `chooseFile` (bool) - will prompt for a file when the script runs
- `saveFile` (bool) - will prompt to save a file when the script runs
- `quitAfter` (bool) - will quit the app when the script has completed
- `notifyAfter` (bool) - will show an alert when the script has completed
- `arguments` (array) - additional array arguments to send to the script


### Resigning
After making changes to the files inside the bundle, the app must be resigned.

### Action Menu Items
To use a script as an Action Menu Item (AMI) configure the AMI to use the URL `sgscripts://your_script_name`
