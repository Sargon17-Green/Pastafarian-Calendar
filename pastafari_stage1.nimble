version = "0.1.0"
srcDir = "src"
requires "nim >= 2.0.0"

task test, "Az 1. szakasz tesztjeinek futtatása":
  exec "nim c -r tests/stage01_tests.nim"
