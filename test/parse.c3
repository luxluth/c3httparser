import c3httparser;
import std::io;

const char[] REQUEST = "GET /hello.txt HTTP/1.1\r\nUser-Agent: curl/7.16.3 libcurl/7.16.3 OpenSSL/0.9.7l zlib/1.2.3\r\nHost: www.example.com\r\nAccept-Language: en, mi\r\n\r\n";

fn void! test_request_parsing() @test {
  io::printfn("Request parsing");
  PartialRequest request = c3httparser::parse_request(REQUEST)!!;
  assert(request.method == HTTPMethod.GET);
  assert(request.http_version == "1.1");
  assert(request.raw_path == "/hello.txt");
  assert(request.head_size == 141);
  foreach(Header header: request.headers)
    io::printfn("%s = %s", header.key, header.value); 
}

const char[] RESPONSE = "HTTP/1.1 200 OK\r\nDate: Mon, 27 Jul 2009 12:28:53 GMT\r\nServer: Apache\r\nLast-Modified: Wed, 22 Jul 2009 19:15:56 GMT\r\nETag: \"34aa387-d-1568eb00\"\r\nAccept-Ranges: bytes\r\nContent-Length: 51\r\nVary: Accept-Encoding\r\nContent-Type: text/plain\r\n\r\nHello World! My payload includes a trailing CRLF.\r\n";

fn void! test_response_parsing() @test {
  io::printfn("Response parsing");
  PartialResponse response = c3httparser::parse_response(RESPONSE)!!;
 
  assert(response.status == "200");
  assert(response.status_message == "OK");
  assert(response.http_version == "1.1");
  assert(response.head_size == 237);
  foreach(Header header: response.headers)
    io::printfn("%s = %s", header.key, header.value); 
}


