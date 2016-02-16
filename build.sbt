scalaVersion := "2.11.6"

libraryDependencies += "edu.berkeley.cs" %% "chisel" % "latest.release"

unmanagedSourceDirectories in Compile <++= baseDirectory { base =>
  Seq(
    base / "interfaces/scala",
    base / "interconnect/scala",
    base / "blocks/buffer/scala",
    base / "blocks/arbiter/scala",
    base / "modules/mam/scala"
  )
}
