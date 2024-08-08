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

    Ampersand,
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
    Equal, // not the same as Eq
    Semicolon,
    Pipe,

    If,
    Else,
    Loop,
    Eq,
    Neq,
    Lt,
    Gt,
    Gteq,
    Lteq,
    Not,
    Var,
    Const,
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
    else if (std.mem.eql(u8, token.l.items, "var")) {
        token.t = TokenType.Var;
    }
    else if (std.mem.eql(u8, token.l.items, "const")) {
        token.t = TokenType.Const;
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
    var token = empty_token();
    switch (lines[i.*]) {
        '&' => {
            token.t = TokenType.Ampersand;
            try token.l.append(lines[i.*]);
            return token;
        },
        '^' => {
            token.t = TokenType.Deref;
            try token.l.append(lines[i.*]);
            return token;
        },
        '+' => {
            token.t = TokenType.Add;
            try token.l.append(lines[i.*]);
            return token;
        },
        '-' => {
            token.t = TokenType.Subtract;
            try token.l.append(lines[i.*]);
            return token;
        },
        '*' => {
            token.t = TokenType.Multiply;
            try token.l.append(lines[i.*]);
            return token;
        },
        '/' => {
            token.t = TokenType.Divide;
            try token.l.append(lines[i.*]);
            return token;
        },
        '%' => {
            token.t = TokenType.Modulo;
            try token.l.append(lines[i.*]);
            return token;
        },
        '(' => {
            token.t = TokenType.OpenRound;
            try token.l.append(lines[i.*]);
            return token;
        },
        ')' => {
            token.t = TokenType.CloseRound;
            try token.l.append(lines[i.*]);
            return token;
        },
        '[' => {
            token.t = TokenType.OpenSquare;
            try token.l.append(lines[i.*]);
            return token;
        },
        ']' => {
            token.t = TokenType.CloseSquare;
            try token.l.append(lines[i.*]);
            return token;
        },
        '{' => {
            token.t = TokenType.OpenBracket;
            try token.l.append(lines[i.*]);
            return token;
        },
        '}' => {
            token.t = TokenType.CloseBracket;
            try token.l.append(lines[i.*]);
            return token;
        },
        ':' => {
            token.t = TokenType.Colon;
            try token.l.append(lines[i.*]);
            return token;
        },
        '.' => {
            token.t = TokenType.Dot;
            try token.l.append(lines[i.*]);
            return token;
        },
        ',' => {
            token.t = TokenType.Comma;
            try token.l.append(lines[i.*]);
            return token;
        },
        '$' => {
            token.t = TokenType.Dollar;
            try token.l.append(lines[i.*]);
            return token;
        },
        '!' => {
            token.t = TokenType.Not;
            try token.l.append(lines[i.*]);
            return token;
        },
        '=' => {
            token.t = TokenType.Equal;
            try token.l.append(lines[i.*]);
            return token;
        },
        ';' => {
            token.t = TokenType.Semicolon;
            try token.l.append(lines[i.*]);
            return token;
        },
        '|' => {
            token.t = TokenType.Pipe;
            try token.l.append(lines[i.*]);
            return token;
        },
        '\"' => {
            token.l.deinit();
            return lex_string(lines, i);
        },
        '0'...'9' => {
            token.l.deinit();
            return lex_numeric_constant(lines, i);
        },
        'a'...'z', 'A'...'Z', '_' => {
            token.l.deinit();
            return lex_identifier(lines, i);
        },
        ' ', '\t', 0 => {
            token.l.deinit();
            return empty_token();
        },
        '\n' => {
            token.l.deinit();
            current_line += 1;
            return empty_token();
        },
        else => {
            token.l.deinit();
            std.debug.print("Unrecognized character {d} at line {d}\n", .{ lines[i.*], current_line });
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
