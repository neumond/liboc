cd $(dirname $0)
cd items
~/.luarocks/bin/busted $@ --exclude-tags="skip" -- ../tests/
