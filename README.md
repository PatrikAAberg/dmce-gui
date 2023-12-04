# dmce-gui
GUI implementations for viewing DMCE generated data.

## dmcetraceGUI

<img src="https://github.com/PatrikAAberg/dmce-gui/assets/22773714/db5bef9a-63ef-4d7d-8fd9-5ba53a9be0b1" width=40% height=40%>

Interactive trace GUI used to view DMCE trace bundles (.zip files). Use main latest of this git together with master latest of the [dmce](https://github.com/PatrikAAberg/dmce) git until the upcoming 2.0 release.

![dmce-trace-threads](https://github.com/PatrikAAberg/dmce-gui/assets/22773714/f988f245-47c3-4580-9950-c6d483281fac)

#### Download Godot and generate a runnable DMCE Trace GUI
To generate an executable, use the Godot editor:
https://godotengine.org/download/archive/4.0.4-stable/
1. Navigate to Project->Export.
2. Select your platform of preference
3. Click "Export all" and choose "Release"

#### Generate DMCE trace bundles

    $ # Assuming DMCE is installed on your system (https://github.com/PatrikAAberg/dmce)
    $ dmce-set-profile trace-mc
    $ cd path-to-git
    $ dmce
    $ # Build and execute program here
    $ dmce-trace --bundle [trace buffer file] [ probe references file] [code tree]

The probe references file is generated at the dmce probing pass. Everytime a process exists that has run at least one dmce probe will produce a trace buffer file. The code tree is the path to the git containing the probed code. Default locations for the first two:

/tmp/$USER/dmce/dmcebuffer.bin

/tmp/$USER/dmce/name-of-git/probe-references.log

If confusion hits you, --help switches are available for most dmce utilities!
