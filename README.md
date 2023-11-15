# dmce-gui
GUI implementations for viewing dmce generated data. Use main latest of this git together with master latest of the dmce git until the upcoming 2.0 release.

### dmcetraceGUI

![dmce-trace-threads](https://github.com/PatrikAAberg/dmce-gui/assets/22773714/f988f245-47c3-4580-9950-c6d483281fac)


Interactive trace GUI used to view trace bundles (.zip files) generated with:

    $ # Assuming dmce is installed on your system (https://github.com/PatrikAAberg/dmce)
    $ dmce-set-profile trace-mc
    $ cd path-to-git
    $ dmce-launcher -aq
    $ # Build and execute program here
    $ dmce-trace --bundle [trace buffer file] [ probe references file] [code tree]

If confusion hits you, --help switches are available for most dmce utilities!
