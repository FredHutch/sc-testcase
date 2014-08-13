#!/bin/bash

##############################################################################
# test.sh - test case wrapper script                                         #
##############################################################################

# Get full path to package base directory.
BASE_DIR=$(readlink -f `dirname $0`)
# RETURN_CODE should be modified if an error occurs.
RETURN_CODE=0

# Setup $MD5_SUM and $RESULTS_FILES
source $BASE_DIR/checksum

function get_checksum
{
    CHECKSUM=""
    if [ -z "$RESULTS_FILES" ]; then
        echo -e -n "\nError: \$RESULTS_FILES is not set. "
        echo "Please specify the results file(s) to work with."
        exit 1
    fi
    for f in $RESULTS_FILES; do
        if [ ! -f "$BASE_DIR/output/$f" ]; then
            echo -e "\nError: Unable to calculate md5 sum for file $f."
            exit 1
        else
            # Assume md5sum in path 
            CHECKSUM=$CHECKSUM`md5sum $BASE_DIR/output/$f | awk '{ print $1 }'` 
        fi
    done

    CHECKSUM=`echo $CHECKSUM |md5sum | awk '{ print $1 }'`
    echo "$CHECKSUM"
}

if [ $# -eq 1 ] && [ "$1" = "--help" ] || [ $# -gt 1 ]; then
    echo -e "\ntest.sh - launch a test case\n"
    echo -e "Options\n"
    echo -e "\t--help\t\t- this help text"
    echo -e "\t--clean\t\t- perform any temporary file cleanup"
    echo -e "\t--checksum\t- generate md5sum against results file(s) "
    echo -e "\t\t\t  currently in output directory."

# Check for "clean" parameter and perform clean-up if requested.  Add custom
# clean-up commands here.
elif [ $# -eq 1 ] && [ "$1" = "--clean" ]; then
    echo -e "\nPerforming clean-up.\n"
    source $BASE_DIR/clean_up $BASE_DIR
    echo
elif [ $# -eq 1 ] && [ "$1" = "--checksum" ]; then
    CHECKSUM=$(get_checksum)
    echo "checksum: $CHECKSUM"
else # Run test case
    echo `date "+%Y-%m-%d %H:%M:%S"` "Starting test case execution" >> \
    $BASE_DIR/output/test.log
##############################################################################
# Place any code to execute on the cluster in this section                   #
#   * Set RETURN_CODE appropriately, 0 for success (default) non-0 int if    #
#     error.                                                                 #
#   * Append STDOUT and STDERR to $BASE_DIR/output/test.log                  #
#   * Other custom logging can go in output/*.log                            #
##############################################################################

    source $BASE_DIR/run_test $BASE_DIR

    CHECKSUM=$(get_checksum)
    if [ "$CHECKSUM" != "$MD5_SUM" ]; then
        RETURN_CODE=1
    fi

    if [ $RETURN_CODE = 0 ]; then   # Success
        echo `date "+%Y-%m-%d %H:%M:%S"` "Test case execution successful" >> \
        $BASE_DIR/output/test.log
    else    # Test case failed
        #echo `date "+%Y-%m-%d %H:%M:%S"` "An error has occurred, $BASE_DIR/output/error.log may contain further details. Exiting" >> $BASE_DIR/output/test.log
        echo `date "+%Y-%m-%d %H:%M:%S"` "An error has occurred, this log file may contain further details. Exiting" >> $BASE_DIR/output/test.log
    fi
    exit $RETURN_CODE
fi


