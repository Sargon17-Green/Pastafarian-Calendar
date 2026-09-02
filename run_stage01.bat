@echo off
sbt "Test / run"
exit /b %errorlevel%
