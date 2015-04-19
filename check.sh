#!/bin/bash

cat stdlegacy.log| grep ' # skip ' > legacy_skip_in.log
cat stdlegacy.log| grep ' # TODO ' > legacy_todo_in.log

cat stdstream.log| grep ' # skip ' > stream_skip_in.log
cat stdstream.log| grep ' # TODO ' > stream_todo_in.log

perl -p -i -e 's/ok \d+//g' {legacy,stream}_{skip,todo}_in.log

for i in {legacy,stream}_{skip,todo}; do
    echo "Creating ${i}.log";
    sort "${i}_in.log" > "${i}.log"
done

echo
echo "============================================="
echo "Diff of TODO:"
diff legacy_todo.log stream_todo.log | grep -v 'Test/Stream' | grep -v 'Test-Simple'
echo
echo
echo "============================================="
echo "Diff of skip:"
diff legacy_skip.log stream_skip.log | grep -v 'Test/Stream' | grep -v 'Test-Simple'
