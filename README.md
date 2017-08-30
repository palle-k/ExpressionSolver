# ExpressionSolver 

A solver for simple mathematical expressions.

This project demonstrates the use of context free grammars
to solve expressions by traversing the syntax tree of the expression.

## How it works

The parser uses a context free grammar which respects operator precedence and associativity:

```bnf
<sum> ::= <sum> <binop-add-sub> <product> | <product>
<product> ::= <power> | <product> <binop-mul-div> <power>
<power> ::= <atom> | <atom> <binop-pow> <power> | <unop> <power>
<atom> ::= <brackets> | <integer> | <real> | <variable> | <function>
<brackets> ::= '(' <sum> ')'
<binop-add-sub> ::= '+' | '-'
<binop-mul-div> ::= '*' | '/'
<binop-pow> ::= '^'
<unop> ::= '+' | '-'
<integer> ::= <integer> <digit> | <digit>
<real> ::= <integer> '.' <integer>
<digit> ::= '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
<variable> ::= <string>
<function> ::= <string> '(' <arguments> ')'
<arguments> ::= <sum> | <arguments> ',' <sum>
<string> ::= <string> <letter> | <letter>
<letter> ::= "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" | "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z"
```

## Examples:

```
> -3^2^3
-6561.0
> tanh(pi/5+1/3*-e)
-0.270844926380908
> ((-e^5+log(sin(e+pi)+3))*(4^sin(-2)+4))
-631.652183876061
```

