# c3httparser

Simple http header parser in c3

### Example

```c3
module example;
import c3httparser;
import std::io;

const char[] REQUEST = "GET /hello.txt HTTP/1.1\r\nUser-Agent: curl/7.16.3 libcurl/7.16.3 OpenSSL/0.9.7l zlib/1.2.3\r\nHost: www.example.com\r\nAccept-Language: en, mi\r\n\r\n";

fn void! main() {
  PartialRequest request = c3httparser::parse_request(REQUEST)!!;

  io::printfn("method -> %s", request.method);
  io::printfn("protocol version -> %s", request.http_version);
  io::printfn("head_size -> %d", request.head_size);
  io::printfn("uri -> %s", request.raw_path);

  foreach(Header header: request.headers)
    io::printfn("%s = %s", header.key, header.value);
}
```
