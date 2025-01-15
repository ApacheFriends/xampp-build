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

Once the needed files are located into a `tarballs` directory and mounted into the container at `/tmp/tarballs`, your can run the commands below to create the desired installer depending on the platform. You can use the container to compile the binaries for Linux x64 but you will need access to an OS X higher than 10.6 to compile the binaries from OS X there.

```
tclsh createstack.tcl buildTarball xamppunixinstaller80stack linux-x64
tclsh createstack.tcl buildTarball xamppunixinstaller80stack osx-x64
```

> NOTE: you can build other PHP versions (7.4.x, 8.0.x, 8.1.x, or 8.2.x) replacing `80` with `74`, `81`, or `82`.

Once the tarball is compressed, you can move it to the `/tmp/tarball` mounted directory to use it in the next step.

## How to build the XAMPP installers

You can build the XAMPP installers from the `src` directory. The Linux and OS X platforms will require a tarball with all the binaries compiled from the previous step.

Once the needed files are located into a `tarballs` directory and mounted into the container at `/tmp/tarballs`, your can run the commands below to create the desired installer depending on the platform.

```
tclsh createstack.tcl pack xamppunixinstaller80stack linux-x64
tclsh createstack.tcl pack xamppunixinstaller80stack osx-x64
tclsh createstack.tcl pack xamppinstaller80stack windows-x64
```

> NOTE: you can pack other PHP versions (7.4.x, 8.0.x, 8.1.x, or 8.2.x) replacing `80` with `74`, `81`, or `82`.

The installers will be accessible at `/opt/installbuilder/output/`.

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

