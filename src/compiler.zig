// * !
// The algorithm is based on Robert Nystrom's C implementation of Vaughan Pratt's top down operator precedence
// parsing algorithm. Massive thanks to both of them.
// * !

const std = @import("std");
const lexer = @import("lexer.zig");

// *
// Some typedefs
// *
const Token = lexer.Token;
const TokenType = lexer.TokenType;

// *
// The allocator
// *
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

// *
// The precedence enum.
// *
const PrecedenceEnum = enum {
    None,
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
};

// *
// The ParseRule structure thing from Nystrom's implementation.
// *
pub const ParseRule = struct {
    prefix: ?*const fn (c: *Compiler) void,
    infix: ?*const fn (c: *Compiler) void,
    postfix: ?*const fn (c: *Compiler) void,
    prec: PrecedenceEnum
};

// *
// The map, which maps Tokens to their Precedence structure.
// *
const TokenPrecedenceMap = std.EnumMap(TokenType, ParseRule);

const precedence = TokenPrecedenceMap.init(std.enums.EnumFieldStruct(TokenType, ?ParseRule, @as(?ParseRule, null)) {
    .Equal = ParseRule {
        .prefix = null,
        .infix = Compiler.binary_op,
        .postfix = null, 
        .prec = PrecedenceEnum.Assign
    },
    .Comma = ParseRule {
        .prefix = null,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.Comma
    },

    .Ampersand = ParseRule {
        .prefix = Compiler.unary_op,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.And
    },

    .Eq = ParseRule {
        .prefix = null,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.Equality
    },

    .Neq = ParseRule {
        .prefix = null,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.Equality
    },

    .Lt = ParseRule {
        .prefix = null,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.Comparison
    },

    .Lteq = ParseRule {
        .prefix = null,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.Comparison
    },

    .Gt = ParseRule {
        .prefix = null,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.Comparison
    },

    .Gteq = ParseRule {
        .prefix = null,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.Comparison
    },

    .Add = ParseRule {
        .prefix = Compiler.unary_op,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.Term
    },

    .Subtract = ParseRule {
        .prefix = Compiler.unary_op,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.Term
    },

    .Multiply = ParseRule {
        .prefix = null,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.Factor
    },

    .Divide = ParseRule {
        .prefix = null,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.Factor
    },

    .Modulo = ParseRule {
        .prefix = null,
        .infix = Compiler.binary_op,
        .postfix = null,
        .prec = PrecedenceEnum.Factor
    },

    .OpenRound = ParseRule {
        .prefix = Compiler.grouping,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .IntegerConstant = ParseRule {
        .prefix = Compiler.number,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .FloatConstant = ParseRule {
        .prefix = Compiler.number,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    // *
    // The people that nobody invited to the party, but they still showed up
    // *

    .StringConstant = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Deref = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .CloseRound = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .OpenSquare = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .CloseSquare = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .OpenBracket = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .CloseBracket = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Colon = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Dot = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Dollar = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Semicolon = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Pipe = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .If = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Else = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Loop = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Not = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Var = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Const = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .each_ptr = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .print_chr = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .print_num = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .SpecialDbg = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Identifier = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .None = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },

    .Eof = ParseRule {
        .prefix = null,
        .infix = null,
        .postfix = null,
        .prec = PrecedenceEnum.None
    },
});

// *
// The compiler struct
// *
pub const Compiler = struct {
    // *
    // The tokens to be parsed
    // *
    tokens: *std.ArrayList(Token),

    // *
    // The iterator
    // *
    i: usize,

    // *
    // Should we print debug info, or not?
    // *
    debug_flag: bool,

    // *
    // Parse a unary operation and print it
    // *
    pub fn unary_op(self: *Compiler) void {
        if (self.i <= 0) {
            std.debug.panic("Invalid call to unary_op.\n", .{});
        }

        const op = self.tokens.items[self.i - 1];

        if (self.debug_flag) {
            std.debug.print("{s}", .{ op.l.items });
        }

        self.parse_precedence(PrecedenceEnum.Unary);
    }

    // *
    // Parse a binary operation and print it
    // *
    pub fn binary_op(self: *Compiler) void {
        if (self.i <= 0) {
            std.debug.panic("Invalid call to binary_op.\n", .{});
        }

        const op = self.tokens.items[self.i - 1];

        const rule = precedence.get(op.t).?;

        if (self.debug_flag) {
            std.debug.print("{s} ", .{ op.l.items });
        }

        self.parse_precedence(@enumFromInt(@intFromEnum(rule.prec) + 1));
    }

    // *
    // Parse a grouping operation and print it
    // *
    pub fn grouping(self: *Compiler) void {
        std.debug.print("(", .{});
        self.expression();

        self.i -= 1;
        self.expect(TokenType.CloseRound);

        self.i += 1;

        std.debug.print(") ", .{});
    }

    pub fn number(self: *Compiler) void {
        if (self.i <= 0) {
            std.debug.panic("Invalid call to number.\n", .{});
        }

        const num = self.tokens.items[self.i - 1];

        if (self.debug_flag) {
            std.debug.print("{s}", .{ num.l.items });
            if (self.tokens.items[self.i].t != TokenType.CloseRound) {
                std.debug.print(" ", .{});
            }
        }
    }

    pub fn parse_precedence(self: *Compiler, prec: PrecedenceEnum) void {
        self.i += 1;

        if (self.i <= 0) {
            std.debug.panic("Invalid call to parse_precedence.\n", .{});
        }

        const prev_rule = precedence.get(self.tokens.items[self.i - 1].t);

        if (prev_rule == null) {
            self.error_report("Expected expression.\n", .{});
            return;
        }

        if (prev_rule.?.prefix == null) {
            self.error_report("Expected expression.\n", .{});
            return;
        }

        const prefix = prev_rule.?.prefix.?;

        prefix(self);

        while (@intFromEnum(prec) <= @intFromEnum(precedence.get(self.tokens.items[self.i].t).?.prec)) {
            self.i += 1;

            const infix_rule = precedence.get(self.tokens.items[self.i - 1].t).?;

            const infix = infix_rule.infix.?;

            infix(self);
        }
    }

    // *
    // Just reports an error.
    // *
    fn error_report(self: *Compiler, comptime fmt: []const u8, args: anytype) void {
        // *
        // I will try my best to improve the error messages, print a snippet of the erroneous code.
        // *
        std.debug.print("Error: line {d}, token {s}\n", .{
            self.tokens.items[self.i].line,
            @tagName(self.tokens.items[self.i].t)
        });

        std.debug.print(fmt, args);
    }

    fn expect(self: *Compiler, t: TokenType) void {
        if (self.i + 1 >= self.tokens.items.len or self.i + 1 < 0) {
            std.debug.panic("We are sorry, you have encountered a critial error!\nThis message means that the fault is in the compiler, not in your code.\n", .{});
        }

        if (self.tokens.items[self.i + 1].t != t) {
            self.error_report("Expected token {s}, found {s}.\n", .{ @tagName(t), @tagName(self.tokens.items[self.i + 1].t) });
            return;
        }

        self.i += 1;
    }

    // *
    // Function which initializes the state of a new compiler and the precedence EnumMap
    // *
    pub fn init(tokens: *std.ArrayList(Token), debug_info: bool) Compiler {
        return Compiler {
            .tokens = tokens,
            .i = 0,
            .debug_flag = debug_info
        };
    }

    pub fn expression(self: *Compiler) void {
        self.parse_precedence(PrecedenceEnum.Assign);
    }

};
