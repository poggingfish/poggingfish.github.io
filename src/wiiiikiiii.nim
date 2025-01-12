import markdown
import std/strutils
import std/dirs
import std/paths
import std/strformat

const pageName = "pogging.fish"
const donation = ""
const tmpl = readFile("wiki/templates/base.html")

proc applyTemplate(page: string): string =
  return multireplace(tmpl, 
    [("__varHtmlpage__var", page),
      ("__varWikiName__var", pageName),
      ("__varDonate__var", donation)
    ]
  )

proc main() =
  if dirExists(Path("generated")):
    removeDir(Path("generated"))
  createDir(Path("generated"))
  writeFile("generated/base.css", readFile("wiki/templates/base.css"))
  # Generate html files
  var index = newSeq[(string, string)]()
  for i in walkDirRec(Path("wiki/pages")):
    let basePath = Path(string(i).split("/")[2..^1].join("/")).changeFileExt(".html")
    let path = "generated/" & string(basePath)
    let original = readFile(string(i))
    index.add((string(basePath), original.split("\n")[0].replace("#", "")))
    let mdhtml = markdown(original)
    writeFile(string(path), applyTemplate(mdhtml))
  # Create index page
  var indexhtml = "<p>Looking for something specific? Do CTRL+F to find it!</p>"
  for i in index:
    indexhtml = indexhtml & fmt"<p><a href={i[0]}>{i[1]}</a><p>"
  writeFile("generated/indexpage.html", applyTemplate(indexhtml))


when isMainModule:
  main()
