#!/bin/bash

up_revision() {
    APPLICATIONS=`cat $1`
    for app in $APPLICATIONS; do
        grep -n "prog $app =" $PATHTOBC/tools/vtracker/$2  > /dev/null
        if [ ! $? -eq 0 ]; then
            APPSNOTPRESENT=$APPSNOTPRESENT:$app
        else
            block=`cat $PATHTOBC/tools/vtracker/$2 | grep -A 5 "prog $app ="`
            position=0
            counter=0
            for i in $block; do
                let counter++
                if [ $i == "rev" ]; then
                    let position=counter
                fi
            done
            let position=($position-1)/3
            revision=`echo $block | grep -oP 'rev\s*=\s*([0-9]+)' | awk '{print $3}'`
            let revision++
            line=`grep -n "prog $app =" $PATHTOBC/tools/vtracker/$2 | awk -F: '{print $1}'`
            let line=line+$position
            sed -e "${line}s/.*/  rev       = $revision/g" -i $PATHTOBC/tools/vtracker/$2
        fi
    done
}

APPSNOTPRESENT=
PATHTOBC=$(echo $PWD | sed 's#\(\.*bitnami-code\|.*releases\)\(-[^\/]*\/\|-[^\/]*\)\?.*#\1\2#g')
if [ $# -eq "2" ]; then
    if [ $2 == "applications" ] || [ $2 == "isvpartners" ] || [ $2 == "nami-modules" ]; then
	if [ $2 == "applications" ]; then
            up_revision $1 applications
            up_revision $1 isvpartners
            APPSDUPLICATED=`echo $APPSNOTPRESENT | sed -e "s/:/\n/g" | awk '!a[$0]++'`
            APPSNOTPRESENT=`echo $APPSNOTPRESENT | sed -e "s/:/\n/g"`
            for i in $APPSDUPLICATED; do
                APPSNOTPRESENT=`echo $APPSNOTPRESENT | sed "0,/$i/s///"`
            done
	else
	    up_revision $1 $2
            APPSNOTPRESENT=`echo $APPSNOTPRESENT | sed -e "s/:/\n/g"`
	fi
        echo
        echo "The following stacks must be updated manually:"
        echo $APPSNOTPRESENT
        echo 
    else
	echo
        echo "Invalid VtrackerFile"
        echo "Allowed values: applications isvpartners nami-modules"
        echo
    fi
else
        echo
        echo "$0 stack-list.txt VtrackerFile"
        echo "Example: $0 applications.txt applications\t\t\t -> '* Update revision for all the applications in the applications.txt list'"
        echo "Example: $0 applications.txt nami-modules\t\t\t -> '* Update revision for all the nami-modules in the applications.txt list'"
        echo
fi
