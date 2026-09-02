ThisBuild / scalaVersion := "2.13.18"
ThisBuild / organization := "org.pastafari"
ThisBuild / version := "0.1.0-stage01"

Compile / scalacOptions ++= Seq("-deprecation", "-feature", "-unchecked", "-Xlint")
Test / scalacOptions ++= Seq("-deprecation", "-feature", "-unchecked", "-Xlint")
Test / run / mainClass := Some("pastafari.Stage01Tests")
