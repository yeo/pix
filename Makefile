docker:
	docker build -t pix .

run:
	mkdir -p public/upload
	crystal run src/pix.cr

run-in-docker:
	mkdir -p public/upload
	docker run --rm -it -p 3003:3003 \
		-v `pwd`/public/upload:/app/public/upload \
		pix

upload:
	curl -v -F "image1=@./public/images/t2.jpg" http://localhost:3003/incoming/
	curl -v -F "image1=@./public/images/rose.png" http://localhost:3003/incoming/

prod-upload:
	curl -v -F "image1=@./public/images/t2.jpg" https://pix.fastloop.xyz/incoming/
	curl -v -F "image1=@./public/images/rose.png" https://pix.fastloop.xyz/incoming/

clean:
	rm -rf public/upload
	mkdir public/upload
