set additionalOutputDirectory [lindex $argv 0]
set htmlFilePrefix ""

if {($additionalOutputDirectory != "") && (![regexp {^s3://} $additionalOutputDirectory]) && [file exists $additionalOutputDirectory]} {
    puts "\[generateScreenshotsHtmlFile\] Additional output directories found: [glob -tails -nocomplain -directory $additionalOutputDirectory *]"

    # Get all the tarballs containing casper results (from all the test machines)
    set casperJSScreenShots [glob -tails -nocomplain -directory $additionalOutputDirectory casper-screenshots-*.tar.gz]
    puts "\[generateScreenshotsHtmlFile\] CasperJS screenshot tarballs found: $casperJSScreenShots"

    # Path to folder containing the casper's screenshots results
    set resultPath casperjs

    if {[llength $casperJSScreenShots] != 0} {
        set wd [pwd]
        # For each casper tarball, uncompress and remove
        foreach casperTarball $casperJSScreenShots {
            cd $additionalOutputDirectory
            # Auxiliary CasperJS results folder
            file mkdir [file join $additionalOutputDirectory $resultPath]
            # Uncompress
            exec tar -xzf $casperTarball -C $resultPath 2>@1
            # Remove tarball
            file delete $casperTarball
        }

        # The code below will take care of screenshots only
        set imghtml {<html>
<head>
<style type="text/css">
.preview img { position:absolute; display:none; z-index:99; }
.preview:hover img { display:inline-block; border:1px solid #eeeeee; }
</style>
<link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Dosis">
<link rel="stylesheet" href="https://d1d5nb8vlsbujg.cloudfront.net/bitnami-ui/0.4.1/bitnami.ui.min.css" media="screen">
<link rel="stylesheet" href="https://d1d5nb8vlsbujg.cloudfront.net/bitnami-ui/0.4.1/bitnami.ui.components.min.css" media="screen">
</head>
<body>}

        # Get test classnames paths (see getBTSOutput in main.tcl)
        # eg: /bitnami/btsOutput/magentostackLinux64-3497535-1293/magento/test-results/Magento/screenshots
        set classNames [glob -tails -nocomplain -directory $additionalOutputDirectory [file join $resultPath *]]
        foreach className $classNames {
            # Get test classname
            set testClassName [file tail $className]
            # Get test types paths
            set typeTests [glob -nocomplain [file join $className *]]

            # Initialize the test suites var which will be used for the test plan generation
            set testSuites ""

            # Add test class to html
            append imghtml \n "  <div class=\"padding-normal\">"
            append imghtml \n "    <h2>Screenshots for ${testClassName}</h2>"
            append imghtml \n "    <hr class=\"separator-enormous\"/>"

            # Add table to html
            append imghtml \n "    <table class=\"type-small\">"
            append imghtml \n "      <thead>"
            append imghtml \n "        <tr>"
            append imghtml \n "          <th>Application</th>"
            append imghtml \n "          <th>Scenario</th>"
            append imghtml \n "          <th>Stage</th>"
            append imghtml \n "          <th>Test Name</th>"
            append imghtml \n "          <th>Screenshot</th>"
            append imghtml \n "        </tr>"
            append imghtml \n "      </thead>"
            append imghtml \n "      <tbody>"
            # Populate table for each result
            foreach typeTest $typeTests {
                # Get test type name
                set testTypeName [file tail $typeTest]

                # Get scenarios paths
                set scenarios [glob -nocomplain [file join $typeTest functional *]]
                foreach scenario $scenarios {
                    # Get scenario name
                    set scenarioName [file tail $scenario]

                    # An scenario is equivalent to a test suite, so accumulate the proper parameters to later generate the test plan
                    set testSuites "$testSuites \"$scenarioName\" \"$additionalOutputDirectory/$className/$testTypeName/functional/$scenarioName/tests\" "

                    # Get stages paths
                    set stages [glob -nocomplain [file join $scenario result *]]
                    foreach stage $stages {
                    # Get stage name
                        set stageName [file tail $stage]

                        # Get test names paths
                        set testsFolders [glob -nocomplain [file join $stage screenshots *]]
                        foreach testFolder $testsFolders {
                        # Get test name
                            set testName [file tail $testFolder]

                            # Get screenshots paths
                            set screenshotsFiles [glob -nocomplain [file join $testFolder *]]
                            # If there are screenshots, generate the html body
                            if {[llength $screenshotsFiles] != 0} {
                            # Sort screenshots by name
                                set screenshotsFiles [lsort $screenshotsFiles]

                                # Generate a row for each screenshot result
                                set count [llength $screenshotsFiles]
                                foreach screenshotFile $screenshotsFiles {
                                # Get screenshot name
                                    set screenshotName [file tail $screenshotFile]
                                    # Decrease counter
                                    set count [expr $count-1]
                                    # If it is a failure
                                    set tFailure 0
                                    if {[regexp {.*failure.*} $screenshotName]} {
                                        set tFailure 1
                                    }
                                    # Add screenshots to html
                                    if {$tFailure} {
                                        append imghtml \n "      <tr class=\"type-color-action\">"
                                    } else {
                                        append imghtml \n "      <tr>"
                                    }
                                    append imghtml \n "        <td class=\"padding-v-small\">${testTypeName}</td>"
                                    append imghtml \n "        <td class=\"padding-v-small\">${scenarioName}</td>"
                                    append imghtml \n "        <td class=\"padding-v-small\">${stageName}</td>"
                                    append imghtml \n "        <td class=\"padding-v-small\">${testName}</td>"
                                    append imghtml \n "        <td class=\"padding-v-small\">"
                                    append imghtml \n "          <div class=\"preview\">"
                                    if {$tFailure} {
                                        append imghtml \n "            <a class=\"button button-action\" href=\"$screenshotFile\">$screenshotName</a>"
                                    } else {
                                        append imghtml \n "            <a class=\"button button-accent\" href=\"$screenshotFile\">$screenshotName</a>"
                                    }
                                    append imghtml \n "            <img src=\"$screenshotFile\" alt=\"$screenshotName\" height=\"100\"/>"
                                    append imghtml \n "          </div>"
                                    append imghtml \n "        <td>"
                                    append imghtml \n "      </tr>"
                                }
                            }
                        }
                    }
                }
            }
            append imghtml \n "    </table>"
            append imghtml \n "  </div>"

        }

        # Close html
        append imghtml \n "</body>"
        append imghtml \n "</html>"

        # Set prefix for citest
        if {$htmlFilePrefix != ""} {
            set htmlFilePrefix "${htmlFilePrefix}-"
        }

        # Dump html for screenshots
        set htmlFile [file join $additionalOutputDirectory ${htmlFilePrefix}casperjsscreenshots.html]
        puts "Generating HTML for CasperJS screenshot results at $htmlFile"
        # Open html file in w mode?
        set fh [open $htmlFile w]
        puts $fh $imghtml
        close $fh
        cd $wd

        # TODO: The code below will take care of html only
    } else {
        puts "Selenium tarballs not found. Usage:"
        puts ""
        puts "  $ tclkit $argv0 </path/to/folder/with/casperjs/tarballs>"
        puts ""
    }
} else {
    puts "You need to provide a folder as input to work:"
    puts ""
    puts "  $ tclkit $argv0 </path/to/folder/with/casperjs/tarballs>"
    puts ""
}

