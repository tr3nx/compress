import strutils, sequtils, system, algorithm, sugar, os

type
  Node = ref object
    left : Node
    right: Node
    byte : char
    count: int

  Lookup = object
    byte: char
    bits: string

  Packer = object
    bits: string

proc build_table(node: Node, path: string = ""): seq[Lookup] =
  if ord(node.byte) == 0:
    build_table(node.left, path & "0") & build_table(node.right, path & "1")
  else:
    @[Lookup(byte: node.byte, bits: path)]

proc look_up_byte(lookup: seq[Lookup], byte: char): string =
  for _, l in lookup:
    if l.byte == byte:
      return l.bits.len.toBin(8) & l.bits

proc look_up_bits(lookup: seq[Lookup], bits: string): string =
  for _, l in lookup:
    if l.bits == bits:
      return $l.byte

proc unpack(packer: var Packer, num: int): string =
  result = packer.bits[0..num-1]
  packer.bits.removePrefix(result)

proc compress(original: string): string =
  var tree: seq[Node]

  for _, c in deduplicate(toSeq(original)):
    tree.add(Node(byte: c, count: original.count(c)))

  while tree.len > 1:
    tree.sort((x, y: Node) => x.count < y.count)
    let n1 = tree.pop()
    let n2 = tree.pop()
    tree.add(Node(left: n1, right: n2, count: n1.count + n2.count))

  let table = build_table(tree[0])

  result.add original.len.toBin(32)  # pack length of original data 0-(2^32-1)
  result.add table.len.toBin(8)      # pack table entry count 0-255

  for _, t in table:
    result.add t.byte.int.toBin(8)   # pack dec of char
    result.add t.bits.len.toBin(8)   # pack length of char bits
    result.add t.bits                # pack the bits themselves

  for _, c in toSeq(original):
    result.add table.look_up_byte(c) # pack each original byte

proc decompress(compressed: string): string =
  var packer = Packer(bits: compressed)
  let data_len: int = fromBin[int](packer.unpack(32))   # original data length
  let table_len: int8 = fromBin[int8](packer.unpack(8)) # table entry count

  var table: seq[Lookup]
  for _ in countup(0, table_len-1):
    let byte: char = fromBin[int8](packer.unpack(8)).char # original byte
    let bits_len: int8 = fromBin[int8](packer.unpack(8))  # byte's bits length
    let bits: string = $packer.unpack(bits_len)           # each byte's bits
    table.add(Lookup(byte: byte, bits: bits))             # rebuild table

  for _ in countup(0, data_len-1):
    let next_len: int8 = fromBin[int8](packer.unpack(8))    # next bits length
    result.add look_up_bits(table, packer.unpack(next_len)) # byte from bits

let args = commandLineParams()
let input: string =
  if args.len > 1: args[1]
  else: stdin.readAll

if args[0] == "decompress": stdout.write decompress(input)
else: stdout.write compress(input)
