#!/bin/bash

## ./run_git_diff_patch.sh ../git/otto/otto/ patch_pro/20190315_bootloader_9603C_9603CVD_patch_b4cd3bd_c760c7be ad8e325

mkdir -p $2

PWD=`pwd`
DIFF_S=$PWD/$1
DIFF_D=`realpath $2`
R1=$3
Skip_r=
DIFF_folder=
if [ $# -ge 4 ]; then
	if [ ! "$4" == "last" ]; then
		R2=$4
	fi
	
	if [ $# -ge 5 ]; then
		Skip_r=$5
	fi
	
	if [ $# -ge 6 ]; then
		DIFF_folder=$6
	fi
fi

if [ ! -d $DIFF_S ]; then
	echo "Cannot find folder $DIFF_S"
	exit 1
fi

if [ ! $? -eq 0 ]; then
	echo "Cannot create folder $DIFF_D  $?"
	exit 1
fi

DIFF_D_after=$DIFF_D/after
DIFF_D_before=$DIFF_D/before

if [ ! "$DIFF_folder" == "" ]; then
	DIFF_D_after=$DIFF_D/after/$DIFF_folder
	DIFF_D_before=$DIFF_D/before/$DIFF_folder
fi
mkdir -p $DIFF_D_after
mkdir -p $DIFF_D_before

cd $DIFF_S

if [ -z $R2 ]; then
	R2=`git rev-parse --short HEAD`
fi
echo "Diff reversion $R1 to $R2 ...."
#git diff --name-status --diff-filter=ACMRT $R1~1 $R2 >  $DIFF_D/git_diff_"$R1"_"$R2"_files.txt
#git diff --name-status --diff-filter=D $R1~1 $R2 >  $DIFF_D/git_diff_"$R1"_"$R2"_delete_files.txt
#git diff --diff-filter=ACDMRT $R1~1 $R2 >  $DIFF_D/git_diff_"$R1"_"$R2"_change.patch
git diff --diff-filter=ACDMRT $R1~1 $R2 >  $DIFF_D/changes.patch
git log $R1~1..$R2 >  $DIFF_D/git_log_"$R1"_"$R2"_log.txt
git archive --format=zip --output=$DIFF_D/files.zip $R2 `git diff-tree -r --no-commit-id --name-only --diff-filter=ACMRT $R1~1 $R2`

cd $DIFF_D
unzip files.zip -d $DIFF_D_after
unzip files.zip -d $DIFF_D_before
rm files.zip 
cd $DIFF_D_before
echo $DIFF_D/changes.patch
patch -p1 -R < $DIFF_D/changes.patch

cd $DIFF_D
diff -ruN before after > changes.patch

