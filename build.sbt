scalaVersion := "2.11.6"

libraryDependencies += "edu.berkeley.cs" %% "chisel" % "latest.release"

unmanagedSourceDirectories in Compile <++= baseDirectory { base =>
  Seq(
    base / "modules/mam/scala",
    base / "interfaces/scala"
  )
}
