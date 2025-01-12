# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

import markdown
import std/stringutils

func main() =
  let tmpl = readFile("templates/base.html")

when isMainModule:
  main()
