build: ./src/main.zig
	zig build --release=safe
	cp ./zig-out/bin/feedme-lang ./

debug: ./src/main.zig
	zig build
	cp ./zig-out/bin/feedme-lang ./

test: ./src/main.zig
	zig build test

install: ./feedme-lang
	install -m 777 ./feedme-lang /usr/local/bin/feedme
