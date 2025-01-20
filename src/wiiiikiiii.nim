import markdown
import std/strutils
import std/dirs
import std/paths
import std/strformat
import std/json
import std/tables
import std/algorithm

const pageName = "pogging.fish"
const donation = "<p><a href='https://bsky.app/profile/pogging.fish'>Follow me on Bluesky</a></p>"
const tmpl = readFile("wiki/templates/base.html")
let meta = parseFile("wiki/meta.json")

proc applyTemplate(page: string, tags: string = "", date: string = "(meta pages have no date)", name = ""): string =
  return multireplace(tmpl,
    [("__varHtmlpage__var", page),
     ("__varTags__var", tags),
     ("__varCreationdate__var", date),
     ("__varWikiName__var", pageName),
     ("__varPageName__var", name),
     ("__varDonate__var", donation)
    ]
  )

proc getPostDate(i: string): int =
  let d = meta{i}{"creationdate"}
  if d == nil:
    return 19700101
  else:
    return d.getInt()

proc customCmp(i: (string, string, string), i2: (string, string, string)): int =
  return cmp(
    getPostDate(i[0]),
    getPostDate(i2[0])
  )

proc intToDate(i: int): string =
  let s = $i
  return fmt"{s[0..3]}-{s[4..5]}-{s[6..7]}"

proc createLink(i: (string, string, string)): string =
  return fmt"<p><a href=/{i[0]}>{i[1]}</a> on {intToDate(getPostDate(i[0]))} <small>&ThickSpace;{i[2]}</small><p>"

proc getPostTags(i: string): JsonNode =
  let t = meta{i}{"tags"}
  if t == nil:
    return newJArray()
  else:
    return t

proc main() =
  if dirExists(Path("generated")):
    removeDir(Path("generated"))
  createDir(Path("generated"))
  createDir(Path("generated/tags"))
  writeFile("generated/base.css", readFile("wiki/templates/base.css"))
  # Generate html files
  var index = newSeq[(string, string, string)]()
  var tags = initTable[string, string]()
  for i in walkDirRec(Path("wiki/pages")):
    let filePath = Path(string(i).split("/")[2..^1].join("/"))
    for dir in string(i).split("/")[2..^2]:
      createDir(Path("generated/" & dir))
    if not string(filePath).endsWith(".md"):
      writeFile(fmt"generated/{string(filePath)}", readFile(fmt"wiki/pages/{string(filePath)}"))
      continue
    let basePath = filePath.changeFileExt(".html")
    let metadata = meta{string(basePath)}
    let original = readFile(string(i))
    let name = original.split("\n")[0].replace("#", "").strip()
    var tagstring = ""
    var first = true
    for tag_j in getPostTags(string(basePath)):
      let tag = tag_j.getStr()
      if not first:
        tagstring &= ", "
      tagstring &= fmt"<a href=/tags/{tag}.html>{tag}</a>"
      first = false
      if not tags.hasKey(tag):
        tags[tag] = ""
    let path = "generated/" & string(basePath)
    index.add((string(basePath), name, tagstring))
    let mdhtml = markdown(original)
    writeFile(string(path), applyTemplate(mdhtml, fmt"<p>{tagstring}</p>", fmt"{intToDate(getPostDate(string(basePath)))}", name))
  # Create index page
  var indexhtml = "<h2>Looking for something specific? Do CTRL+F to find it!</h2>"
  indexhtml &= "tag listing: "
  index.sort(customCmp, SortOrder.Descending)
  for i in tags.keys():
    indexhtml &= fmt"<a href=/tags/{i}.html>{i}</a>&MediumSpace;"
    tags[i] &= fmt"<h1>Listing for tag '{i}'</h1>"
  indexhtml &= "<p>(newest posts are first.)</p>"
  for i in index:
    indexhtml &= createLink(i)
    for tag in getPostTags(i[0]):
      tags[tag.getStr()] &= createLink(i)
  for i in tags.keys():
    writeFile(fmt"generated/tags/{i}.html", applyTemplate(tags[i], name=i))
  writeFile("generated/indexpage.html", applyTemplate(indexhtml, name="Index"))


when isMainModule:
  main()
