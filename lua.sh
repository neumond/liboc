eval $(luarocks path)
cd $(dirname $0)
cd items
lua5.3 $@
