#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

enum TokenType {
    null,
    mv_left,
    mv_right,
    add,
    subtr,
    function_declaration,
    identifier,
    left_paren,
    right_paren,
    number,
    print_char,
    print_int,
    get_char,
    get_int,
    nl,
    start_loop,
    end_loop,
    cleanse,
    I_CONTINUE,
    I_BREAK,
    I_TERMINATE,
    if_,
    greater,
    less,
    equal,
    groreq,
    lessoreq,
    noteq,
    end_if,
    mention_cell,
    putch,
    escape_code,
    multiply,
    divide,
    modulo
};

typedef struct {
    int token;
    char *lexeme;
} Token;

Token i_Token(int type, char *lexeme) {
    Token res;
    res.token = type;
    res.lexeme = lexeme;

    return res;
}

bool isDigit(char c) {
    return c >= '0' && c <= '9';
}

bool isAlpha(char c) {
    return c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z';
}

bool isAlphaNumeric(char c) {
    return isDigit(c) || isAlpha(c);
}

char *tocharptr(char c) {
    char *result = malloc(2 * sizeof(char));

    result[0] = c;
    result[1] = '\0';

    return result;
}

const char peek(char arr[], int cur_i) {
    return arr[cur_i + 1];
}

Token tokenize(char c, char arr[], int cur_i) {
    switch (c) {
        case '<':
            return i_Token(mv_left, "<");
        case '>':
            return i_Token(mv_right, ">");
        case '+':
            return i_Token(add, "+");
        case '-':
            return i_Token(subtr, "-");
        case 'f':
            return i_Token(function_declaration, "f");
        case '(':
            return i_Token(left_paren, "(");
        case ')':
            return i_Token(right_paren, ")");
        case '.':
            return i_Token(print_char, ".");
        case '=':
            return i_Token(print_int, "=");
        case ';':
            return i_Token(I_BREAK, ";");
        case ':':
            return i_Token(I_TERMINATE, ":");
        case '?':
            return i_Token(I_CONTINUE, "?");
        case '\n':
            return i_Token(nl, "\n");
        case '[':
            return i_Token(start_loop, "[");
        case ']':
            return i_Token(end_loop, "]");
        case '#':
            return i_Token(cleanse, "#");
        case ',':
            return i_Token(get_char, ",");
        case '&':
            return i_Token(get_int, "&");
        case '{':
            return i_Token(if_, "{");
        case '}':
            return i_Token(end_if, "}");
        case 'g':
            return i_Token(greater, "g");
        case 'l':
            return i_Token(less, "l");
        case 'e':
            return i_Token(equal, "e");
        case 'G':
            return i_Token(groreq, "G");
        case 'L':
            return i_Token(lessoreq, "L");
        case 'n':
            return i_Token(noteq, "n");
        case '$':
            return i_Token(mention_cell, "$");
        case '@':
            return i_Token(putch, "@");
        case '\\':
            return i_Token(escape_code, "\\");
        case '*':
            return i_Token(multiply, "*");
        case '/':
            return i_Token(divide, "/");
        case '%':
            return i_Token(modulo, "%%");
        default:
            char *lexeme = malloc(sizeof(char));
            if(isDigit(c)) {
                strcat(lexeme, tocharptr(c));
                while(isDigit(peek(arr, cur_i))) {
                    strcat(lexeme, tocharptr(peek(arr, cur_i)));
                    cur_i++;
                }
                return i_Token(number, lexeme);
            } else if(isAlpha(c)) {
                strcat(lexeme, tocharptr(c));
                while(isAlphaNumeric(peek(arr, cur_i))) {
                    strcat(lexeme, tocharptr(peek(arr, cur_i)));
                    cur_i++;
                }
                return i_Token(identifier, lexeme);
            } else {
                return i_Token(null, tocharptr(c));
            }
            break;
    }
}

bool ifStmtEval(int if_oper, int ifval1, int ifval2) {
    switch(if_oper) {
        case greater:
            return ifval1 > ifval2;
        case less:
            return ifval1 < ifval2;
        case equal:
            return ifval1 == ifval2;
        case groreq:
            return ifval1 >= ifval2;
        case lessoreq:
            return ifval1 <= ifval2;
        case noteq:
            return ifval1 != ifval2;
        default:
            return false;
    }
}

void run(char *filename) {

    FILE* script = fopen(filename, "r");

    if(script == NULL) {
        perror("FILE NOT FOUND!");
    }

    char current;

    char code[2048];

    int i = 0;

    int skip = 0;

    while(current = fgetc(script)) {
        if(current == EOF) break;
        code[i] = current;
        i++;
    }

    Token tokens[2048];

    int cur_i = 0;
    for(i = 0; i < 2048; i++) {
        if(skip > 0) {
            skip--;
            continue;
        }

        cur_i = i;
        current = code[i];
        if(current == '\0') break;
        tokens[i] = tokenize(current, code, cur_i);
        if(tokens[i].token == number || tokens[i].token == identifier) {
            for(skip = 0; skip < strlen(tokens[i].lexeme); skip++);
            skip--;
        }
    }
    cur_i = i;

    int langarr[128];
    int currentIndex = 0;
    int stomachIndex = 0;

    bool inComment = false;

    int looptimes;
    bool inLoop = false;
    int loopat;
    bool loopArgs = false;

    int if_val_1;
    int if_val_2;
    int if_oper;

    fclose(script);

    // it's showtime

    for(i = 0; i <= cur_i; i++) {
        if(inComment) {
            if(tokens[i].token == nl) {
                inComment = false;
            }
            continue;
        }
        switch(tokens[i].token) {
            case mv_left:
                if(tokens[i + 1].token == left_paren) {
                    if(tokens[i + 2].token == number) {
                        currentIndex -= atoi(tokens[i + 2].lexeme);
                        break;
                    } else if(tokens[i + 2].token == mention_cell) {
                        currentIndex -= langarr[atoi(tokens[i + 3].lexeme)];
                        break;
                    }
                }
                currentIndex--;
                break;
            case mv_right:
                if(tokens[i + 1].token == left_paren) {
                    if(tokens[i + 2].token == number) {
                        currentIndex += atoi(tokens[i + 2].lexeme);
                        break;
                    } else if(tokens[i + 2].token == mention_cell) {
                        currentIndex += langarr[atoi(tokens[i + 3].lexeme)];
                        break;
                    }
                }
                currentIndex++;
                break;
            case add:
                if(tokens[i + 1].token == left_paren) {
                    if(tokens[i + 2].token == number) {
                        langarr[currentIndex] += atoi(tokens[i + 2].lexeme);
                        break;
                    } else if(tokens[i + 2].token == mention_cell) {
                        langarr[currentIndex] += langarr[atoi(tokens[i + 3].lexeme)];
                        break;
                    }
                }
                langarr[currentIndex]++;
                break;
            case subtr:
                if(tokens[i + 1].token == left_paren) {
                    if(tokens[i + 2].token == number) {
                        langarr[currentIndex] -= atoi(tokens[i + 2].lexeme);
                        break;
                    } else if(tokens[i + 2].token == mention_cell) {
                        langarr[currentIndex] -= langarr[atoi(tokens[i + 3].lexeme)];
                        break;
                    }
                }
                langarr[currentIndex]--;
                break;
            case function_declaration:
                break;
            case print_char:
                putchar(langarr[currentIndex]);
                break;
            case print_int:
                printf("%d\n", langarr[currentIndex]);
                break;
            case I_BREAK:
                inComment = true;
                break;
            case I_TERMINATE:
                exit(0);
            case I_CONTINUE:
                continue;
            case nl:
                langarr[stomachIndex]--;
            case start_loop:
                if(tokens[i + 1].token == left_paren) {
                    if(tokens[i + 2].token == number) {
                        looptimes = atoi(tokens[i + 2].lexeme);
                        loopArgs = false;
                    } else if(tokens[i + 2].token == mention_cell) {
                        if(tokens[i + 3].token == number) {
                            looptimes = langarr[atoi(tokens[i + 3].lexeme)];
                            loopArgs = false;
                        }
                    }
                } else {
                    looptimes = langarr[currentIndex];
                    loopArgs = true;
                }
                inLoop = true;
                loopat = i;
                break;
            case end_loop:
                if(inLoop) {
                    if(looptimes > 0) {
                        looptimes--;
                        i = loopat;
                        if(loopArgs) {
                            langarr[currentIndex]--;
                        }
                        continue;
                    } else {
                        inLoop = false;
                        loopat = 0;
                    }
                }
                break;
            case cleanse:
                while(langarr[currentIndex] > 0) {
                    langarr[currentIndex]--;
                }
                break;
            case get_char:
                scanf("\n %c", &langarr[currentIndex]);
                break;
            case get_int:
                scanf("\n %d", &langarr[currentIndex]);
                break;
            case if_:
                if(i + 2 < cur_i) {
                    switch(tokens[i + 2].token) {
                        case mention_cell:
                            if(tokens[i + 3].token == number) {
                                if_val_1 = langarr[atoi(tokens[i + 3].lexeme)];
                            }
                            break;
                        case number:
                            if_val_1 = atoi(tokens[i + 2].lexeme);
                            break;
                    }
                    if(i + 5 < cur_i) {
                        if_oper = tokens[i + 5].token;
                        if(i + 7 < cur_i) {
                            switch(tokens[i + 7].token) {
                                case mention_cell:
                                    if(tokens[i + 8].token == number) {
                                        if_val_2 = langarr[atoi(tokens[i + 8].lexeme)];
                                    }
                                    break;
                                case number:
                                    if_val_2 = atoi(tokens[i + 7].lexeme);
                                    break;
                            }
                            
                            bool if_exec = ifStmtEval(if_oper, if_val_1, if_val_2);

                            if(if_exec) {
                                while(tokens[i].token != nl) {
                                    i++;
                                }
                            } else {
                                while(tokens[i].token != end_if) {
                                    i++;
                                }
                            }
                            break;
                        }
                    }
                }
                break;
            case end_if:
                if_val_1 = 0;
                if_val_2 = 0;
                break;
            case putch:
                if(tokens[i + 1].token == escape_code) {
                    switch(tokens[i + 2].lexeme[0]) {
                        case 'n':
                            putchar('\n');
                            break;
                        case 'w':
                            putchar(' ');
                            break;
                        case 't':
                            putchar('\t');
                            break;
                        case '\\':
                            putchar('\\');
                            break;
                    }
                    break;
                }
                putchar(tokens[i + 1].lexeme[0]);
                i++;
                break;
            case multiply:
                if(tokens[i + 1].token == left_paren) {
                    if(tokens[i + 2].token == number) {
                        langarr[currentIndex] *= atoi(tokens[i + 2].lexeme);
                    } else if(tokens[i + 2].token == mention_cell) {
                        if(tokens[i + 3].token == number) {
                            langarr[currentIndex] *= langarr[atoi(tokens[i + 3].lexeme)];
                        }
                    }
                }
                break;
            case divide:
                if(tokens[i + 1].token == left_paren) {
                    if(tokens[i + 2].token == number) {
                        langarr[currentIndex] /= atoi(tokens[i + 2].lexeme);
                    } else if(tokens[i + 2].token == mention_cell) {
                        if(tokens[i + 3].token == number) {
                            langarr[currentIndex] /= langarr[atoi(tokens[i + 3].lexeme)];
                        }
                    }
                }
                break;
            case modulo:
                if(tokens[i + 1].token == left_paren) {
                    if(tokens[i + 2].token == number) {
                        langarr[currentIndex] %= atoi(tokens[i + 2].lexeme);
                    } else if(tokens[i + 2].token == mention_cell) {
                        if(tokens[i + 3].token == number) {
                            langarr[currentIndex] %= langarr[atoi(tokens[i + 3].lexeme)];
                        }
                    }
                }
                break;
        }
        if(langarr[stomachIndex] < 0) {
            puts("The program died of starvation :(");
            exit(1);
        }
    }
}

int main(int argc, char *argv[]) {
    for(int i = 1; i < argc; i++) {
        run(argv[i]);    
    }
}
