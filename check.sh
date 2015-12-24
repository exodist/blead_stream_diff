#!/bin/bash

cat blead.log | grep ' # skip ' > blead_skip_in.log
cat blead.log | grep ' # TODO ' > blead_todo_in.log
cat blead.log | grep '^# ' > blead_comment_in.log
cat blead.log | grep '^\(not \)\?ok ' > blead_ok_in.log

cat patched.log | grep ' # skip ' > patched_skip_in.log
cat patched.log | grep ' # TODO ' > patched_todo_in.log
cat patched.log | grep '^# ' > patched_comment_in.log
cat patched.log | grep '^\(not \)\?ok ' > patched_ok_in.log

# Strip out test numbers, some tests run in random order, removing the numbers
# makes them merge better.
perl -p -i -e 's/^(not )?ok \d+/$1ok/g' {blead,patched}_{skip,todo,ok,comment}_in.log

# Strip random memory addresses.
perl -p -i -e 's/\(0x[0-9a-f]+\)/__REMOVE__/ig' {blead,patched}_{ok,comment}_in.log

# These filter out items that produce several lines of randomness each.
# If you are curious feel free to comment them out, I recommend only commenting
# 1 out at a time though.
perl -p -i -e 's/(te?mp)/__REMOVE__/ig'                                           {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's/(time|date|seconds|wallclock)/__REMOVE__/ig'                     {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's/(thread|process|pid|kill|parent|child)/__REMOVE__/ig'            {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's/(vianame|viacode)/__REMOVE__/g'                                  {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's/sig \d+ is(?: not)? a member/__REMOVE__/g'                       {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's/Line \d+ doesn.t start with a blank/__REMOVE__/g'                {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's/get.flag/__REMOVE__/g'                                           {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's/Extracted file/__REMOVE__/g'                                     {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's/seed.*$/__REMOVE__/g'                                            {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's/An object of class .t\w+. isa .t\w+./__REMOVE__/g'               {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's{t/\d+\.(enc|utf) eq t/.*\.(enc|utf)}{__REMOVE__}g'               {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's{uses .* heads}{__REMOVE__}g'                                     {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's{File written size=}{__REMOVE__}g'                                {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's{require "auto/A\d_\d+splittest/autosplit.ix}{__REMOVE__}g'       {blead,patched}_{ok,comment}_in.log
perl -p -i -e 's{Foo::Bar\d+ }{__REMOVE__}g'                                      {blead,patched}_{ok,comment}_in.log

# Only filter in comments
perl -p -i -e 's{using dist Simple\d+ in}{__REMOVE__}g'                           {blead,patched}_comment_in.log
perl -p -i -e 's{/cpan/Module-Metadata/MMD-.*/Simple\d+}{__REMOVE__}g'            {blead,patched}_comment_in.log
perl -p -i -e 's/^# [AB] \d+$/__REMOVE__/g'                                       {blead,patched}_comment_in.log
perl -p -i -e 's/^# ADB->\[-1\]:/__REMOVE__/g'                                    {blead,patched}_comment_in.log
perl -p -i -e 's/\d{15}/__REMOVE__/g'                                             {blead,patched}_comment_in.log
perl -p -i -e 's/-e "use AutoSplit; autosplit/__REMOVE__/g'                       {blead,patched}_comment_in.log
perl -p -i -e 's{ext-\d+/\d being (created|removed)}{__REMOVE__}g'                {blead,patched}_comment_in.log

# Large decimals are typically from timing things, which is not reproducable
# from run to run.
perl -p -i -e 's/\d\.\d{5}/__REMOVE__/g' {blead,patched}_{ok,comment}_in.log

for i in {blead,patched}_{skip,todo,ok,comment}; do
    cat "${i}_in.log" | grep -a -v '__REMOVE__' | grep -a -v 'Test2' | grep -a -v 'Test-Simple' | sort > "${i}.log"
done

MAX_DIFF_SIZE=25;

echo
echo "============================================="
echo "Diff of comment:"
diff blead_comment.log patched_comment.log > comment.diff
C_DIFF=`cat comment.diff | wc -l`
if [ $C_DIFF -eq 0 ]; then
    echo "No Differences"
elif [ $C_DIFF -lt $MAX_DIFF_SIZE ]; then
    cat comment.diff
else
    echo "Diff is $C_DIFF lines long, see comment.diff"
fi

echo
echo
echo "============================================="
echo "Diff of ok:"
diff blead_ok.log patched_ok.log > ok.diff
OK_DIFF=`cat ok.diff | wc -l`
if [ $OK_DIFF -eq 0 ]; then
    echo "No Differences"
elif [ $OK_DIFF -lt $MAX_DIFF_SIZE ]; then
    cat ok.diff
else
    echo "Diff is $OK_DIFF lines long, see ok.diff"
fi

echo
echo "============================================="
echo "Diff of TODO:"
diff blead_todo.log patched_todo.log > todo.diff
TODO_DIFF=`cat todo.diff | wc -l`
if [ $TODO_DIFF -eq 0 ]; then
    echo "No Differences"
elif [ $TODO_DIFF -lt $MAX_DIFF_SIZE ]; then
    cat todo.diff
else
    echo "Diff is $TODO_DIFF lines long, see todo.diff"
fi

echo
echo
echo "============================================="
echo "Diff of skip:"
diff blead_skip.log patched_skip.log > skip.diff
SKIP_DIFF=`cat skip.diff | wc -l`
if [ $SKIP_DIFF -eq 0 ]; then
    echo "No Differences"
elif [ $SKIP_DIFF -lt $MAX_DIFF_SIZE ]; then
    cat skip.diff
else
    echo "Diff is $SKIP_DIFF lines long, see todo.diff"
fi

echo
echo
echo "============================================="
echo "Test Counts: (This is effected by the number of files, and the number of files with pod)"
BLEAD_COUNT=`cat blead.log | grep -a -e '^\(not \)\?ok ' | wc -l`
PATCHED_COUNT=`cat patched.log | grep -a -e '^\(not \)\?ok ' | wc -l`
DELTA_COUNT=$(expr $PATCHED_COUNT - $BLEAD_COUNT)
echo "  blead: $BLEAD_COUNT"
echo "patched: $PATCHED_COUNT"
echo "  DELTA: $DELTA_COUNT"

echo
echo
echo "============================================="
BLEAD_COMMENTS=`cat blead.log | grep -a -e '^# ' | wc -l`
PATCHED_COMMENTS=`cat patched.log | grep -a -e '^# ' | wc -l`
DELTA_COMMENTS=$(expr $PATCHED_COMMENTS - $BLEAD_COMMENTS)
echo "Comment Counts:"
echo "  blead: $BLEAD_COMMENTS"
echo "patched: $PATCHED_COMMENTS"
echo "  DELTA: $DELTA_COMMENTS"

rm *_in.log
rm *_*.log
