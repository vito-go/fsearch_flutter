build-web:
	flutter build web
	- mkdir bin/
	zip -r ./bin/web.zip ./build/web/