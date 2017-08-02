#!/bin/bash 

SEQDIR=$(readlink -f $(dirname $0))
export NO_COLOR=1
TMPDIR=$(mktemp -d)

# Drop colors and SHA as they change from one run to another
__sanitize_log()
{
	sed -r -e "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" -e 's/^([a-zA-Z\*]* +)[a-f0-9]+ /\1 /g'
}

echo $TMPDIR
cd $TMPDIR || exit 1

(
	set -e
	git init
	echo 1 > file
	git add file
	git commit -m "First commit"
	git branch rebase_conflict
	git branch cherry_pick
	git branch empty_cp
	echo 2 >> file
	git commit -a -m "Second commit"
	echo 3 >> file
	git commit -a -m "Third commit"
	echo 4 >> file
	git commit -a -m "Fourth commit"
	git branch revert

	git checkout rebase_conflict
	echo 3 > file
	git commit -a -m "Alternate second"

	git checkout cherry_pick
	echo 1 > file2
	git add file2
	git commit -a -m "Alternate history"

	git checkout empty_cp
	echo 2 >> file
	echo 1 > file2
	git add file file2
	git commit -a -m "Redundant second commit"

) > /dev/null

echo "Checking cherry pick support"
git checkout cherry_pick
git cherry-pick master~2 master master~1 > /dev/null 2>&1
LOG=$($SEQDIR/sequencer-status | __sanitize_log)
REF_LOG=$(cat <<EOF | __sanitize_log
#  Cherry picking
pick    f6d35cc Third commit 
*pick   4e8ccfd Fourth commit 
done    ce86bf6 Second commit
onto    d0d80f9 Alternate history
EOF
)

diff  <(echo "$LOG")  <(echo "$REF_LOG")
if [ $? -ne 0 ]; then
	echo "Failure in cherry pick mode" >&2
	exit 1
fi
git cherry-pick --abort

echo "Checking revert support"
git checkout revert
git revert --no-edit  master master~2 master~1 > /dev/null 2>&1
LOG=$($SEQDIR/sequencer-status | __sanitize_log)
REF_LOG=$(cat <<EOF | __sanitize_log
#  Reverting
revert  f6d35cc Third commit 
*revert 960d878 Second commit 
done    50dd0a7 Revert "Fourth commit"
onto    4e8ccfd Fourth commit
EOF
)

diff  <(echo "$LOG")  <(echo "$REF_LOG")
if [ $? -ne 0 ]; then
	echo "Failure in revert mode" >&2
	exit 1
fi

git revert --abort

echo "Checking non interactive rebase support"
git checkout revert
git rebase rebase_conflict > /dev/null 2>&1
LOG=$($SEQDIR/sequencer-status | __sanitize_log)
REF_LOG=$(cat <<EOF | __sanitize_log
# Non-interactive rebase: revert onto rebase_conflict
pick    38fb428 Fourth commit
pick    46c2f5e Third commit
*pick   22bc518 Second commit
onto    68cb488 Alternate second
EOF
)

diff  <(echo "$LOG")  <(echo "$REF_LOG")
if [ $? -ne 0 ]; then
	echo "Failure in revert mode" >&2
	exit 1
fi
git rebase --abort

echo "Checking am support"
git checkout rebase_conflict
git format-patch master~2..master --stdout > patches.mailbox
git am patches.mailbox  > /dev/null 2>&1
LOG=$($SEQDIR/sequencer-status | __sanitize_log)
REF_LOG=$(cat <<EOF | __sanitize_log
# Applying patches
pick    0002 Fourth commit 
done    0001 Third commit 
onto    339d1b1 Alternate second
EOF
)

diff  <(echo "$LOG")  <(echo "$REF_LOG")
if [ $? -ne 0 ]; then
	echo "Failure in AM mode" >&2
	exit 1
fi
git am --abort


echo "Checking rebase with empty commit support"
git checkout master
GIT_EDITOR=true git rebase -i empty_cp  > /dev/null 2>&1
LOG=$($SEQDIR/sequencer-status | __sanitize_log)
REF_LOG=$(cat <<EOF | __sanitize_log
# Interactive rebase: master onto empty_cp
pick    d4e101f Fourth commit 
pick    b636e21 Third commit 
pick    f4f895f Second commit 
onto    211640b Redundant second commit
EOF
)

diff  <(echo "$LOG")  <(echo "$REF_LOG")
if [ $? -ne 0 ]; then
	echo "Failure in AM mode" >&2
	exit 1
fi
git rebase --abort


# Post cleanup
rm -Rf $TMPDIR
