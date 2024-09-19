build-web:
	flutter build web
	- mkdir target/
	cd build && zip -r ../target/web.zip web/