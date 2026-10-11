#!/bin/sh
set -eu
rm -rf out
mkdir -p out
javac -encoding UTF-8 -d out $(find src/main/java -name '*.java' -print) $(find src/test/java -name '*.java' -print)
java -Xms64m -Xmx256m -XX:+UseSerialGC -cp out org.pastafari.javalojban.Stage02LinearWeavingTests
