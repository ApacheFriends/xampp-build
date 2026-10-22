# XAMPP build system

The XAMPP build system is a group of Tcl classes and procedures that allow us to automate the generation of XAMPP installers, by taking care of building, configuring and preparing the distribution of the bundled programs.

The build system lays in the `src` folder of the repository. Most of the Tcl files that are there only contain program classes. Under the `apps` and `base` directories, you will find the XML files describing the [InstallBuilder](https://installbuilder.com) logic steps.

## Requirements

- [Docker](https://www.docker.com/products/docker-desktop/). You can check the resources into the `Dockerfile` if you want to run the same steps in a different host.
- Thirdparty source code tarballs. You can get those tarballs from the official websites. For simplicity you can also download from [Sourceforge](https://sourceforge.net/projects/xampp/files/thirdparties/).

## TL;DR

```
$ docker build . -t xampp-build
$ docker run -v `pwd`/../xampp-code:/home/xampp-code -v `pwd`/tarballs:/tmp/tarballs -it xampp-build bash
```

## How to compile the code from source for Linux and OS X

For Unix platforms (Linux and OS X), before creating the installers, the process relays on a tarball including all the required components already compiled. The XAMPP build system is also able to compile those components for you.

You can build the XAMPP base tarballs from the `src` directory. You can get the source code for any of the components from the official website. For simplicity you can get them together from [Sourceforge](https://sourceforge.net/projects/xampp/files/thirdparties/).

Once the needed files are located into a `tarballs` directory and mounted into the container at `/tmp/tarballs`, run the commands below to create the desired installer depending on the platform. You can use the container to compile the binaries for Linux x64 but you will need access to an OS X higher than 10.6 to compile the binaries from OS X there.

```
tclsh createstack.tcl buildTarball xamppunixinstaller82stack linux-x64
tclsh createstack.tcl buildTarball xamppunixinstaller82stack osx-x64
```

> NOTE: Build other PHP versions (8.2.x, 8.3.x, 8.4.x, 8.5.x) replacing `82` with `83`, `84`, `85`.
> NOTE: PHP 7.4, 8.0, 8.1 are all passed end of life and stacks will be removed in upcoming versions of XAMPP.

The tarball needed for building will be located in `/bitnami/<stack_name>/output` and it will have the date it was built in the filename. This file must be copied into `/tmp/tarballs` mounted directory to use in the next step to build the xampp installer.

## How to build the XAMPP installers

You can build the XAMPP installers from the `src` directory. The Linux and OS X platforms will require a tarball with all the binaries compiled from the previous step.

Once the needed files are located into a `tarballs` directory and mounted into the container at `/tmp/tarballs`, run the commands below to create the desired installer depending on the platform. For the Linux and OS X platforms this will require the tarball generated from `tclsh createstack.tcl buildTarball` for Windows this will just require the Windows third party tarballs as it does not perform any compilation but packs the existing softwares and configures them.

```
tclsh createstack.tcl pack xamppunixinstaller82stack linux-x64
tclsh createstack.tcl pack xamppunixinstaller82stack osx-x64
tclsh createstack.tcl pack xamppinstaller82stack windows-x64
```

> NOTE: Build other PHP versions (8.2.x, 8.3.x, 8.4.x, 8.5.x) replacing `82` with `83`, `84`, `85`.

The installers will be accessible at `/opt/installbuilder/output/`.

## Optional Components

Currently supported only for OpenJDK and Windows versions of XAMPP.

```
tclsh createstack.tcl pack xamppinstaller82stack windows-x64 addComponents java
```

After the `addComponents` flag add a comma separated list of optional components to include. `Example: addComponents "java, python"`. Currently only java is supported for the Windows XAMPP installer, but this feature will be expanded to include more components across all of the architectures.

This is an easy way to add extra components to a given core stack. Including `openjdk` first was done because the current version of XAMPP Windows has Tomcat as a default service which needs an instance of OpenJDK installed to run. If you want XAMPP on Windows to fully work out of the box then use the `addComponents java`. This is an optional feature though as some of these optional components greatly increase the size of XAMPP installer binary and should be an opt-in feature to include them.

## License


Copyright &copy; 2022 Apache Friends

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

