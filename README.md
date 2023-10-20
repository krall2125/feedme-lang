# An esoteric programming language
feedme-lang is an esoteric programming language written in C.
It took me two days to write a complete programming language with if statements, operations,
loops and more.

# How the language works
The syntax looks almost identical to brainfuck syntax. That's because writing a brainfuck like language
is very easy. But do not be fooled. That does not mean the language works just like brainfuck.
In the language you move around cells just like in brainfuck using < and >. You can increase or decrease the number stored in the cell using + and -.
There is a stomach cell. This is the cell number 0. Or number 1 if you love Lua. While it is bigger than zero the program will continue running.
On every newline the number 1 gets subtracted from the stomach cell.

You can print the value of the cell as a character using . or as a number using = (that's a feature that is not in brainfuck).
You can also get character input using , or number input using & (that's another feature missing in brainfuck).
You can use @ and a character behind it to print the character. To print a space this way use \w behind the @.

All the basic operators (>, <, +, -, [) and some other operators I added to this brainfuck clone (*, /, %) can be used as functions where the argument
is the number of times this operator should execute. You can also use a value stored in a cell as the argument by using $ and the number of the cell behind it.

The operator * multiplies the current cell by the argument.
The operator / divides the current cell by the argument.
The operator % modulos (if that word exists) the current cell by the argument.

# if statements
To start an if statement use {.
After it, put a space and then the condition.
You can pass numbers or cells as the values for comparation in the condition.
The implemented operators (put it between the values for comparation obviously) are:
e - equal
g - greater
l - less
G - greater or equal
L - less or equal
n - not equal
Don't forget to end the if statement body with }.

# loops
Originally, loops work just like in brainfuck. You start'em with [ and end with ] and their body executes as long as the value of the current cell is above 0.
But if you use the [ with an argument, the loop executes the number of times provided by the argument.

# Summarizing
The language is fucking confusing. It doesn't work like brainfuck and I don't know why.
You also get only 128 cells to move around and the interpreter doesn't tell you about errors in your code.
You also can only write 2048 symbols in one file or the interpreter will crash.