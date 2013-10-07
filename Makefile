build:
	./node_modules/.bin/coffee -o lib/ -c src/
clean:
	rm -r lib/