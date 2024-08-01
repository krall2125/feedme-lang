const std = @import("std");
const lexer = @import("lexer.zig");

const Token = lexer.Token;
const TokenType = lexer.TokenType;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const OperatorContext = enum {
    Prefix,
    Infix,
    Postfix,
    None,   // for literal expressions - they technically do not count as any kind of operator
};

fn op_precedence(t: TokenType, ctx: OperatorContext) u8 {
    return switch (t) {
        TokenType.Equal =>
            switch (ctx) {
                OperatorContext.Infix => 1,
                else => 0
            },                                               // = operator for variable assignment

        TokenType.Comma =>
            switch (ctx) {
                OperatorContext.Infix => 2,
                else => 0
            },                                               // , operator for comma expressions

        TokenType.Ampersand =>
            switch (ctx) {
                OperatorContext.Prefix => 6,
                OperatorContext.Infix => 3,
                else => 0
            },

        TokenType.Eq, TokenType.Neq =>
            switch (ctx) {
                OperatorContext.Infix => 4,
                else => 0
            },                                              // Equality operators

        TokenType.Lt, TokenType.Lteq, TokenType.Gt, TokenType.Gteq =>
            switch (ctx) {
                OperatorContext.Infix => 5,
                else => 0
            },                                              // Comparsion operators, greater than etc.

        TokenType.Not, TokenType.Deref =>
            switch (ctx) {
                OperatorContext.Prefix => 6,
                else => 0
            },                                              // Various value-modifying prefix operators


        TokenType.StringConstant,
        TokenType.IntegerConstant,
        TokenType.FloatConstant,
        TokenType.Identifier => 7,                                          // Constants

        TokenType.OpenRound => 8,                                           // ( for grouping
        TokenType.Colon => 9,                                               // : operator for static typing
        else => 0
    };
}

const ExprType = enum {
    Literal,
    Unary,
    Binary
};

const Expr = struct {
    operands: std.ArrayList(Expr),
    operator: TokenType,
    t: ExprType,
    // fn eval(self: *Expr) !f64 {

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

    pub fn expression(self: *Compiler) Expr {
        var lowest_precedence: u8 = 9;
        var lowest_precedence_pos: usize = 0;
        var ctx: OperatorContext = undefined;

        const root: Expr = undefined;

        // Parse and evaluate and print single expression?
        while (self.i < self.tokens.items.len) : (self.i += 1) {
            if (self.debug_flag) {
                std.debug.print("Current token: '{s}', {s}, {d}\n", .{ self.tokens.items[self.i].l.items, @tagName(self.tokens.items[self.i].t), self.tokens.items[self.i].line });
            }

            if (self.tokens.items[self.i].t == TokenType.Eof) break;

            if (self.i + 1 < self.tokens.items.len) {
                const is_current_literal_expr = op_precedence(self.tokens.items[self.i].t, OperatorContext.Prefix) == 7;

                const is_next_literal_expr = op_precedence(self.tokens.items[self.i + 1].t, OperatorContext.Prefix) == 7;
                const is_prev_literal_expr = self.i > 0 and self.i - 1 < self.tokens.items.len and op_precedence(self.tokens.items[self.i - 1].t, OperatorContext.Prefix) == 7;

                if ((is_current_literal_expr and is_next_literal_expr) or (is_current_literal_expr and is_prev_literal_expr)) {
                    self.error_report("Invalid expression: two literal expressions, one after another.\nPlease, check the ordering of your code.\n", .{ });
                }
                else if (is_current_literal_expr) {
                    continue;
                }

                if (is_next_literal_expr and is_prev_literal_expr) {
                    ctx = OperatorContext.Infix;
                }
                else if (is_next_literal_expr) {
                    ctx = OperatorContext.Prefix;
                }
                else if (is_prev_literal_expr) {
                    ctx = OperatorContext.Postfix;
                }
                else {
                    continue;
                }
            }

            // 2 + 2 * 2 - 5
            // -
            // |\
            // + 5
            // |\
            // * 2
            // |\
            // 2 2

            if (op_precedence(self.tokens.items[self.i].t, ctx) < lowest_precedence) {
                lowest_precedence = op_precedence(self.tokens.items[self.i].t, ctx);
                lowest_precedence_pos = self.i;
            }
        }

        std.debug.print("lowest precedence token: {s}, {d}\n", .{ @tagName(self.tokens.items[lowest_precedence_pos].t), lowest_precedence_pos });

        return root;
    }

};
