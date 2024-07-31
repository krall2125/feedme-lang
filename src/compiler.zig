const std = @import("std");
const lexer = @import("lexer.zig");

const Token = lexer.Token;
const TokenType = lexer.TokenType;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

fn op_precedence(t: TokenType) u8 {
    return (switch (t) {
        TokenType.Comma => 1,                                               // , operator for comma expressions
        TokenType.Eq, TokenType.Neq => 2,                                   // Equality operators
        TokenType.Lt, TokenType.Lteq, TokenType.Gt, TokenType.Gteq => 3,    // Comparsion operators, greater than etc.
        TokenType.Not, TokenType.AddressOf, TokenType.Deref => 4,           // Various value-modifying prefix operators

        TokenType.StringConstant,
        TokenType.IntegerConstant,
        TokenType.FloatConstant,
        TokenType.Identifier => 5,                                          // Constants

        TokenType.OpenRound => 6,                                           // ( for grouping
        TokenType.Colon => 7,                                               // : operator for static typing
        else => 0
    });
}

fn expression() void {
}
