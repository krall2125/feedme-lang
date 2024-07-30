// *
// Import std
// *
const std = @import("std");

// *
// Set up GPA
// *
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub const TokenType = enum {
    IntegerConstant,
    FloatConstant,
    StringConstant,

    AddressOf,
    Deref,
    Add,
    Subtract,
    Multiply,
    Divide,
    Modulo,

    OpenRound,
    CloseRound,
    OpenSquare,
    CloseSquare,
    OpenBracket,
    CloseBracket,
    Colon,
    Dot,
    Comma,
    Dollar,

    If,
    Else,
    Loop,
    Eq,
    Neq,
    Lt,
    Gt,
    Gteq,
    Lteq,
    each_ptr,
    print_chr,
    print_num,

    SpecialDbg,

    Identifier,

    None,
    Eof,
};

pub const Token = struct {
    t: TokenType,
    l: std.ArrayList(u8),
    line: usize
};

var current_line: usize = 1;

fn empty_token() Token {
    return Token{.t = TokenType.None, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line };
}

fn is_numeric(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn is_alpha(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
}

fn lex_numeric_constant(lines: []u8, i: *u32) !Token {
    var token = empty_token();

    while (is_numeric(lines[i.*])) : (i.* += 1) {
        if (lines[i.*] == 0) {
            token.t = TokenType.IntegerConstant;
            return token;
        }
        try token.l.append(lines[i.*]);
    }

    if (lines[i.*] != '.') {
        i.* -= 1;
        token.t = TokenType.IntegerConstant;
        return token;
    }

    try token.l.append('.');

    i.* += 1;

    while (is_numeric(lines[i.*])) : (i.* += 1) {
        if (lines[i.*] == 0) {
            break;
        }
        try token.l.append(lines[i.*]);
    }

    i.* -= 1;

    token.t = TokenType.FloatConstant;
    return token;
}

pub fn in_slice(comptime T: type, haystack: []const T, needle: T) bool {
    for (haystack) |thing| {
        if (thing == needle) {
            return true;
        }
    }
    return false;
}

pub fn filter_slice(comptime T: type, slice: []T, filter_fun: (fn (val: T) bool), dropped_element_fun: (fn (val: *const T) void)) !std.ArrayList(T) {
    var filtered = std.ArrayList(T).init(gpa.allocator());

    for (slice) |item| {
        if (!filter_fun(item)) {
            dropped_element_fun(&item);
            continue;
        }

        try filtered.append(item);
    }

    return filtered;
}

fn lex_identifier(lines: []u8, i: *u32) !Token {
    var token = empty_token();

    while (is_alpha(lines[i.*]) or is_numeric(lines[i.*])) : (i.* += 1) {
        if (lines[i.*] == 0) {
            break;
        }
        try token.l.append(lines[i.*]);
    }

    if (std.mem.eql(u8, token.l.items, "if")) {
        token.t = TokenType.If;
    }
    else if (std.mem.eql(u8, token.l.items, "else")) {
        token.t = TokenType.Else;
    }
    else if (std.mem.eql(u8, token.l.items, "eq")) {
        token.t = TokenType.Eq;
    }
    else if (std.mem.eql(u8, token.l.items, "neq")) {
        token.t = TokenType.SpecialDbg;
    }
    else if (std.mem.eql(u8, token.l.items, "gt")) {
        token.t = TokenType.Gt;
    }
    else if (std.mem.eql(u8, token.l.items, "lt")) {
        token.t = TokenType.Lt;
    }
    else if (std.mem.eql(u8, token.l.items, "gteq")) {
        token.t = TokenType.Gteq;
    }
    else if (std.mem.eql(u8, token.l.items, "lteq")) {
        token.t = TokenType.Lteq;
    }
    else if (std.mem.eql(u8, token.l.items, "dbg")) {
        token.t = TokenType.SpecialDbg;
    }
    else if (std.mem.eql(u8, token.l.items, "each_ptr")) {
        token.t = TokenType.each_ptr;
    }
    else if (std.mem.eql(u8, token.l.items, "print_chr")) {
        token.t = TokenType.print_chr;
    }
    else if (std.mem.eql(u8, token.l.items, "print_num")) {
        token.t = TokenType.print_num;
    }
    else {
        token.t = TokenType.Identifier;
    }

    // const keywords = [_][*]u8 {"begin", "end", "print", "func", "pop", "swap", "dup"};

    // if (in_slice([]const u8, keywords, token.l.items)) {
        
    // }
    
    i.* -= 1;
    
    return token;
}

fn lex_string(lines: []u8, i: *u32) !Token {
    var token = empty_token();

    i.* += 1;

    while (lines[i.*] != '\"' and lines[i.*] != 0) : (i.* += 1) {
        try token.l.append(lines[i.*]);
    }

    token.t = TokenType.StringConstant;

    return token;
}

fn lex_character(lines: []u8, i: *u32) !Token {
    switch (lines[i.*]) {
        '&' => {
            var token = Token{.t = TokenType.AddressOf, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '^' => {
            var token = Token{.t = TokenType.Deref, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '+' => {
            var token = Token{.t = TokenType.Add, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '-' => {
            var token = Token{.t = TokenType.Subtract, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '*' => {
            var token = Token{.t = TokenType.Multiply, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '/' => {
            var token = Token{.t = TokenType.Divide, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '%' => {
            var token = Token{.t = TokenType.Modulo, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '(' => {
            var token = Token{.t = TokenType.OpenRound, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        ')' => {
            var token = Token{.t = TokenType.CloseRound, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '[' => {
            var token = Token{.t = TokenType.OpenSquare, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        ']' => {
            var token = Token{.t = TokenType.CloseSquare, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '{' => {
            var token = Token{.t = TokenType.OpenBracket, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '}' => {
            var token = Token{.t = TokenType.CloseBracket, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        ':' => {
            var token = Token{.t = TokenType.Colon, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '.' => {
            var token = Token{.t = TokenType.Dot, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        ',' => {
            var token = Token{.t = TokenType.Comma, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '$' => {
            var token = Token{.t = TokenType.Dollar, .l = std.ArrayList(u8).init(gpa.allocator()), .line = current_line};
            try token.l.append(lines[i.*]);
            return token;
        },
        '\"' => {
            return lex_string(lines, i);
        },
        '0'...'9' => {
            return lex_numeric_constant(lines, i);
        },
        'a'...'z', 'A'...'Z', '_' => {
            return lex_identifier(lines, i);
        },
        ' ', '\t', 0 => {
            return empty_token();
        },
        '\n' => {
            current_line += 1;
            return empty_token();
        },
        else => {
            std.debug.print("i like men {d}\n", .{ lines[i.*] });
            return empty_token();
        }
    }
}

pub fn lex_str_arraylist(str: std.ArrayList(u8)) !std.ArrayList(Token) {
    var i: u32 = 0;

    var tokens = std.ArrayList(Token).init(gpa.allocator());

    while (i < str.items.len) : (i += 1) {
        try tokens.append(lex_character(str.items, &i) catch empty_token());
    }

    const actual_tokens = try filter_slice(Token, tokens.items, struct {
        pub fn filter_fun(val: Token) bool {
            return val.t != TokenType.None;
        }
    }.filter_fun, struct {
        pub fn dropped_element_fun(val: *const Token) void {
            val.*.l.deinit();
        }
    }.dropped_element_fun);

    defer tokens.deinit();
    
    return actual_tokens;
}

pub fn lex(filename: [*:0]u8) !std.ArrayList(Token) {
    var file = std.fs.cwd().openFile(std.mem.span(filename), .{}) catch unreachable;
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var char: u8 = in_stream.readByte() catch 0;

    var file_contains = std.ArrayList(u8).init(gpa.allocator());

    while (char != 0) : (char = in_stream.readByte() catch 0) {
        try file_contains.append(char);
    }

    try file_contains.append(0);

    // std.debug.print("{s}\n", .{ file_contains.items });
    
    defer file_contains.deinit();

    var tokens = try lex_str_arraylist(file_contains);

    var eof = empty_token();
    eof.t = TokenType.Eof;
    eof.line = current_line;
    try tokens.append(eof);

    return tokens;
}
