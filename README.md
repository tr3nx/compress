# Compressor in Nim
#### Using Huffman coding with prefix tree

`cat ./compress.nim | shasum`
`63bce75fc050ef3dc34fde476cb57dc3cfa03094`

`cat ./compress.nim | ./compress compress | ./compress decompress | shasum`
`63bce75fc050ef3dc34fde476cb57dc3cfa03094`
