#!/bin/sh
set -eu
rm -rf out
mkdir -p out
javac -encoding UTF-8 -d out $(find src/main/java src/test/java -name '*.java' -print)
java -cp out org.pastafari.javalojban.Stage01Tests
