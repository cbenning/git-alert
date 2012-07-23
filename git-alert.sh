#!/bin/bash

MYGITUSER='myuser@remotehost' #User to exclude 

REPOS[1]='git@remotehost:myuser/myrepo1.git'
REPOS[2]='git@remotehost:myuser/myrepo2.git'

CWD=`pwd`
CLONEDIR="$CWD/.git-alert-repos"
LAST_FILENAME=".last_commit"
NEW_FILENAME=".new_commit"
SLEEP_SECONDS="60"
NOTIFY_TIMEOUT="10000"

if [ ! -d "$CLONEDIR" ]
    then
    mkdir -p $CLONEDIR
fi
cd $CLONEDIR

while true; do

    for repourl in ${REPOS[@]} 
        do
            echo "Checking $repourl"
            repodir=${repourl##*/}
            
            if [ ! -d "$repodir" ]
                then
                git clone $repourl $repodir
            fi
            cd $repodir
            git fetch

            if [ ! -f "$LAST_FILENAME" ]
                then
                git log origin/master -n 1 > $LAST_FILENAME
            else
                git log origin/master -n 1 > $NEW_FILENAME
                authorname=`cat $NEW_FILENAME  | grep 'Author' | sed 's/.*<\(.*\)>.*/\1/'`
                new_dateline=`grep Date $NEW_FILENAME`
                last_dateline=`grep Date $LAST_FILENAME`

                ## If you want to ignore commit
                if [ "$authorname" == "$MYGITUSER" ] 
                    then
                    rm $NEW_FILENAME
                elif [ "$new_dateline" != "$last_dateline" ]
                    then

                    cat $NEW_FILENAME > $LAST_FILENAME
                    rm $NEW_FILENAME
                    message=`cat $LAST_FILENAME`

                   notify-send -t $NOTIFY_TIMEOUT "GIT: $authorname pushed to $repodir" "$message"
                fi
            fi
            cd ..
            continue

        done
     echo "Sleeping for $SLEEP_SECONDS"
     sleep $SLEEP_SECONDS
done


