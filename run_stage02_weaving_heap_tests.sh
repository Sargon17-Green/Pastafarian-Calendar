#!/bin/sh
set -eu
rm -rf out
mkdir -p out
javac -encoding UTF-8 -d out $(find src/main/java -name '*.java' -print) src/test/java/org/pastafari/javalojban/Stage02WeavingHeapTests.java
java -Xms64m -Xmx256m -XX:+UseSerialGC -cp out org.pastafari.javalojban.Stage02WeavingHeapTests medium
java -Xms64m -Xmx512m -XX:+UseSerialGC -cp out org.pastafari.javalojban.Stage02WeavingHeapTests large
