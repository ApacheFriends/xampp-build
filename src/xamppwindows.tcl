# left:
# phpmyadmin/doc
# FileZillaFTP source code

::itcl::class windowsXamppComponent {
    inherit baseBitnamiProgram
    protected variable xamppoutputdir
    protected variable xamppworkspacedir
    constructor {environment} {
        chain $environment
    } {
    }
    public method needsToBeBuilt {} {
        return 0
    }
    public method copyStackLogoImage {} {}
    public method build {} {}
    public method install {} {
        set xamppoutputdir [file join [$be cget -output] xampp]
        set xamppworkspacedir [file join [$be cget -src] windowsXamppWorkspace xampp]
        extract
        file mkdir $xamppoutputdir
    }

    public method copyFromWorkspace {args} {
        foreach file $args {
            set src [file join $xamppworkspacedir $file]
            set dest [file join $xamppoutputdir $file]
            if {![file exists [file dirname $dest]]} {
                file mkdir [file dirname $dest]
            }
            file copy -force $src $dest
        }
    }

    public method setReadmeVersion {component version} {
        foreach file {readme_de.txt readme_en.txt} {
            xampptcl::util::substituteParametersInFile [file join $xamppoutputdir $file] \
                [list "@@BITROCK_${component}_VERSION@@" $version]
        }
    }
}

::itcl::class windowsXamppWorkspace {
    inherit windowsXamppComponent
    public variable controlPanelVersion
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppWorkspace
        set version 10
        set licenseRelativePath {}
        set rev 15
        set controlPanelVersion "3.3.0"
        set tarballName xampp-windows-workspace-${version}-${rev}.zip
    }
    public method extractDirectory {} {
        return [file join [$be cget -src] windowsXamppWorkspace]
    }
    public method install {} {
        chain
        copyFilesFromWorkspace
        setReadmeVersion CONTROL_PANEL ${controlPanelVersion}
    }
    public method copyFilesFromWorkspace {} {
        copyFromWorkspace cgi-bin/cgi.cgi cgi-bin/perltest.cgi cgi-bin/printenv.pl
        copyFromWorkspace contrib
        copyFromWorkspace htdocs
        copyFromWorkspace install
        copyFromWorkspace licenses
        copyFromWorkspace locale
        copyFromWorkspace src/xampp-control-panel
        copyFromWorkspace src/xampp-mailToDisk
        copyFromWorkspace src/xampp-nsi-installer
        copyFromWorkspace src/xampp-start-stop
        copyFromWorkspace src/xampp-usb-lite

        copyFromWorkspace tmp/why.tmp
        copyFromWorkspace webdav/index.html webdav/webdav.txt

        copyFromWorkspace xampp-control.exe xampp_start.exe xampp_stop.exe
        copyFromWorkspace service.exe
        copyFromWorkspace readme_de.txt readme_en.txt
        copyFromWorkspace setup_xampp.bat
        copyFromWorkspace passwords.txt
    }
}

::itcl::class windowsXamppHtdocs {
    inherit windowsXamppComponent
    protected variable http_prefix
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppHtdocs
        set version 20221122
        set rev 0
        set licenseRelativePath {}
        set tarballName xampp-htdocs-windows-${version}.tar.gz
        # HTTP prefix to use
        set http_prefix /dashboard
    }
    public method extractDirectory {} {
        return [file join [$be cget -src] windowsXamppHtdocs]
    }
    public method install {} {
        chain
        set directory [lindex [glob -directory [extractDirectory] *] 0]
        foreach g [glob -tails -directory $directory -type f \
                       * */* */*/* */*/*/* */*/*/*/* */*/*/*/*/* */*/*/*/*/*/* */*/*/*/*/*/*/* */*/*/*/*/*/*/*/* */*/*/*/*/*/*/*/*/* */*/*/*/*/*/*/*/*/*/* */*/*/*/*/*/*/*/*/*/*/*] {
            set source [file join $directory $g]
            set destination [file join $xamppoutputdir htdocs [string trim $http_prefix /] $g]
            file mkdir [file dirname $destination]
            file copy -force $source $destination
        }
    }
}

::itcl::class windowsXamppVcredist {
    inherit windowsXamppComponent
    public variable vcVersion
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppVcredist
        set version 2008
        set vcVersion 9
        set licenseRelativePath {}
        set tarballName vcredist_x86_${version}.exe
        lappend additionalFileList test_php_VC${vcVersion}.bat
        set mainComponentXMLName xampp-vcredist
        set isReportableAsMainComponent 0
    }
    public method install {} {
        file copy -force [findTarball vcredist_x86_${version}.exe] [file join [$be cget -output] vcredist_x86.exe]
        file copy -force [findTarball test_php_VC${vcVersion}.bat] [file join [$be cget -output] xampp test_php.bat]
    }
}

::itcl::class windowsXamppVcredist2015 {
    inherit windowsXamppVcredist
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppVcredist
        set version 2015
        set vcVersion 14
        set tarballName vcredist_x86_${version}.exe
        lappend additionalFileList test_php_VC${vcVersion}.bat
    }
}

::itcl::class windowsXamppApache {
    inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppApache
        set fullname Apache
        set version [versions::get "Apache" windows]
        set rev 1
        set licenseRelativePath {}
        set tarballName httpd-${version}-win32-VC11.zip
        set mainComponentXMLName xampp-apache
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] Apache24] [file join $xamppoutputdir apache]

        # Remove htdocs and cgi-bin from XAMPP not to confuse users
        file delete -force [file join $xamppoutputdir apache htdocs]
        file delete -force [file join $xamppoutputdir apache cgi-bin]

        xampptcl::file::addTextToFile $xamppoutputdir/apache/conf/httpd.conf \
            "# XAMPP: We disable operating system specific optimizations for a listening\n# socket by the http protocol here. IE 64 bit make problems without this.\n\nAcceptFilter http none\nAcceptFilter https none\n# AJP13 Proxy\n<IfModule mod_proxy.c>\n<IfModule mod_proxy_ajp.c>\nInclude \"conf/extra/httpd-ajp.conf\"\n</IfModule>\n</IfModule>\n"

	xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/httpd.conf [list \
        {ServerRoot ".*"} {ServerRoot "/xampp/apache"} \
        {Define SRVROOT ".*"} {Define SRVROOT "/xampp/apache"} \
        {"\${SRVROOT}/htdocs"} {"/xampp/htdocs"} \
        {"\${SRVROOT}/cgi-bin} {"/xampp/cgi-bin} \
        {#LoadModule access_compat_module modules/mod_access_compat.so} {LoadModule access_compat_module modules/mod_access_compat.so} \
	    {#LoadModule dav_lock_module modules/mod_dav_lock.so} {LoadModule dav_lock_module modules/mod_dav_lock.so} \
	    {#LoadModule headers_module modules/mod_headers.so} {LoadModule headers_module modules/mod_headers.so} \
	    {#LoadModule info_module modules/mod_info.so} {LoadModule info_module modules/mod_info.so} \
	    {#LoadModule lua_module modules/mod_lua.so} "\\0\nLoadModule cache_disk_module modules/mod_cache_disk.so" \
	    {#LoadModule proxy_module modules/mod_proxy.so} {LoadModule proxy_module modules/mod_proxy.so} \
	    {#LoadModule proxy_ajp_module modules/mod_proxy_ajp.so} {LoadModule proxy_ajp_module modules/mod_proxy_ajp.so} \
	    {#LoadModule rewrite_module modules/mod_rewrite.so} {LoadModule rewrite_module modules/mod_rewrite.so} \
	    {#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so} {LoadModule socache_shmcb_module modules/mod_socache_shmcb.so} \
	    {#LoadModule ssl_module modules/mod_ssl.so} {LoadModule ssl_module modules/mod_ssl.so} \
	    {#LoadModule status_module modules/mod_status.so} {LoadModule status_module modules/mod_status.so} \
	    {ServerAdmin admin@example.com} {ServerAdmin postmaster@localhost} \
	    {#ServerName www.example.com:80} {ServerName localhost:80} \
	    {<Directory ".*?/htdocs">} {<Directory "/xampp/htdocs">} \
	    {    Options Indexes FollowSymLinks} {    Options Indexes FollowSymLinks Includes ExecCGI} \
	    {    AllowOverride None} {    AllowOverride All} \
	    {DirectoryIndex index.html} "DirectoryIndex index.php index.pl index.cgi index.asp index.shtml index.html index.htm \\\n                   default.php default.pl default.cgi default.asp default.shtml default.html default.htm \\\n                   home.php home.pl home.cgi home.asp home.shtml home.html home.htm" \
	    {CustomLog "logs/access.log" common} {#CustomLog "logs/access.log" common} \
	    {#CustomLog "logs/access.log" combined} {CustomLog "logs/access.log" combined} \
	    {#AddHandler cgi-script .cgi} {AddHandler cgi-script .cgi .pl .asp} \
	    {#AddType text/html .shtml} {AddType text/html .shtml} \
	    {#AddOutputFilter INCLUDES .shtml} {AddOutputFilter INCLUDES .shtml} \
	    {#MIMEMagicFile conf/magic} "<IfModule mime_magic_module>\n    #\n    # The mod_mime_magic module allows the server to use various hints from the\n    # contents of the file itself to determine its type.  The MIMEMagicFile\n    # directive tells the module where the hint definitions are located.\n    #\n    MIMEMagicFile \"conf/magic\"\n</IfModule>\n" \
	    {#EnableSendfile on} {#EnableSendfile off} \
	    {#Include conf/extra/httpd-mpm.conf} {Include conf/extra/httpd-mpm.conf} \
	    {#Include conf/extra/httpd-autoindex.conf} {Include conf/extra/httpd-autoindex.conf} \
	    {#Include conf/extra/httpd-languages.conf} {Include conf/extra/httpd-languages.conf} \
	    {#Include conf/extra/httpd-userdir.conf} {Include conf/extra/httpd-userdir.conf} \
	    {#Include conf/extra/httpd-info.conf} {Include conf/extra/httpd-info.conf} \
	    {#Include conf/extra/httpd-vhosts.conf} {Include conf/extra/httpd-vhosts.conf} \
	    {#Include conf/extra/httpd-dav.conf} "#Attention! WEB_DAV is a security risk without a new userspecific configuration for a secure authentifcation \n\\0" \
	    {#Include conf/extra/httpd-default.conf} "\\0\n# Implements a proxy/gateway for Apache.\nInclude \"conf/extra/httpd-proxy.conf\"\n# Various default settings\nInclude \"conf/extra/httpd-default.conf\"\n# XAMPP settings\nInclude \"conf/extra/httpd-xampp.conf\"" \
	    {#Include conf/extra/httpd-ssl.conf} {Include conf/extra/httpd-ssl.conf} \
	    ] 1 1

	xampptcl::file::prependTextToFile $xamppoutputdir/apache/conf/extra/httpd-autoindex.conf \
	    "<IfModule autoindex_module>\n<IfModule alias_module>\n"
        xampptcl::file::addTextToFile $xamppoutputdir/apache/conf/extra/httpd-autoindex.conf \
	    "</IfModule>\n</IfModule>"

	xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-autoindex.conf [list \
	    {Alias /icons/ ".*?/icons/"} {Alias /icons/ "/xampp/apache/icons/"} \
	    {<Directory ".*?/icons">} {<Directory "/xampp/apache/icons">} \
	    ] 1 1

	xampptcl::file::prependTextToFile $xamppoutputdir/apache/conf/extra/httpd-dav.conf \
	    "<IfModule dav_module>\n<IfModule dav_fs_module>\n<IfModule setenvif_module>\n<IfModule alias_module>\n<IfModule auth_digest_module>\n<IfModule authn_file_module>"
	xampptcl::file::addTextToFile $xamppoutputdir/apache/conf/extra/httpd-dav.conf \
	    "BrowserMatch \"MSIE\" AuthDigestEnableQueryStringHack=On\n\n</IfModule>\n</IfModule>\n</IfModule>\n</IfModule>\n</IfModule>\n</IfModule>"

	xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-dav.conf [list \
	    "<RequireAny>.*?Require method GET POST OPTIONS.*?Require user admin.*?</RequireAny>" "<LimitExcept GET OPTIONS>\n        require valid-user\n    </LimitExcept>"
	    ] 1

	xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-dav.conf [list \
	    {DavLockDB ".*?"} {DavLockDB "/xampp/apache/logs/Dav.Lock"} \
	    {Alias /uploads ".*?/uploads"} {Alias /webdav "/xampp/webdav/"} \
	    {<Directory ".*?/uploads">} "<Directory \"/xampp/webdav\">\nRequire all granted" \
	    {AuthName DAV-upload} {AuthName "XAMPP with WebDAV"} \
	    ] 1 1

	xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-default.conf [list \
	    {Timeout 60} {Timeout 300} \
	    {ServerSignature Off} {ServerSignature On} \
	    ] 1 1

	xampptcl::file::prependTextToFile $xamppoutputdir/apache/conf/extra/httpd-languages.conf \
	    "<IfModule mime_module>\n<IfModule negotiation_module>\n"
	xampptcl::file::addTextToFile $xamppoutputdir/apache/conf/extra/httpd-languages.conf\
	    "</IfModule>\n</IfModule>"

	xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-vhosts.conf [list \
	    {# VirtualHost example} "# Use name-based virtual hosting.\n#\n##NameVirtualHost *:80\n#\n\\0" \
	    {^<VirtualHost} {##\0} \
	    {(\s+)(ServerAdmin webmaster@)} {\1##\2} \
	    {(\s+)DocumentRoot ".*?/docs/} {\1##DocumentRoot "/xampp/htdocs/} \
	    {(\s+)(ServerName\s)} {\1##\2} \
	    {(\s+)(ServerAlias\s)} {\1##\2} \
	    {(\s+)(ErrorLog\s)} {\1##\2} \
	    {(\s+)(CustomLog\s)} {\1##\2} \
	    {^</VirtualHost} {##\0} \
	    ] 1 1

	xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-multilang-errordoc.conf [list \
	    {Alias /error/ ".*?/error/"} "<IfModule alias_module>\n<IfModule include_module>\n<IfModule negotiation_module>\nAlias /error/ \"/xampp/apache/error/\"" \
	    {<Directory ".*/error">} {<Directory "/xampp/apache/error">} \
	    ] 1 1

	xampptcl::file::addTextToFile $xamppoutputdir/apache/conf/extra/httpd-multilang-errordoc.conf \
	    "</IfModule>\n</IfModule>\n</IfModule>"

	xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-ssl.conf [list \
	    {DocumentRoot ".*/htdocs"} {DocumentRoot "/xampp/htdocs"} \
        {"\${SRVROOT}/logs/} {"/xampp/apache/logs/} \
        {"\${SRVROOT}/cgi-bin} {"/xampp/apache/cgi-bin} \
	    {SSLSessionCache\s.*$} {SSLSessionCache "shmcb:/xampp/apache/logs/ssl_scache(512000)"} \
	    {SSLCertificateFile\s.*$} {SSLCertificateFile "conf/ssl.crt/server.crt"} \
	    {SSLCertificateKeyFile\s.*$} {SSLCertificateKeyFile "conf/ssl.key/server.key"} \
	    ] 1 1

	xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-userdir.conf [list \
	    {Require method GET POST OPTIONS} "    <Limit GET POST OPTIONS>\n        Order allow,deny\n        Allow from all\n    </Limit>\n    <LimitExcept GET POST OPTIONS>\n        Order deny,allow\n        Deny from all\n    </LimitExcept>" \
	    ] 1 1

	xampptcl::file::prependTextToFile $xamppoutputdir/apache/conf/extra/httpd-userdir.conf \
	    "<IfModule userdir_module>\n"
	xampptcl::file::addTextToFile $xamppoutputdir/apache/conf/extra/httpd-userdir.conf \
	    "\n</IfModule>"

	xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-manual.conf [list \
        {"\${SRVROOT}/manual} {"/xampp/apache/manual} \
	    ] 1 1
	xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/mime.types [list \
	    {application/octet-stream\s.*} "application/octet-stream\tbin bpk class deploy dist distz dmg dms dump elc iso lha lrf lzh mar pkg so" \
	    ] 1 1
	copyFilesFromWorkspace
    # T35519 Fix warning message related to SQLite not being properly loaded
    xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list \
       "LoadModule\\s+php5_module" "LoadFile \"/xampp/php/libpq.dll\"\nLoadModule php5_module" \
       "Alias \/security.*Alias \/licenses" "Alias \/licenses" ]
	setReadmeVersion APACHE ${version}
    }
    public method copyFilesFromWorkspace {} {
        copyFromWorkspace apache_start.bat apache_stop.bat
        copyFromWorkspace apache/apache_installservice.bat apache/apache_uninstallservice.bat apache/makecert.bat
        copyFromWorkspace apache/conf/extra/httpd-ajp.conf
        copyFromWorkspace apache/conf/extra/httpd-proxy.conf
        copyFromWorkspace apache/conf/extra/httpd-xampp.conf
        copyFromWorkspace apache/conf/extra/httpd-info.conf
        copyFromWorkspace apache/conf/ssl.crt/server.crt
        copyFromWorkspace apache/conf/ssl.csr/server.csr
        copyFromWorkspace apache/conf/ssl.key/server.key
        copyFromWorkspace apache/error/XAMPP_FORBIDDEN.html.var

        xampptcl::util::substituteParametersInFile [file join $xamppoutputdir apache/makecert.bat] [list bin/openssl.cnf conf/openssl.cnf]
    }
}

::itcl::class windowsXamppApachePhp7 {
    inherit windowsXamppApache
    constructor {environment} {
	chain $environment
    } {
        set version [versions::get "Apache" windows]
        set tarballName httpd-${version}-win32-VC14.zip
    }
    public method install {} {
        chain
        xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list "php5" "php7"]
    }
}
::itcl::class windowsXamppApacheAddons {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppApacheAddons
        set version 1
        set licenseRelativePath {}
        set tarballName xampp-httpd-addons-win32-${version}.zip
        set mainComponentXMLName xampp-apache
    }
    public method install {} {
        chain
        file copy -force [$be cget -src]/xampp-httpd-addons-win32-${version}/bin/pv.exe $xamppoutputdir/apache/bin/pv.exe
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
    }
}


::itcl::class windowsXamppFileZillaFTP {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppFileZillaFTP
        set version 0.9.41
        set licenseRelativePath {}
        set tarballName FileZillaFTP-${version}-win32.zip
        set mainComponentXMLName xampp-filezilla
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] FileZillaFTP] [file join $xamppoutputdir FileZillaFTP]
        # this is really needed - and original XAMPP ships two binaries instead of renaming it
        file copy -force "[file join $xamppoutputdir FileZillaFTP]/FileZilla server.exe" "[file join $xamppoutputdir FileZillaFTP]/FileZillaServer.exe"
        file copy -force "[file join $xamppoutputdir FileZillaFTP]/FileZilla Server.xml" "[file join $xamppoutputdir FileZillaFTP]/FileZillaServer.xml"
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
        copyFromWorkspace filezilla_setup.bat filezilla_start.bat filezilla_stop.bat
        file mkdir $xamppoutputdir/anonymous/incoming
        xampptcl::file::write $xamppoutputdir/anonymous/onefile.html "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">\n<HTML>\n\t<HEAD>\n\t\t<TITLE> One File </TITLE>\n\t</HEAD>\n\n\t<BODY>\n\t\t<CENTER><B>One File!</B></CENTER>\n\t</BODY>\n</HTML>"

    }
}

::itcl::class windowsXamppFileZillaFTPSource {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppFileZillaFTPSource
        set version 0.9.41
        set licenseRelativePath {}
        set tarballName FileZillaFTP-${version}-win32-sourcecode.zip
        set mainComponentXMLName xampp-filezilla
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] FileZillaFTP-source] [file join $xamppoutputdir FileZillaFTP/source]
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
        copyFromWorkspace filezilla_setup.bat filezilla_start.bat filezilla_stop.bat
        file mkdir $xamppoutputdir/anonymous/incoming
        xampptcl::file::write $xamppoutputdir/anonymous/onefile.html "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">\n<HTML>\n\t<HEAD>\n\t\t<TITLE> One File </TITLE>\n\t</HEAD>\n\n\t<BODY>\n\t\t<CENTER><B>One File!</B></CENTER>\n\t</BODY>\n</HTML>"

    }
}

::itcl::class windowsXamppMercuryMail {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppMercuryMail
        set version 4.63
        set licenseRelativePath {}
        set tarballName MercuryMail-${version}-win32.zip
        set mainComponentXMLName xampp-mercury
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] MercuryMail/Programs] [file join $xamppoutputdir MercuryMail]
        file delete -force [file join $xamppoutputdir MercuryMail IERenderer.fff]
        file delete -force [file join $xamppoutputdir MercuryMail IERenderer]
        file mkdir [file join $xamppoutputdir mailoutput]
        foreach d {LOGS QUEUE SCRATCH/MERCURYB SCRATCH/MERCURYD SCRATCH/MERCURYI SCRATCH/MERCURYP} {
            file mkdir [file join $xamppoutputdir MercuryMail $d]
        }
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
        copyFromWorkspace mercury_start.bat mercury_stop.bat
        copyFromWorkspace mailtodisk/bz2.pyd mailtodisk/mailtodisk.exe mailtodisk/mailtodisk.exe.manifest mailtodisk/mfc90.dll mailtodisk/mfc90u.dll mailtodisk/mfcm90.dll mailtodisk/mfcm90u.dll mailtodisk/Microsoft.VC90.CRT.manifest mailtodisk/Microsoft.VC90.MFC.manifest mailtodisk/msvcm90.dll mailtodisk/msvcp90.dll mailtodisk/msvcr90.dll mailtodisk/python27.dll mailtodisk/pythoncom27.dll mailtodisk/PyWinTypes27.dll mailtodisk/README.txt mailtodisk/select.pyd mailtodisk/unicodedata.pyd mailtodisk/win32api.pyd mailtodisk/win32trace.pyd mailtodisk/win32ui.pyd mailtodisk/_hashlib.pyd mailtodisk/_win32sysloader.pyd
    }
}

::itcl::class windowsXamppMercuryMailAddons {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppMercuryMailAddons
        set version 4.63
        set licenseRelativePath {}
        set tarballName xampp-mercurymail-addons-win32-${version}.zip
        set mainComponentXMLName xampp-mercury
    }
    public method install {} {
        chain
        set srcdir [file join [$be cget -src] xampp-mercurymail-addons-win32-${version}]
        foreach g [glob -tails -type f -directory $srcdir * */* */*/* */*/*/* */*/*/*/* */*/*/*/*/* */*/*/*/*/*/* */*/*/*/*/*/*/* */*/*/*/*/*/*/*/* */*/*/*/*/*/*/*/*/* */*/*/*/*/*/*/*/*/*/* */*/*/*/*/*/*/*/*/*/*/*] {
	    file mkdir [file join $xamppoutputdir [file dirname $g]]
	    file copy -force [file join $srcdir $g] [file join $xamppoutputdir $g]
	}
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
    }
}

::itcl::class windowsXamppSendmail {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppSendmail
        set version 32
        set licenseRelativePath {}
        set tarballName fake-sendmail-${version}-win32.zip
        set mainComponentXMLName xampp-sendmail
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] sendmail] [file join $xamppoutputdir sendmail]
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
    }
}

::itcl::class windowsXamppMysql {
  inherit windowsXamppComponent
    public variable pathName
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppMysql
        set version 5.6.26
        set licenseRelativePath {}
        set tarballName mysql-${version}-win32.zip
        set pathName mysql-${version}-win32
        set mainComponentXMLName xampp-mysql
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] $pathName] [file join $xamppoutputdir mysql]
        foreach file [glob -nocomplain -directory [file join $xamppoutputdir mysql] \
	    mysql-test sql-bench lib include \
	    *.pdb */*.pdb */*/*.pdb */*/*/*.pdb */*/*/*/*.pdb */*/*/*/*/*.pdb */*/*/*/*/*/*.pdb */*/*/*/*/*/*/*.pdb */*/*/*/*/*/*/*/*.pdb */*/*/*/*/*/*/*/*/*.pdb \
	    ] {
            file delete -force $file
        }
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
        copyFromWorkspace mysql_start.bat mysql_stop.bat mysql/bin/my.ini
        copyFromWorkspace mysql/mysql_installservice.bat
        copyFromWorkspace mysql/mysql_uninstallservice.bat
        copyFromWorkspace mysql/resetroot.bat
    }
}


::itcl::class windowsXamppMariaDb {
  inherit windowsXamppMysql
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppMariaDb
        set fullname MariaDB
        set version [versions::get "MariaDB" "10"]
        set tarballName mariadb-${version}-win32.zip
        set pathName mariadb-${version}-win32
    }
    public method install {} {
        chain
        xampptcl::util::substituteParametersInFile [file join $xamppoutputdir mysql bin my.ini] [list skip-federated #skip-federated]
        setReadmeVersion MARIADB ${version}
    }

}


::itcl::class windowsXamppMysqlData {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppMysql
        set version 10.4-1
        set licenseRelativePath {}
        set tarballName xampp-mariadbdata-win64-${version}.zip
        set mainComponentXMLName xampp-mysql
    }
    public method install {} {
        chain
        file delete -force [file join $xamppoutputdir mysql/data]
        file copy -force [file join [$be cget -src] mysqldata] [file join $xamppoutputdir mysql/data]
        file copy -force [file join [$be cget -src] mysqldata] [file join $xamppoutputdir mysql/backup]
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
    }
}

::itcl::class windowsXamppMysql55 {
  inherit windowsXamppMysql
    constructor {environment} {
        chain $environment
    } {
        set version 5.5.42
        set tarballName mysql-${version}-win32.zip
    }
}

::itcl::class windowsXamppMysql55Data {
  inherit windowsXamppMysqlData
    constructor {environment} {
        chain $environment
    } {
        set version 55
        set tarballName xampp-mysqldata-win32-${version}.zip
    }
}

::itcl::class windowsXamppPerl {
    inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppPerl
        set version 5.16.3.1
        set licenseRelativePath {}
        set tarballName strawberry-perl-${version}-32bit-portable.zip
        set mainComponentXMLName xampp-perl
    }
    public method extractDirectory {} {
        return [file join [$be cget -src] windowsXamppPerl]
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] windowsXamppPerl/perl] [file join $xamppoutputdir perl]
        copyFilesFromWorkspace

        # replace C:/strawberry with /xampp
        foreach file {perl/lib/CPAN/Config.pm} {
	    # work around read-only mode for certain files
            catch {file attributes [file join $xamppoutputdir $file] -permissions 0644}
            xampptcl::util::substituteParametersInFile [file join $xamppoutputdir $file] [list C:/strawberry /xampp]
        }

        # get a list of the .bat files in perl dinamically
        set cwd [pwd]
        cd $xamppoutputdir
        set batFiles [glob [file join perl/bin *.bat]]
        cd $cwd
        # add some other required files
        set perlScripts [concat $batFiles perl/bin/pod2latex perl/lib/Config_heavy.pl perl/vendor/lib/ppm.xml]
        # replace C:\strawberry with \xampp
        foreach file $perlScripts {
            # work around read-only mode for certain files
            catch {file attributes [file join $xamppoutputdir $file] -permissions 0644}
            xampptcl::util::substituteParametersInFile [file join $xamppoutputdir $file] [list C:\\strawberry \\xampp]
	}
        # replace C:\\strawberry with \\xampp
        foreach file {perl/lib/CPAN/Config.pm perl/lib/CORE/config.h perl/lib/Config.pm} {
            # work around read-only mode for certain files
            catch {file attributes [file join $xamppoutputdir $file] -permissions 0644}
            xampptcl::util::substituteParametersInFile [file join $xamppoutputdir $file] [list C:\\\\strawberry \\\\xampp]
        }
    }
    public method copyFilesFromWorkspace {} {
    }
}

::itcl::class windowsXamppPerlAddons {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppPerlAddons
        set version 1
        set licenseRelativePath {}
        set tarballName xampp-perl-addons-win32-${version}.zip
        lappend additionalFileList xampp-perl-addons-win32-${version}.patch
        set mainComponentXMLName xampp-perl
    }
    public method install {} {
        chain
        set srcdir [file join [$be cget -src] xampp-perl-addons-win32-${version}]
        set patchFile [findPatch xampp-perl-addons-win32-${version}.patch]
        foreach file {
            lib/HTML
        } {
            file copy -force [file join $srcdir $file] [file join $xamppoutputdir perl $file]
        }
        set wd [pwd]
        cd [file join $xamppoutputdir]
        logexec patch -p0 <$patchFile
        cd $wd
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
    }
}

::itcl::class windowsXamppPhp {
    inherit windowsXamppComponent
    public variable vcVersion
    public variable opensslVersion
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppPhp
        set fullname PHP
        set version [::xampp::php::getXAMPPVersion 55]
        set vcVersion VC11
        set opensslVersion 1.0.2j
        set licenseRelativePath {}
        set tarballName php-${version}-Win32-${vcVersion}-x86.zip
        set mainComponentXMLName xampp-php
    }
    public method extractDirectory {} {
        return [file join [$be cget -src] windowsXamppPhp]
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] windowsXamppPhp] [file join $xamppoutputdir php]
        file copy -force [file join [$be cget -src] windowsXamppPhp php.ini-development] [file join $xamppoutputdir php php.ini]

        foreach f [glob -directory [file join [$be cget -src] windowsXamppPhp] icu*.dll libsasl.dll] {
            file copy -force $f [file join $xamppoutputdir apache bin]
        }

        phpiniSubstitutions
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
        copyFromWorkspace php/webdriver-test-example.php
        copyFromWorkspace php/phpunit php/phpunit.bat
    }
    public method phpiniSubstitutions {} {
        if { [file exists $xamppoutputdir/php/ext/php_ftp.dll] } {
            xampptcl::util::substituteParametersInFile $xamppoutputdir/php/php.ini \
                [list {; Module Settings ;
;;;;;;;;;;;;;;;;;;;} {; Module Settings ;
;;;;;;;;;;;;;;;;;;;
extension=php_ftp.dll}]
            }
        if { [file exists $xamppoutputdir/php/ext/php_mysql.dll] } {
            xampptcl::util::substituteParametersInFile $xamppoutputdir/php/php.ini \
                [list \
                     {;extension=php_mysql.dll} {extension=php_mysql.dll} \
                ]
        }
        xampptcl::util::substituteParametersInFile $xamppoutputdir/php/php.ini \
            [list \
            {;extension_dir = "ext"} {extension_dir = "\xampp\php\ext"} \
            {; extension_dir = "ext"} {extension_dir = "\xampp\php\ext"} \
            {;upload_tmp_dir =} {upload_tmp_dir = "\xampp\tmp"} \
            {;browscap = extra/browscap.ini} {browscap = "\xampp\php\extras\browscap.ini"} \
            {;session.save_path = "/tmp"} {session.save_path = "\xampp\tmp"} \
            {;session.entropy_length = 32} {session.entropy_length = 0} \
            {;extension=php_exif.dll} {extension=php_exif.dll} \
            {;extension=exif} {extension=exif} \
            {;extension=php_fileinfo.dll} {extension=php_fileinfo.dll} \
            {;extension=fileinfo} {extension=fileinfo} \
            {;extension=php_mbstring.dll} {extension=php_mbstring.dll} \
            {;extension=mbstring} {extension=mbstring} \
            {;extension=php_curl.dll} {extension=php_curl.dll} \
            {;extension=curl} {extension=curl} \
            {;extension=php_bz2.dll} {extension=php_bz2.dll} \
            {;extension=bz2} {extension=bz2} \
            {;extension=php_gd2.dll} {extension=php_gd2.dll} \
            {;extension=gd2} {extension=gd2} \
            {;extension=php_gettext.dll} {extension=php_gettext.dll} \
            {;extension=gettext} {extension=gettext} \
            {;extension=php_mysqli.dll} {extension=php_mysqli.dll} \
            {;extension=mysqli} {extension=mysqli} \
            {;extension=php_pdo_mysql.dll} {extension=php_pdo_mysql.dll} \
            {;extension=pdo_mysql} {extension=pdo_mysql} \
            {;extension=php_pdo_sqlite.dll} {extension=php_pdo_sqlite.dll} \
            {;extension=pdo_sqlite} {extension=pdo_sqlite} \
            {;include_path = ".:/php/includes"} {include_path = \xampp\php\PEAR} \
            {;curl.cainfo =} {curl.cainfo = "\xampp\apache\bin\curl-ca-bundle.crt"} \
            {;openssl.cafile=} {openssl.cafile = "\xampp\apache\bin\curl-ca-bundle.crt"} \
            {; Module Settings ;
;;;;;;;;;;;;;;;;;;;} {; Module Settings ;
;;;;;;;;;;;;;;;;;;;
asp_tags=Off
display_startup_errors=On
track_errors=Off
y2k_compliance=On
allow_call_time_pass_reference=Off
safe_mode=Off
safe_mode_gid=Off
safe_mode_allowed_env_vars=PHP_
safe_mode_protected_env_vars=LD_LIBRARY_PATH
error_log="\xampp\php\logs\php_error_log"
register_globals=Off
register_long_arrays=Off
magic_quotes_gpc=Off
magic_quotes_runtime=Off
magic_quotes_sybase=Off
extension=php_openssl.dll} \
            {[Pdo]} {[Pdo]
pdo_mysql.default_socket="MySQL"} \
        ]
        puts "substituting $xamppoutputdir/php/php.ini"
        # Some applications require higher limits, such as WordPress for uploading big images
        xampptcl::util::substituteParametersInFileRegex $xamppoutputdir/php/php.ini [list \
            {\nmax_execution_time = [^\n]+} "\nmax_execution_time = 120" \
            {\nmemory_limit = [^\n]+} "\nmemory_limit = 512M" \
            {\npost_max_size = [^\n]+} "\npost_max_size = 40M" \
            {\nupload_max_filesize = [^\n]+} "\nupload_max_filesize = 40M" \
        ] 1

        xampptcl::file::addTextToFile $xamppoutputdir/php/php.ini "\[Syslog\]
define_syslog_variables=Off
\[Session\]
define_syslog_variables=Off
\[Date\]
date.timezone=Europe/Berlin
\[MySQL\]
mysql.allow_local_infile=On
mysql.allow_persistent=On
mysql.cache_size=2000
mysql.max_persistent=-1
mysql.max_link=-1
mysql.default_port=3306
mysql.default_socket=\"MySQL\"
mysql.connect_timeout=3
mysql.trace_mode=Off
\[Sybase-CT\]
sybct.allow_persistent=On
sybct.max_persistent=-1
sybct.max_links=-1
sybct.min_server_severity=10
sybct.min_client_severity=10
\[MSSQL\]
mssql.allow_persistent=On
mssql.max_persistent=-1
mssql.max_links=-1
mssql.min_error_severity=10
mssql.min_message_severity=10
mssql.compatability_mode=Off
mssql.secure_connection=Off"
    }

}

::itcl::class windowsXamppPhp7 {
  inherit windowsXamppPhp
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppPhp7
        set vcVersion VC14
        set opensslVersion [versions::get "OpenSSL" stable]
        set tarballName php-${version}-Win32-${vcVersion}-x86.zip
    }
}

::itcl::class windowsXamppPhp74 {
  inherit windowsXamppPhp7
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppPhp74
        set version [::xampp::php::getXAMPPVersion 74]
        set rev [::xampp::php::getXAMPPRevision 74]
        set vcVersion VC15
        set opensslVersion 1.1.0g
        set tarballName php-${version}-Win32-${vcVersion}-x86.zip
    }
}

::itcl::class windowsXamppPhp80 {
  inherit windowsXamppPhp7
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppPhp80
        set version [::xampp::php::getXAMPPVersion 80]
        set rev [::xampp::php::getXAMPPRevision 80]
        set vcVersion VS16
        set opensslVersion 1.1.0g
        set tarballName php-${version}-Win32-${vcVersion}-x86.zip
    }
}

::itcl::class windowsXamppPhp81 {
  inherit windowsXamppPhp7
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppPhp81
        set version [::xampp::php::getXAMPPVersion 81]
        set rev [::xampp::php::getXAMPPRevision 81]
        set vcVersion VS16
        set opensslVersion 1.1.0g
        set tarballName php-${version}-Win32-${vcVersion}-x86.zip
    }
}

::itcl::class windowsXamppPhpAddons {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppPhpAddons
        set version 1
        set licenseRelativePath {}
        set tarballName xampp-php-addons-win32-${version}.zip
        set mainComponentXMLName xampp-php
    }
    public method install {} {
        chain
	foreach path {fonts mibs openssl browscap.ini} {
	    file copy -force [file join [$be cget -src] xampp-php-addons-win32-${version}/php/extras $path] \
		[file join $xamppoutputdir php extras $path]
	}
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
    }
}

::itcl::class windowsXamppPhpPear {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppPhpPear
        set fulname PEAR
        set version 1.10.1
        set licenseRelativePath {}
        set tarballName xampp-pear-win32-${version}.zip
        set mainComponentXMLName xampp-php
    }
    public method install {} {
        chain
	set dir [file join [$be cget -src] xampp-pear-win32-${version}]
	foreach f [glob -directory $dir -tails *] {
	    file copy -force [file join $dir $f] [file join $xamppoutputdir php/$f]
	}
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
    }
}

::itcl::class windowsXamppCurl {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppCurl
        set version 7.47.1
        set licenseRelativePath {}
        set tarballName curl-win32-${version}.zip
        set cacertificatesVersion [getVtrackerField cacertificates version frameworks]
        lappend additionalFileList curl-ca-bundle-${cacertificatesVersion}.crt
        set mainComponentXMLName xampp-apache
    }
    public method install {} {
        chain
        set curlDir [file join $xamppoutputdir apache bin]
        file mkdir $curlDir
        set cacertificatesVersion [getVtrackerField cacertificates version frameworks]
        file copy -force [findFile curl-ca-bundle-${cacertificatesVersion}.crt] [file join $curlDir curl-ca-bundle.crt]
        file copy -force [file join [$be cget -src] curl curl.exe] [file join $curlDir curl.exe]
    }
    public method copyFilesFromWorkspace {} {}
}

::itcl::class windowsXamppPhpADODB {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppPhpADODB
        set version 518a
        set licenseRelativePath {}
        set tarballName adodb${version}.zip
        set mainComponentXMLName xampp-php
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] adodb5] [file join $xamppoutputdir php/pear/adodb]
        copyFilesFromWorkspace
        setReadmeVersion ADODB ${version}
    }
    public method copyFilesFromWorkspace {} {
    }
}

::itcl::class windowsXamppPhpXdebug {
  inherit windowsXamppComponent
    protected variable tarballBaseName {}
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppPhpXdebug
        set version 2.2.5-5.5
        set licenseRelativePath {}
        set tarballBaseName php_xdebug-${version}-vc11
        set tarballName $tarballBaseName.zip
        set mainComponentXMLName xampp-php
    }
    public method extractDirectory {} {
        return [file join [$be cget -src] xdebug]
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] xdebug/$tarballBaseName.dll] [file join $xamppoutputdir php/ext/php_xdebug.dll]
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
    }
}

::itcl::class windowsXamppPhpMyAdmin {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppPhpMyAdmin
        set fullname phpMyAdmin
        set version [getVtrackerField phpMyAdmin version frameworks]
        set licenseRelativePath {}
        set tarballName phpMyAdmin-${version}-all-languages
        set mainComponentXMLName xampp-phpmyadmin
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] phpMyAdmin-${version}-all-languages] [file join $xamppoutputdir phpMyAdmin]
        copyFilesFromWorkspace
        setReadmeVersion PHPMYADMIN ${version}
    }
    public method copyFilesFromWorkspace {} {
        copyFromWorkspace phpMyAdmin/config.inc.php
    }
}

::itcl::class windowsXamppTomcat {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppTomcat
        set version [versions::get "Tomcat" "85"]
        set licenseRelativePath {}
        set tarballName apache-tomcat-${version}-windows-x86.zip
        set mainComponentXMLName xampp-tomcat
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] apache-tomcat-${version}] [file join $xamppoutputdir tomcat]
        copyFilesFromWorkspace
        setReadmeVersion TOMCAT ${version}
    }
    public method copyFilesFromWorkspace {} {
        copyFromWorkspace catalina_service.bat catalina_start.bat catalina_stop.bat
        copyFromWorkspace tomcat/catalina_start.bat tomcat/catalina_stop.bat tomcat/tomcat_service_install.bat tomcat/tomcat_service_uninstall.bat
    }
}

::itcl::class windowsXamppWebalizer {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppWebalizer
        set version 2.23-04
        set licenseRelativePath {}
        set tarballName webalizer-${version}-cygwin.zip
        set mainComponentXMLName xampp-webalizer
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] webalizer-${version}-cygwin] [file join $xamppoutputdir webalizer]
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
        copyFromWorkspace webalizer/webalizer.conf
    }
}

::itcl::class windowsXamppWebalizerAddons {
  inherit windowsXamppComponent
    constructor {environment} {
        chain $environment
    } {
        set name windowsXamppWebalizerAddons
        set version 1
        set licenseRelativePath {}
        set tarballName xampp-webalizer-addons-${version}.zip
        set mainComponentXMLName xampp-webalizer
    }
    public method install {} {
        chain
        file copy -force [file join [$be cget -src] xampp-webalizer-addons/bgd.dll] [file join $xamppoutputdir webalizer]
        file copy -force [file join [$be cget -src] xampp-webalizer-addons/zlib1.dll] [file join $xamppoutputdir webalizer]
        file copy -force [file join [$be cget -src] xampp-webalizer-addons/webalizer.bat] [file join $xamppoutputdir webalizer]
        file copy -force [file join [$be cget -src] xampp-webalizer-addons/webalizer.php] [file join $xamppoutputdir webalizer]
        copyFilesFromWorkspace
    }
    public method copyFilesFromWorkspace {} {
    }
}

::itcl::class windowsXamppStandard {
    inherit windowsXamppComponent
    protected variable rev 0
    protected variable xampp_vcredist_name VC11
    constructor {environment} {
        chain $environment
    } {
        set name xampp
        set version [::xampp::php::getXAMPPVersion 55]
        set rev [::xampp::php::getXAMPPRevision 55]
        set licenseRelativePath {}
        set tarballName {}
    }
    public method findTarball {{file {}}} {
	# to allow proper building in the cloud
	return ""
    }
    public method getTextFiles {} {}
    public method getProgramFiles {} {
        return [lremove [chain] [list scripts conf]]
    }
    public method srcdir {} {
	return [file join [$be cget -src] xampp]
    }
    public method install {} {
	set xamppoutputdir [file join [$be cget -output] xampp]
	set xamppDoubleSlash [string map [list \\ \\\\] [file nativename [file normalize $xamppoutputdir]]]
	set outputDoubleSlash [string map [list \\ \\\\] [file nativename [file normalize [$be cget -output]]]]

	set fh [open [file join $xamppoutputdir htdocs/xampp/.version] w]
	puts $fh $version
	close $fh


	foreach f [glob -directory [file join $xamppoutputdir htdocs] *.html */*.html */*/*.html */*/*/*.html */*/*/*/*.html */*/*/*/*/*.html] {
	    xampptcl::util::substituteParametersInFile $f [list \
		{@@XAMPP_VERSION@@} $version]
	}

	xampptcl::util::substituteParametersInFileRegex [file join $xamppoutputdir install/.version] [list \
	    {\$xamppversion.*} "\$xamppversion = \"$version\"" \
	    ] 0 1
	foreach file {
	    readme_en.txt
	    readme_de.txt
	} {
	    xampptcl::util::substituteParametersInFileRegex [file join $xamppoutputdir $file] [list \
		{^.*ApacheFriends XAMPP Version.*} "###### ApacheFriends XAMPP Version $version ######" \
		] 0 1
	}

	if {[file exists [file join $xamppoutputdir php/libssh2.dll]]} {
	    file copy -force [file join $xamppoutputdir php/libssh2.dll] [file join $xamppoutputdir apache/bin/libssh2.dll]
	}
    foreach f [glob [file join [$be cget -output] htdocs-xampp *]] {
        file copy -force $f [file join $xamppoutputdir htdocs]
    }

	packSvnExport
	packXampp

    # Removing security folder
    set xamppoutputdir [file join [$be cget -output] xampp]
    file delete -force [file join $xamppoutputdir security]
    }

    public method packXampp {} {
	if {![info exists ::env(COMPRESSIONALGORITHM)] || ($::env(COMPRESSIONALGORITHM) != "zip")} {
	    set xamppName "xampp-windows-x64-${version}-${rev}-${xampp_vcredist_name}"

	    set wd [pwd]
	    cd [$be cget -output]
	    # logexec 7z a -tzip -mx9 -md=32k -mfb=128 -mpass=10 -mem=AES256 $xamppName.zip xampp
	    # logexec 7z a -t7z -mx=9 -mfb=64 -md=64m -ms=on $xamppName.7z xampp
	    logexec 7z a -tzip $xamppName.zip xampp
	    logexec 7z a -t7z  $xamppName.7z xampp

	    puts "RESULT FILE: \"[file join [pwd] $xamppName.zip]\""
	    puts "RESULT FILE: \"[file join [pwd] $xamppName.7z]\""

	    cd $wd
	}
    }

    public method packSvnExport {} {
	# get list of files to store for SVN export
	if {![info exists ::env(COMPRESSIONALGORITHM)] || ($::env(COMPRESSIONALGORITHM) != "zip")} {
	    set exportFilelist [glob -nocomplain -tails -type f -directory [file join [$be cget -src] windowsXamppWorkspace] \
		xampp/* xampp/*/* xampp/*/*/* xampp/*/*/*/* xampp/*/*/*/*/* xampp/*/*/*/*/*/* \
		xampp/*/*/*/*/*/*/* xampp/*/*/*/*/*/*/*/* xampp/*/*/*/*/*/*/*/*/* xampp/*/*/*/*/*/*/*/*/*/* \
		xampp/*/*/*/*/*/*/*/*/*/*/* xampp/*/*/*/*/*/*/*/*/*/*/*/* xampp/*/*/*/*/*/*/*/*/*/*/*/*/*]

	    set wd [pwd]
	    cd [$be cget -output]
	    # eval logexec 7z a -tzip -mx9 -md=32k -mfb=128 -mpass=10 -mem=AES256 xampp-workspace-svn-export.zip $exportFilelist
	    eval logexec 7z a -tzip xampp-workspace-svn-export.zip $exportFilelist

	    puts "RESULT FILE: \"[file join [pwd] xampp-workspace-svn-export.zip]\""

	    cd $wd
	}
    }
}

::itcl::class windowsXamppStandardPhp7 {
    inherit windowsXamppStandard
    constructor {environment} {
	chain $environment
        set xampp_vcredist_name VC14
    } {
    }
    public method packSvnExport {} {
	# get list of files to store for SVN export
	if {![info exists ::env(COMPRESSIONALGORITHM)] || ($::env(COMPRESSIONALGORITHM) != "zip")} {
	    set exportFilelist [glob -nocomplain -tails -type f -directory [file join [$be cget -src] windowsXamppWorkspace] \
		xampp/* xampp/*/* xampp/*/*/* xampp/*/*/*/* xampp/*/*/*/*/* xampp/*/*/*/*/*/* \
		xampp/*/*/*/*/*/*/* xampp/*/*/*/*/*/*/*/* xampp/*/*/*/*/*/*/*/*/* xampp/*/*/*/*/*/*/*/*/*/* \
		xampp/*/*/*/*/*/*/*/*/*/*/* xampp/*/*/*/*/*/*/*/*/*/*/*/* xampp/*/*/*/*/*/*/*/*/*/*/*/*/*]
        set exportFilelist [listFilter $exportFilelist [list *phpunit*]]

	    set wd [pwd]
	    cd [$be cget -output]
	    # eval logexec 7z a -tzip -mx9 -md=32k -mfb=128 -mpass=10 -mem=AES256 xampp-workspace-svn-export.zip $exportFilelist
	    eval logexec 7z a -tzip xampp-workspace-svn-export.zip $exportFilelist

	    puts "RESULT FILE: \"[file join [pwd] xampp-workspace-svn-export.zip]\""

	    cd $wd
	}
    }
}

::itcl::class windowsXamppStandardPhp74 {
    inherit windowsXamppStandardPhp7
    constructor {environment} {
	chain $environment
        set version [::xampp::php::getXAMPPVersion 74]
        set rev [::xampp::php::getXAMPPRevision 74]
        set xampp_vcredist_name VC15
    } {
    }
}

::itcl::class windowsXamppStandardPhp80 {
    inherit windowsXamppStandardPhp7
    constructor {environment} {
	chain $environment
        set version [::xampp::php::getXAMPPVersion 80]
        set rev [::xampp::php::getXAMPPRevision 80]
        set xampp_vcredist_name VS16
    } {
    }
}

::itcl::class windowsXamppStandardPhp81 {
    inherit windowsXamppStandardPhp7
    constructor {environment} {
	chain $environment
        set version [::xampp::php::getXAMPPVersion 81]
        set rev [::xampp::php::getXAMPPRevision 81]
        set xampp_vcredist_name VS16
    } {
    }
}

::itcl::class windowsXamppStandardPhp82 {
    inherit windowsXamppStandardPhp7
    constructor {environment} {
	chain $environment
        set version [::xampp::php::getXAMPPVersion 82]
        set rev [::xampp::php::getXAMPPRevision 82]
        set xampp_vcredist_name VS16
    } {
    }
}

::itcl::class windowsXamppPortable {
    inherit windowsXamppComponent
    protected variable rev 0
    protected variable xampp_vcredist_name VC11
    constructor {environment} {
        chain $environment
    } {
        set name xampp
        set version [::xampp::php::getXAMPPVersion 55]
        set rev [::xampp::php::getXAMPPRevision 55]
        set licenseRelativePath {}
        set tarballName {}
        #set dependencies {xampp {xampp.xml}}
    }
    public method findTarball {{file {}}} {
        # to allow proper building in the cloud
        return ""
    }
    public method getTextFiles {} {}
    public method getProgramFiles {} {
        return [lremove [chain] [list scripts conf]]
    }
    public method srcdir {} {
	return [file join [$be cget -src] xampp]
    }
    public method install {} {
	set xamppoutputdir [file join [$be cget -output] xampp]

	foreach deletefile {
	    anonymous
	    src
	    mysql/mysql-test
	    mysql/sql-bench
	    mysql/scripts
	    mysql/include
	    mysql/lib
	    filezilla_setup.bat
	    filezilla_start.bat
	    filezilla_stop.bat
	    mercury_start.bat
	    mercury_stop.bat
	    service.exe
	    apache/apache_installservice.bat
	    apache/apache_uninstallservice.bat
	    mysql/mysql_installservice.bat
	    mysql/mysql_uninstallservice.bat
	    htdocs/xampp/.modell
	    setup_xampp.bat
	} {
	    file delete -force [file join $xamppoutputdir $deletefile]
	}

        set fh [open [file join $xamppoutputdir htdocs/xampp/.version] w]
        puts $fh $version
        close $fh

	foreach f [glob -directory [file join $xamppoutputdir htdocs] *.html */*.html */*/*.html */*/*/*.html */*/*/*/*.html */*/*/*/*/*.html] {
	    xampptcl::util::substituteParametersInFile $f [list \
		{@@XAMPP_VERSION@@} $version]
	}

	file copy [$be cget -src]/windowsXamppWorkspace/xampp/src/xampp-usb-lite/setup_xampp.bat $xamppoutputdir/setup_xampp.bat
	file copy [$be cget -src]/windowsXamppWorkspace/xampp/src/xampp-usb-lite/xampp-control.ini $xamppoutputdir/xampp-control.ini

	xampptcl::util::substituteParametersInFileRegex [file join $xamppoutputdir/readme_en.txt] [list \
	    {^.*ApacheFriends XAMPP Version.*} "###### ApacheFriends XAMPP Version $version ######\r\n \r\nNote: The Portable Version does not contain the FileZilla FTP and the Mercury Mail Server. The service installations are also disabled here.\r\n" \
	    ] 0 1

	xampptcl::util::substituteParametersInFileRegex [file join $xamppoutputdir/readme_de.txt] [list \
	    {^.*ApacheFriends XAMPP Version.*} "###### ApacheFriends XAMPP Version $version ######\r\n \r\nHinweis: Die Portable Version enth\u00e4lt nicht den FileZilla FTP und den Mercury Mail Server. Die Installation als Dienste sind ebenfalls deaktiviert.\r\n" \
           ] 0 1
        file copy -force $xamppoutputdir/htdocs/xampp/.modell-usb $xamppoutputdir/htdocs/xampp/.modell

	# so that we can reuse same set of components
	file mkdir $xamppoutputdir/MercuryMail
	file mkdir $xamppoutputdir/FileZillaFTP
	file mkdir $xamppoutputdir/webalizer

	if {[file exists [file join $xamppoutputdir php/libssh2.dll]]} {
	    file copy -force [file join $xamppoutputdir php/libssh2.dll] [file join $xamppoutputdir apache/bin/libssh2.dll]
	}
    foreach f [glob [file join [$be cget -output] htdocs-xampp *]] {
        file copy -force $f [file join $xamppoutputdir htdocs]
    }

	packXampp
    }

    public method packXampp {} {
	set xamppName "xampp-portable-windows-x64-${version}-${rev}-${xampp_vcredist_name}"

	set wd [pwd]
	cd [$be cget -output]

	# logexec 7z a -tzip -mx9 -md=32k -mfb=128 -mpass=10 -mem=AES256 $xamppName.zip xampp
	# logexec 7z a -t7z -mx=9 -mfb=64 -md=64m -ms=on $xamppName.7z xampp
	logexec 7z a -tzip $xamppName.zip xampp
	logexec 7z a -t7z $xamppName.7z xampp

	puts "RESULT FILE: \"[file join [pwd] $xamppName.zip]\""
	puts "RESULT FILE: \"[file join [pwd] $xamppName.7z]\""

	cd $wd
    }
}

::itcl::class windowsXamppPortablePhp7 {
    inherit windowsXamppPortable
    constructor {environment} {
        chain $environment
        set xampp_vcredist_name VC14
    } {
    }
}



::itcl::class windowsXamppPortablePhp74 {
    inherit windowsXamppPortablePhp7
    constructor {environment} {
        chain $environment
        set version [::xampp::php::getXAMPPVersion 74]
        set rev [::xampp::php::getXAMPPRevision 74]
        set xampp_vcredist_name VC15
    } {
    }
}

::itcl::class windowsXamppPortablePhp8 {
    inherit windowsXamppPortable
    constructor {environment} {
        chain $environment
        set xampp_vcredist_name VS16
    } {
    }
    public method packXampp {} {
        # PHP 8.0 is installed as 'php_module', and portable classes don't run the preparefordist method
        xampptcl::util::substituteParametersInFile $xamppoutputdir/apache/conf/extra/httpd-xampp.conf [list "php8_module" "php_module"]
        chain
    }
}

::itcl::class windowsXamppPortablePhp80 {
    inherit windowsXamppPortablePhp8
    constructor {environment} {
        chain $environment
        set version [::xampp::php::getXAMPPVersion 80]
        set rev [::xampp::php::getXAMPPRevision 80]
    } {
    }
}

::itcl::class windowsXamppPortablePhp81 {
    inherit windowsXamppPortablePhp8
    constructor {environment} {
        chain $environment
        set version [::xampp::php::getXAMPPVersion 81]
        set rev [::xampp::php::getXAMPPRevision 81]
    } {
    }
}

::itcl::class windowsXamppPortablePhp82 {
    inherit windowsXamppPortablePhp8
    constructor {environment} {
        chain $environment
        set version [::xampp::php::getXAMPPVersion 82]
        set rev [::xampp::php::getXAMPPRevision 82]
    } {
    }
}

::itcl::class windowsXamppInstallerStack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windowsXamppVcredist \
	    windowsXamppApache \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windowsXamppMariaDb \
	    windowsXamppMysqlData \
	    windowsXamppPerl \
	    windowsXamppPerlAddons \
	    windowsXamppPhp \
	    windowsXamppPhpAddons \
	    windowsXamppPhpXdebug \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windowsXamppCurl \
	    windowsXamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
	    windowsXamppStandard
    }
}


::itcl::class windowsXamppInstallerPhp74Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windowsXamppVcredist2015 \
	    windowsXamppApachePhp74 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windowsXamppMariaDb \
	    windowsXamppMysqlData \
	    windowsXamppPerl \
	    windowsXamppPerlAddons \
	    windowsXamppPhp74 \
	    windowsXamppPhpAddons \
	    windowsXamppPhpMyAdmin \
	    windowsXamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
	    windowsXamppStandardPhp74
    }
}

::itcl::class windowsXamppInstallerPhp80Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windowsXamppVcredist2015 \
	    windowsXamppApachePhp80 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windowsXamppMariaDb \
	    windowsXamppMysqlData \
	    windowsXamppPerl \
	    windowsXamppPerlAddons \
	    windowsXamppPhp80 \
	    windowsXamppPhpAddons \
	    windowsXamppPhpMyAdmin \
	    windowsXamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
	    windowsXamppStandardPhp80
    }
}

::itcl::class windowsXamppInstallerPhp81Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windowsXamppVcredist2015 \
	    windowsXamppApachePhp81 \
	    windowsXamppApacheAddons \
	    windowsXamppFileZillaFTP \
	    windowsXamppFileZillaFTPSource \
	    windowsXamppMercuryMail \
	    windowsXamppMercuryMailAddons \
	    windowsXamppSendmail \
	    windowsXamppMariaDb \
	    windowsXamppMysqlData \
	    windowsXamppPerl \
	    windowsXamppPerlAddons \
	    windowsXamppPhp81 \
	    windowsXamppPhpAddons \
	    windowsXamppPhpMyAdmin \
	    windowsXamppCurl \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppTomcat \
	    windowsXamppWebalizer \
	    windowsXamppWebalizerAddons \
	    windowsXamppStandardPhp81
    }
}

::itcl::class windowsXamppPortableInstallerStack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windowsXamppVcredist \
	    windowsXamppApache \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windowsXamppMariaDb \
	    windowsXamppMysqlData \
	    windowsXamppPerl \
	    windowsXamppPerlAddons \
	    windowsXamppPhp \
	    windowsXamppPhpAddons \
	    windowsXamppPhpXdebug \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windowsXamppCurl \
	    windowsXamppTomcat \
	    windowsXamppPortable
    }
}

::itcl::class windowsXamppPortableInstallerPhp74Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windowsXamppVcredist2015 \
	    windowsXamppApachePhp74 \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windowsXamppMariaDb \
	    windowsXamppMysqlData \
	    windowsXamppPerl \
	    windowsXamppPerlAddons \
	    windowsXamppPhp74 \
	    windowsXamppPhpAddons \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windowsXamppCurl \
	    windowsXamppTomcat \
	    windowsXamppPortablePhp74
    }
}

::itcl::class windowsXamppPortableInstallerPhp80Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windowsXamppVcredist2015 \
	    windowsXamppApachePhp80 \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windowsXamppMariaDb \
	    windowsXamppMysqlData \
	    windowsXamppPerl \
	    windowsXamppPerlAddons \
	    windowsXamppPhp80 \
	    windowsXamppPhpAddons \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windowsXamppCurl \
	    windowsXamppTomcat \
	    windowsXamppPortablePhp80
    }
}

::itcl::class windowsXamppPortableInstallerPhp81Stack {
    inherit stack
       constructor {environment} {
        chain $environment
    } {
	addComponents bitnamiFiles nativeadapter windowsXamppWorkspace \
	    windowsXamppHtdocs \
	    windowsXamppVcredist2015 \
	    windowsXamppApachePhp81 \
	    windowsXamppApacheAddons \
	    windowsXamppSendmail \
	    windowsXamppMariaDb \
	    windowsXamppMysqlData \
	    windowsXamppPerl \
	    windowsXamppPerlAddons \
	    windowsXamppPhp81 \
	    windowsXamppPhpAddons \
	    windowsXamppPhpPear \
	    windowsXamppPhpADODB \
	    windowsXamppPhpMyAdmin \
	    windowsXamppCurl \
	    windowsXamppTomcat \
	    windowsXamppPortablePhp81
    }
}
