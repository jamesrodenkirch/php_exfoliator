#! /bin/bash
#
# The MIT License
#
# Copyright (c) 2010 James Rodenkirch <james@rodenkirch.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

TITLE="PHP Exfoliator"
FILETYPES="*\.{php,phtml}"
WORKING="/tmp/exfoliate"

#------------------------------------------------>> prompt for parameters  <<---

SOURCE=$(whiptail \
    --title "${TITLE}" \
    --inputbox "Source Directory:\nWhat Files to Scan" \
    10 80 2>&1 > /dev/tty)

if [ $? != 0 ]; then
    exit 0
fi



DESTINATION=$(whiptail \
    --title "${TITLE}" \
    --inputbox "Destination File:\nWhere to Store Results" \
    10 80 2>&1 > /dev/tty)

if [ $? != 0 ]; then
    exit 0
fi



EXCLUDEDIR=$(whiptail \
    --title "${TITLE}" \
    --inputbox "Exclude Directory:\nDirectory pattern to exclude" \
    --cancel-button "No Exclusions" \
    10 80 2>&1 > /dev/tty)

if [ $? = 0 ]; then
    PATTERNDIR="--exclude-dir=*${EXCLUDEDIR}*"
else
    PATTERNDIR=""
fi



EXCLUDEFILE=$(whiptail \
    --title "${TITLE}" \
    --inputbox "Exclude Files:\nFile pattern to exclude" \
    --cancel-button "No Exclusions" \
    10 80 2>&1 > /dev/tty)

if [ $? = 0 ]; then
    PATTERNFILE="--exclude=*${EXCLUDEFILE}*"
else
    PATTERNFILE=""
fi

#---------------------------------------->>  generate and run find command <<---

eval "rm -rf ${WORKING}"
eval "mkdir ${WORKING}"
eval "touch ${WORKING}/grep.log"

eval "grep -r '^class ' --include=${FILETYPES} ${PATTERNDIR} ${PATTERNFILE} ${SOURCE}/." > ${WORKING}/grep.log

#---------------------------------------------------->>  process log file  <<---

c=$((`wc -l "${WORKING}/grep.log" | awk '{print $1'}`))
i=0

{
    while read line
    do
        set -- "${line}"
        IFS=" "; declare -a Array=($*)

        eval "touch ${WORKING}/${Array[1]}"
        eval "grep -r '${Array[1]}' --include=${FILETYPES} ${PATTERNDIR} ${PATTERNFILE} ${SOURCE}/." > ${WORKING}/${Array[1]}

        i=$(($i + 1))
        echo $(echo "100*$i/$c" | bc)

    done <${WORKING}/grep.log

} | whiptail --gauge "Please wait" 5 50 0

#----------------------------------->>  collate classes that are not used  <<---

eval "rm ${WORKING}/grep.log"
eval "touch ${DESTINATION}"

echo "The following classes are not used" >> ${DESTINATION}
echo "" >> ${DESTINATION}
echo "" >> ${DESTINATION}

FILES="${WORKING}/*"
for f in $FILES
do
    counter=`wc -l "$f" | awk '{print $1'}`

    if [ ${counter} = 1 ]; then
        echo $f >> ${DESTINATION}
    fi
done

#--------------------------------------------------->>  clean up and exit  <<---

eval "rm -rf ${WORKING}"
exit 0
