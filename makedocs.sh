nim doc --out=docs/index.html src/sudo.nim

sed -i 's@src/sudo@sudo.nim@' docs/index.html
