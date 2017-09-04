//
//  main.swift
//  ExpressionSolver
//
//  Created by Palle Klewitz on 30.08.2017
//  Copyright (c) 2017 Palle Klewitz
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Covfefe
import Foundation

let grammarString = """
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
"""
let grammar = try Grammar(bnfString: grammarString, start: "sum")

let parser = EarleyParser(grammar: grammar)
let tokenizer = DefaultTokenizer(grammar: grammar)

struct EvaluationError: Error {
	enum Reason {
		case unknownVariable
		case unknownFunction
		case argumentMismatch
	}
	
	let range: Range<String.Index>
	let reason: Reason
}

func solve(expression: String) throws -> Double {
	let ast = try parser.syntaxTree(for: tokenizer.tokenize(expression))
	func _solve(tree: SyntaxTree<NonTerminal, Range<String.Index>>) throws -> Double {
		switch tree {
		case .node(key: let key, children: let children):
			switch key.name {
			case "sum" where children.count == 1:
				return try _solve(tree: children[0])
				
			case "sum" where children.count == 3:
				let `operator` = String(expression[children[1].leafs.first!])
				let lhs = try _solve(tree: children[0])
				let rhs = try _solve(tree: children[2])
				switch `operator` {
				case "+": return lhs + rhs
				case "-": return lhs - rhs
				default: fatalError()
				}
				
			case "product" where children.count == 1:
				return try _solve(tree: children[0])
				
			case "product" where children.count == 3:
				let `operator` = String(expression[children[1].leafs.first!])
				let lhs = try _solve(tree: children[0])
				let rhs = try _solve(tree: children[2])
				switch `operator` {
				case "*": return lhs * rhs
				case "/": return lhs / rhs
				default: fatalError()
				}
				
			case "brackets":
				return try _solve(tree: children[1])
			
			case "atom":
				return try _solve(tree: children[0])
				
			case "real", "integer":
				return Double(expression[tree.leafs.first!.lowerBound ..< tree.leafs.last!.upperBound])!
				
			case "power" where children.count == 3:
				let base = try _solve(tree: children.first!)
				let exponent = try _solve(tree: children.last!)
				return pow(base, exponent)
				
			case "power" where children.count == 2:
				let `operator` = String(expression[children.first!.leafs.first!])
				let operand = try _solve(tree: children.last!)
				switch `operator` {
				case "+":
					return operand
					
				case "-":
					return -operand
					
				default:
					fatalError()
				}
				
			case "power" where children.count == 1:
				return try _solve(tree: children.first!)
				
			case "variable":
				let varName = String(expression[tree.leafs.first!.lowerBound..<tree.leafs.last!.upperBound])
				let variables = [
					"e": M_E,
					"pi": Double.pi
				]
				if let value = variables[varName] {
					return value
				} else {
					throw EvaluationError(range: tree.leafs.first!.lowerBound..<tree.leafs.first!.upperBound, reason: .unknownVariable)
				}
				
			case "function":
				let arguments = try collectArguments(tree: tree.children![2])
				let functionName = String(expression[tree.children!.first!.leafs.first!.lowerBound..<tree.children!.first!.leafs.last!.upperBound])
				let singleArgumentFunctions: [String: (Double) -> Double] = [
					"sin": sin,
					"cos": cos,
					"tan": tan,
					"log": log,
					"exp": exp,
					"sqrt": sqrt,
					"asin": asin,
					"acos": acos,
					"atan": atan,
					"sinh": sinh,
					"cosh": cosh,
					"tanh": tanh,
					"asinh": asinh,
					"acosh": acosh,
					"atanh": atanh
				]
				let twoArgumentFunctions: [String: (Double, Double) -> Double] = [
					"pow": pow
				]
				if arguments.count == 1 {
					guard let function = singleArgumentFunctions[functionName] else {
						throw EvaluationError(range: tree.children!.first!.leafs.first!.lowerBound..<tree.children!.first!.leafs.last!.upperBound, reason: .unknownFunction)
					}
					return function(arguments[0])
				} else if arguments.count == 2 {
					guard let function = twoArgumentFunctions[functionName] else {
						throw EvaluationError(range: tree.children!.first!.leafs.first!.lowerBound..<tree.children!.first!.leafs.last!.upperBound, reason: .unknownFunction)
					}
					return function(arguments[0], arguments[1])
				} else {
					throw EvaluationError(range: tree.leafs.first!.lowerBound..<tree.leafs.last!.upperBound, reason: .argumentMismatch)
				}
				
			default:
				fatalError()
			}
		default: fatalError()
		}
	}
	
	func collectArguments(tree: SyntaxTree<NonTerminal, Range<String.Index>>) throws -> [Double] {
		switch tree.root!.name {
		case "sum":
			return try [_solve(tree: tree)]
			
		case "arguments" where tree.children!.count == 1:
			return try [_solve(tree: tree.children!.first!)]
			
		case "arguments":
			return try collectArguments(tree: tree.children!.first!) + [_solve(tree: tree.children!.last!)]
			
		default:
			fatalError()
		}
	}
	
	return try _solve(tree: ast)
}

print("> ", terminator: "")
fflush(stdout)

while let line = readLine() {
//	let tree = try parser.syntaxTree(for: tokenizer.tokenize(line))
//	print(tree.mapLeafs{String(line[$0])})
	do {
		try print(solve(expression: line))
	} catch let error as SyntaxError {
		let nsrange = NSRange(error.range, in: line)
		print("Error: \(error.reason) '\(line[error.range])' at \(nsrange.lowerBound)...\(nsrange.upperBound)")
	} catch let error as EvaluationError {
		let nsrange = NSRange(error.range, in: line)
		print("Error: \(error.reason) '\(line[error.range])' at \(nsrange.lowerBound)...\(nsrange.upperBound)")
	} catch {
		print("Error: unknown")
	}
	print("> ", terminator: "")
	fflush(stdout)
}
