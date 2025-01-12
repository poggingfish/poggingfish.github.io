import markdown
import std/strutils
import std/dirs
import std/paths
import std/strformat
import std/json
import std/tables

const pageName = "pogging.fish"
const donation = ""
const tmpl = readFile("wiki/templates/base.html")

proc applyTemplate(page: string, tags: string = ""): string =
  return multireplace(tmpl, 
    [("__varHtmlpage__var", page),
     ("__varTags__var", tags),
     ("__varWikiName__var", pageName),
     ("__varDonate__var", donation)
    ]
  )

proc createLink(i: (string, string, string)): string =
  return fmt"<p><a href=/{i[0]}>{i[1]}</a><small>&ThickSpace;{i[2]}</small><p>"

proc main() =
  if dirExists(Path("generated")):
    removeDir(Path("generated"))
  createDir(Path("generated"))
  createDir(Path("generated/tags"))
  writeFile("generated/base.css", readFile("wiki/templates/base.css"))
  let meta = parseFile("wiki/meta.json")
  # Generate html files
  var index = newSeq[(string, string, string)]()
  var tags = initTable[string, seq[(string, string)]]()
  for i in walkDirRec(Path("wiki/pages")):
    let basePath = Path(string(i).split("/")[2..^1].join("/")).changeFileExt(".html")
    for dir in string(i).split("/")[0..^2]:
      createDir(Path("generated/" & dir))
    let metadata = meta{string(basePath).replace(".html", ".md")}
    let original = readFile(string(i))
    let name = original.split("\n")[0].replace("#", "")
    var tagstring = ""
    if metadata != nil and metadata{"tags"} != nil:
      var first = true
      for tag_j in metadata{"tags"}:
        let tag = tag_j.getStr()
        if not first:
          tagstring &= ", "
        tagstring &= fmt"<a href=/tags/{tag}.html>{tag}</a>"
        first = false
        if not tags.hasKey(tag):
          tags[tag] = @[]
        tags[tag].add((string(basePath), name))
    let path = "generated/" & string(basePath)
    index.add((string(basePath), name, tagstring))
    let mdhtml = markdown(original)
    writeFile(string(path), applyTemplate(mdhtml, fmt"<p>{tagstring}</p>"))
  # Create index page
  var indexhtml = "<h2>Looking for something specific? Do CTRL+F to find it!</h2>"
  indexhtml &= "tag listing: "
  for i in tags.keys():
    indexhtml &= fmt"<a href=/tags/{i}.html>{i}</a>&MediumSpace;"
    var tagFile = fmt"<h1>Listing for tag '{i}'</h1>"
    for tag in tags[i]:
      tagFile &= fmt"<p><a href=/{tag[0]}>{tag[1]}</a></p>"
    writeFile(fmt"generated/tags/{i}.html", applyTemplate(tagFile))
  for i in index:
    indexhtml &= createLink(i)
  writeFile("generated/indexpage.html", applyTemplate(indexhtml))


when isMainModule:
  main()
