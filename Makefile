export PATH := ..:$(PATH)

all: doc/karps.md doc/karps.html

doc/karps.md: protos/*.proto
	cd protos && protoc --doc_out=markdown,karps.md:../doc *.proto

doc/karps.html: protos/*.proto
	cd protos && protoc --doc_out=html,karps.html:../doc *.proto
