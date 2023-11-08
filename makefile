build-web:
	flutter build web --web-renderer html
	- mkdir bin/
	cd build && zip -r ../bin/web.zip web/