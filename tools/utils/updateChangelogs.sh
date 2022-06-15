#!/bin/sh
PATHTOBC=$(echo $PWD | sed 's#\(\.*bitnami-code\|.*releases\)\(-[^\/]*\/\|-[^\/]*\)\?.*#\1\2#g')
if [ $# -ge "3" ]; then
        componentXML="$1"
        componentName="$2"
        componentVersion="$3"
        lineofentry="Version @@XAMPP_APPLICATION_VERSION@@      @@XAMPP_DATE@@"
        if [ $# -eq "4" ]; then
                onlyOneApplication="$4"
        else
                onlyOneApplication=""
        fi
        if [ ! -z "$5" ]; then
                msg="$5"
        else
                msg="Updated $componentName to $componentVersion"
        fi
        sedArgument='s/'$lineofentry'/'$lineofentry'\n* '$msg'/g'

        cd $PATHTOBC
        list="`find apps/"$onlyOneApplication" -name \*-standalone.xml -print0 | xargs -0 grep -niI "$componentXML" | awk 'BEGIN{FS="/"}{print $2}' | sort | uniq`"
#        echo -n $list

        cd $PATHTOBC/apps
        echo -n "Modified files for:"
        for i in $list ;do
                file="${i}/changelog.txt"
                if [ ! -e $file ]; then
                        file="${i}stack/changelog.txt"
                        if [ ! -e $file ]; then
                                file=""
                                if [ ${i} = "phpmyadmin" ]; then
                                        file="lampstack/changelog.txt mampstack/changelog.txt wampstack/changelog.txt"
                                fi
                                if [ ${i} = "phppgadmin" ]; then
                                        file="lappstack/changelog.txt mappstack/changelog.txt wappstack/changelog.txt"
                                fi
                        fi
                fi
                for simplefile in $file; do
                        if [ -e $simplefile ]; then
                                if [ ! "`cat $simplefile | grep \"$msg\"`" -a "`cat $simplefile | grep \"$lineofentry\"`" ]; then
                                        sed -i "$sedArgument" $simplefile
                                        echo -n " $simplefile" | sed 's/\/changelog.txt//g'
                                fi
                        fi
                done
        done
        echo
else
        echo
        echo " $0 php.xml PHP 5.4.18\t\t\t-> '* Updated PHP to 5.4.18' (in all apps)"
        echo " $0 php.xml PHP 5.4.18 redmine\t\t-> '* Updated PHP to 5.4.18' (only in redmine)"
        echo " $0 php.xml PHP 5.4.18 redmine \"CUSTOM\"\t-> '* CUSTOM' (only in redmine)"
        echo " $0 php.xml PHP 5.4.18 . \"CUSTOM\"\t-> '* CUSTOM' (in all apps)"
        echo
fi
