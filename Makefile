# Энэ файл зөвхөн Mercury кодыг бүтээж, ажиллуулна.
.PHONY: test clean

test:
	mmc --make --search-directory src --search-directory test stage01_tests
	./stage01_tests

clean:
	rm -rf Mercury stage01_tests *.mh *.mih *.int *.int2 *.int3 *.o *.c
