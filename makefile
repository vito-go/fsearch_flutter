build-web:
	flutter build web--web-renderer html
	- mkdir bin/
	zip -r ./bin/web.zip ./build/web/