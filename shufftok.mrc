alias shufftok {
  var %t = $$1
  var %c = $$2
  var %tot = $numtok(%t,%c)
  while (%tot > 0) {
    var %r = $rand(1,$numtok(%t,%c))
    var %n = $addtok(%n,$gettok(%t,%r,%c),%c)
    var %t = $deltok(%t,%r,%c)
    dec %tot
  }
  return %n
}