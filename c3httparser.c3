module c3httparser;
import std::io;

enum HTTPMethod {
  /** Used to establish a network connection to a resource. **/
  CONNECT,
  /** Requests that a resource be removed. **/
  DELETE,
  /** Requests a representation of a resource. **/
  GET,
  /** Requests the headers of a resource without the body. **/
  HEAD,
  /** Describes the communication options for the target resource. **/
  OPTIONS,
  /** Applies partial modifications to a resource. **/
  PATCH,
  /** Submits data to be processed to a specified resource. **/
  POST,
  /** Updates a resource or creates a new resource if it does not exist. **/
  PUT,
  /** Performs a message loop-back test along the path to the target resource. **/
  TRACE,
}

fn HTTPMethod! http_method_from_string(String s) @private {
  switch(s) {
    case "GET": return HTTPMethod.GET;
    case "HEAD": return HTTPMethod.HEAD;
    case "POST": return HTTPMethod.POST;
    case "PUT": return HTTPMethod.PUT;
    case "DELETE": return HTTPMethod.DELETE;
    case "CONNECT": return HTTPMethod.CONNECT;
    case "OPTIONS": return HTTPMethod.OPTIONS;
    case "TRACE": return HTTPMethod.TRACE;
    case "PATCH": return HTTPMethod.PATCH;
  }

  return HTTParserParsingError.UNKNOWN_HTTP_METHOD?;
}

fault HTTParserParsingError {
  EMPTY_HEADER,
  INVALID_HEADER,
  UNKNOWN_HTTP_METHOD,
  INVALID_HTTP_VERSION_FORMAT,
  WRONG_HEADER
}

struct Header {
  String key;
  String value;
}

struct PartialRequest {
  HTTPMethod method;
  Header[] headers;
  String http_version;
  String raw_path;
  usz head_size;
}

struct PartialResponse {
  String status;
  String status_message;
  Header[] headers;
  String http_version;
  usz head_size;
}

const String CRLF @private = "\r\n"; 

fn usz get_head_size(char[] content) {
  usz size = 0;
  
  bool has_r = false;
  bool has_n = false;
  
  ushort full_encounter = 0;

  foreach(char c: content) {
    defer size++;

    if (c == '\r') { 
      has_r = true; 
      continue;
    }

    if (c == '\n') has_n = true;

    if (has_r && has_n) { 
      full_encounter++;
      has_r = false;
      has_n = false;
    } else {
      full_encounter = 0;
    }

    if (full_encounter == 2) {
        break;
    }
  }

  return size;
}

fn usz count_headers(String[] lines) @private {
  usz count = 0;
  foreach(String line: lines)
    if (line.len > 0) count++;

  return count;
}

fn Header[]! parse_header_fields(String[] header_lines, Allocator allocator) @private {
  usz capacity = count_headers(header_lines);
  Header[] headers = allocator::alloc_array(allocator, Header, capacity);
  usz idx = 0;
  foreach(String line: header_lines) {
    if (line.len > 0) {
      String[] key_value = line.tsplit(":", 2);
      if (key_value.len == 2) {
        String key = key_value[0];
        String value = key_value[1];
        headers[idx++] = Header {
          .key = key.trim(), 
            .value = value.trim()
        };
      } else {
        return HTTParserParsingError.WRONG_HEADER?;
      }
    }
  }

  return headers;
}

fn PartialRequest! parse_request(char[] content, Allocator allocator = allocator::temp()) {
  PartialRequest req = {};

  req.head_size = get_head_size(content);
  String[] head_lines = ((String)content[0..req.head_size-1]).split(CRLF);
  String[] header_lines = head_lines[1..];
  if (head_lines.len == 0) {
    return HTTParserParsingError.EMPTY_HEADER?;
  }

  String[] head_value = head_lines[0].tsplit(" ", 3);
  
  if (head_value.len != 3) {
    return HTTParserParsingError.INVALID_HEADER?;
  }

  req.method = http_method_from_string(head_value[0])!;
  req.raw_path = head_value[1];
  String[] http_version = head_value[2].tsplit("/", 2);
  if (http_version.len != 2) {
    return HTTParserParsingError.INVALID_HTTP_VERSION_FORMAT?;
  }

  String proto = http_version[0];
  String version = http_version[1];

  if (proto != "HTTP") {
    return HTTParserParsingError.INVALID_HTTP_VERSION_FORMAT?;
  }

  req.http_version =  version;
  req.headers = parse_header_fields(header_lines, allocator)!;

  return req;
}

fn PartialResponse! parse_response(char[] content, Allocator allocator = allocator::temp()) {
  PartialResponse resp = {};

  resp.head_size = get_head_size(content);
  String[] head_lines = ((String)content[0..resp.head_size-1]).split(CRLF);
  String[] header_lines = head_lines[1..];
  if (head_lines.len == 0) {
    return HTTParserParsingError.EMPTY_HEADER?;
  }

  String[] head_value = head_lines[0].tsplit(" ", 3);
  if (head_value.len != 3) {
    return HTTParserParsingError.INVALID_HEADER?;
  }


  String[] http_version = head_value[0].tsplit("/", 2);
  if (http_version.len != 2) {
    return HTTParserParsingError.INVALID_HTTP_VERSION_FORMAT?;
  }

  String proto = http_version[0];
  String version = http_version[1];

  if (proto != "HTTP") {
    return HTTParserParsingError.INVALID_HTTP_VERSION_FORMAT?;
  }

  resp.http_version =  version;
  resp.status = head_value[1];
  resp.status_message = head_value[2];
  resp.headers = parse_header_fields(header_lines, allocator)!;

  return resp;
}
