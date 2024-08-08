const std = @import("std");
const lexer = @import("lexer.zig");

const Token = lexer.Token;
const TokenType = lexer.TokenType;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const OperatorContext = enum {
    Prefix,
    Infix,
    Postfix,
    None,
};

const Precedence = enum {
    Assign,
    Comma,
    And,
    Equality,
    Comparison,
    Term,
    Factor,
    Unary,
    Grouping,
    Primary,
    None,
    Some
};

fn op_precedence(t: TokenType, ctx: OperatorContext) Precedence {
    return switch (t) {
        TokenType.Equal =>
            switch (ctx) {
                OperatorContext.Infix => Precedence.Assign,
                OperatorContext.None => Precedence.Some,
                else => Precedence.None
            },

        TokenType.Comma =>
            switch (ctx) {
                OperatorContext.Infix => Precedence.Comma,
                OperatorContext.None => Precedence.Some,
                else => Precedence.None
            },

        TokenType.Ampersand =>
            switch (ctx) {
                OperatorContext.Prefix => Precedence.Unary,
                OperatorContext.Infix => Precedence.And,
                OperatorContext.None => Precedence.Some,
                else => Precedence.None
            },

        TokenType.Eq, TokenType.Neq =>
            switch (ctx) {
                OperatorContext.Infix => Precedence.Equality,
                OperatorContext.None => Precedence.Some,
                else => Precedence.None
            },

        TokenType.Lt, TokenType.Lteq, TokenType.Gt, TokenType.Gteq =>
            switch (ctx) {
                OperatorContext.Infix => Precedence.Comparison,
                OperatorContext.None => Precedence.Some,
                else => Precedence.None
            },

        TokenType.Add, TokenType.Subtract =>
            switch (ctx) {
                OperatorContext.Prefix => Precedence.Unary,
                OperatorContext.Infix => Precedence.Term,
                OperatorContext.None => Precedence.Some,
                else => Precedence.None
            },

        TokenType.Multiply, TokenType.Divide, TokenType.Modulo =>
            switch (ctx) {
                OperatorContext.Infix => Precedence.Factor,
                else => Precedence.None
            },

        TokenType.Not, TokenType.Deref =>
            switch (ctx) {
                OperatorContext.Prefix => Precedence.Unary,
                OperatorContext.None => Precedence.Some,
                else => Precedence.None
            },

        TokenType.OpenRound => Precedence.Grouping,

        TokenType.StringConstant,
        TokenType.IntegerConstant,
        TokenType.FloatConstant,
        TokenType.Identifier => Precedence.Primary,
        else => Precedence.None
    };
}

// Every operator which can vary in the context returns Precedence.Some on OperatorContext.None for the program to know that they have some sort of precedence.

const ExprType = enum {
    Literal,
    Unary,
    Binary
};

const Expr = struct {
    operands: std.ArrayList(Expr),
    operator: TokenType,
    t: ExprType,
    // fn eval(self: *Expr) !std.ArrayList(f64) {

    // }
};

pub const Compiler = struct {
    tokens: *std.ArrayList(Token),
    i: usize,
    debug_flag: bool,

    // *
    // Just reports an error.
    // *
    pub fn error_report(self: *Compiler, comptime fmt: []const u8, args: anytype) void {
        std.debug.print("Error at line {d}, token {s}\n", .{ self.tokens.items[self.i].line, @tagName(self.tokens.items[self.i].t) });
        std.debug.print(fmt, args);
    }

    pub fn expression(self: *Compiler, lastindex: usize) Expr {
        const expr: Expr = Expr {
            .t = undefined,
            .operands = std.ArrayList(Expr).init(gpa.allocator()),
            .operator = undefined
        };

        // TODO: better expression parsing
        return expr;
    }

};
