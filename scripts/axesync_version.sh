#!/bin/sh

RUBY_SCRIPT=$(cat <<'END_RUBY_SCRIPT'
data = YAML::load(STDIN.read)
puts data['CHECKOUT OPTIONS']['AxeSync'][:'commit'] 
END_RUBY_SCRIPT
)

cat Podfile.lock | ruby -ryaml -e "$RUBY_SCRIPT" > AxeSyncCurrentCommit
