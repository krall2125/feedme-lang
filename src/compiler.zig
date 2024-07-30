const std = @import("std");
const lexer = @import("lexer.zig");

const Token = lexer.Token;
const TokenType = lexer.TokenType;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

// TODO: Some sort of parser
