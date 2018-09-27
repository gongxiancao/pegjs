// Javascript Flow Grammar
// ==========================
//
// Accepts javascript flow and returns statement tree.
// go to https://pegjs.org/online to update and generate parser
// don't support: "in" operator, unicode, string literal escape,
// and stand-alone block.
{
  var TYPES_TO_PROPERTY_NAMES = {
    CallExpression:   "callee",
    MemberExpression: "object",
  };
  function filledArray(count, value) {
    return Array.apply(null, new Array(count))
      .map(function() { return value; });
  }

  function extractOptional(optional, index) {
    return optional ? optional[index] : null;
  }

  function extractList(list, index) {
    return list.map(function(element) { return element[index]; });
  }

  function buildList(head, tail, index) {
    return [head].concat(extractList(tail, index));
  }

  function buildBinaryExpression(head, tail) {
    return tail.reduce(function(result, element) {
      return {
        type: "BinaryExpression",
        operator: element[1],
        left: result,
        right: element[3]
      };
    }, head);
  }

  function buildLogicalExpression(head, tail) {
    return tail.reduce(function(result, element) {
      return {
        type: "LogicalExpression",
        operator: element[1],
        left: result,
        right: element[3]
      };
    }, head);
  }

  function optionalList(value) {
    return value !== null ? value : [];
  }
}

Start
  = __ program:Program __ { return program; }

Program
  = body:SourceElements? {
      return {
        type: "Program",
        body: body !== null ? body: []
      };
    }

SourceElements
  = head:SourceElement tail:(__ SourceElement)* {
      return tail.reduce(function(result, element) {
        result.push(element[1]);
        return result;
      }, [head]);
    }

SourceElement
  = Statement

Statement
  = VariableStatement
  / ExpressionStatement
  / IfStatement
  / IterationStatement
  / ContinueStatement
  / BreakStatement
  / ReturnStatement

Block
  = "{" __ body:(StatementList __)? "}" {
      return {
        type: "BlockStatement",
        body: optionalList(extractOptional(body, 0))
      };
    }

EmptyStatement
  = ";" { return { type: "EmptyStatement" }; }

StatementList
  = head:Statement tail:(__ Statement)* { return buildList(head, tail, 1); }

VariableStatement
  = kind:VarToken __ declarations:VariableDeclarationList EOS {
      return {
        type: "VariableDeclaration",
        declarations: declarations,
        kind: kind
      };
    }

VariableDeclarationList
  = head:VariableDeclaration tail:(__ "," __ VariableDeclaration)* {
      return buildList(head, tail, 3);
    }

VariableDeclaration
  = id:Identifier init:(__ Initialiser)? {
      return {
        type: "VariableDeclarator",
        id: id,
        init: extractOptional(init, 1)
      };
    }

Initialiser
  = "=" !"=" __ expression:AssignmentExpression { return expression; }

IfStatement
  = IfToken __ "(" __ test:Expression __ ")" __
    consequent:Block __
    "else" __
    alternate: (Block / IfStatement)
    {
      return {
        type: "IfStatement",
        test: test,
        consequent: consequent,
        alternate: alternate
      };
    }
  / IfToken __ "(" __ test:Expression __ ")" __
    consequent:Block {
      return {
        type: "IfStatement",
        test: test,
        consequent: consequent,
        alternate: null
      };
    }

IterationStatement
  = ForToken __
    "(" __
    init:(Expression __)? ";" __
    test:(Expression __)? ";" __
    update:(Expression __)?
    ")" __
    body:Block
    {
      return {
        type: "ForStatement",
        init: extractOptional(init, 0),
        test: extractOptional(test, 0),
        update: extractOptional(update, 0),
        body: body
      };
    }
  / ForToken __
    "(" __
    VarToken __ declarations:VariableDeclarationList __ ";" __
    test:(Expression __)? ";" __
    update:(Expression __)?
    ")" __
    body:Block
    {
      return {
        type: "ForStatement",
        init: {
          type: "VariableDeclaration",
          declarations: declarations,
          kind: "var"
        },
        test: extractOptional(test, 0),
        update: extractOptional(update, 0),
        body: body
      };
    }

ContinueStatement
  = "continue" EOS {
      return { type: "ContinueStatement", label: null };
    }
  / "continue" _ label:Identifier EOS {
      return { type: "ContinueStatement", label: label };
    }

BreakStatement
  = "break" EOS {
      return { type: "BreakStatement", label: null };
    }
  / "break" _ label:Identifier EOS {
      return { type: "BreakStatement", label: label };
    }


ReturnStatement
  = "return" EOS {
      return { type: "ReturnStatement", argument: null };
    }
  / "return" _ argument:Expression EOS {
      return { type: "ReturnStatement", argument: argument };
    }

ExpressionStatement
  = expression:Expression EOS {
      return {
        type: "ExpressionStatement",
        expression: expression
      };
    }

Expression
  = head:AssignmentExpression tail:(__ "," __ AssignmentExpression)* {
      return tail.length > 0
        ? { type: "SequenceExpression", expressions: buildList(head, tail, 3) }
        : head;
    }

AssignmentExpression
  = left:LeftHandSideExpression __
    "=" !"=" __
    right:AssignmentExpression
    {
      return {
        type: "AssignmentExpression",
        operator: "=",
        left: left,
        right: right
      };
    }
  / left:LeftHandSideExpression __
    operator:AssignmentOperator __
    right:AssignmentExpression
    {
      return {
        type: "AssignmentExpression",
        operator: operator,
        left: left,
        right: right
      };
    }
  / ConditionalExpression

LeftHandSideExpression
  = CallExpression
  / NewExpression

ConditionalExpression
  = test:LogicalORExpression __
    "?" __ consequent:Expression __
    ":" __ alternate:Expression
    {
      return {
        type: "ConditionalExpression",
        test: test,
        consequent: consequent,
        alternate: alternate
      };
    }
  / LogicalORExpression

LogicalORExpression
  = head:LogicalANDExpression
    tail:(__ LogicalOROperator __ LogicalANDExpression)*
    { return buildLogicalExpression(head, tail); }

LogicalOROperator
  = "||"

LogicalANDExpression
  = head:BitwiseORExpression
    tail:(__ LogicalANDOperator __ BitwiseORExpression)*
    { return buildLogicalExpression(head, tail); }

LogicalANDOperator
  = "&&"

BitwiseORExpression
  = head:BitwiseXORExpression
    tail:(__ BitwiseOROperator __ BitwiseXORExpression)*
    { return buildBinaryExpression(head, tail); }

BitwiseOROperator
  = $("|" ![|=])

BitwiseXORExpression
  = head:BitwiseANDExpression
    tail:(__ BitwiseXOROperator __ BitwiseANDExpression)*
    { return buildBinaryExpression(head, tail); }

BitwiseXOROperator
  = $("^" !"=")

BitwiseANDExpression
  = head:EqualityExpression
    tail:(__ BitwiseANDOperator __ EqualityExpression)*
    { return buildBinaryExpression(head, tail); }

BitwiseANDOperator
  = $("&" ![&=])

EqualityExpression
  = head:RelationalExpression
    tail:(__ EqualityOperator __ RelationalExpression)*
    { return buildBinaryExpression(head, tail); }

EqualityOperator
  = "==="
  / "!=="
  / "=="
  / "!="

RelationalExpression
  = head:ShiftExpression tail:(__ RelationalOperator __ ShiftExpression)*
    { return buildBinaryExpression(head, tail); }

RelationalOperator
  = "<="
  / ">="
  / $("<" !"<")
  / $(">" !">")

ShiftExpression
  = head:AdditiveExpression tail:(__ ShiftOperator __ AdditiveExpression)*
    { return buildBinaryExpression(head, tail); }

ShiftOperator
  = $("<<"  !"=")
  / $(">>>" !"=")
  / $(">>"  !"=")

AdditiveExpression
  = head:MultiplicativeExpression tail:(__ AdditiveOperator __ MultiplicativeExpression)*
    { return buildBinaryExpression(head, tail); }

AdditiveOperator
  = $("+" ![+=])
  / $("-" ![-=])

MultiplicativeExpression
  = head:UnaryExpression tail:(__ MultiplicativeOperator __ UnaryExpression)*
    { return buildBinaryExpression(head, tail); }

MultiplicativeOperator
  = $("*" !"=")
  / $("/" !"=")
  / $("%" !"=")

UnaryExpression
  = PostfixExpression
  / operator:UnaryOperator __ argument:UnaryExpression {
      var type = (operator === "++" || operator === "--")
        ? "UpdateExpression"
        : "UnaryExpression";

      return {
        type: type,
        operator: operator,
        argument: argument,
        prefix: true
      };
    }

UnaryOperator
  = $("+" !"=")
  / $("-" !"=")
  / "~"
  / "!"

PostfixExpression
  = argument:LeftHandSideExpression _ operator:PostfixOperator {
      return {
        type: "UpdateExpression",
        operator: operator,
        argument: argument,
        prefix: false
      };
    }
  / LeftHandSideExpression

PostfixOperator
  = "++"
  / "--"


CallExpression
  = head:(
      callee:MemberExpression __ args:Arguments {
        return { type: "CallExpression", callee: callee, arguments: args };
      }
    )
    tail:(
        __ args:Arguments {
          return { type: "CallExpression", arguments: args };
        }
      / __ index:Index {
          return {
            type: "MemberExpression",
            property: index,
            computed: true
          };
        }
      / __ "." __ property:IdentifierName {
          return {
            type: "MemberExpression",
            property: property,
            computed: false
          };
        }
    )*
    {
      return tail.reduce(function(result, element) {
        element[TYPES_TO_PROPERTY_NAMES[element.type]] = result;
        return element;
      }, head);
    }

NewExpression
  = MemberExpression
  / "new" __ callee:NewExpression {
      return { type: "NewExpression", callee: callee, arguments: [] };
    }

MemberExpression
  = head: (
        PrimaryExpression
      / NewToken __ callee:MemberExpression __ args:Arguments {
          return { type: "NewExpression", callee: callee, arguments: args };
        }
    ) tail:(
        __ "." __ property:IdentifierName {
          return { property: property, computed: false };
        }
      / __ property:Index  {
        return { property: property, computed: true };
      }
    )* {
      return tail.reduce(function(result, element) {
        return {
          type: 'MemberExpression',
          object: result,
          property: element.property,
          computed: element.computed
        };
      }, head);
    }

Arguments
  = "(" __ args:(ArgumentList __)? ")" {
      return optionalList(extractOptional(args, 0));
    }

Index
  = _ "[" __ index:Expression __ "]" {
      return index;
    }
  / _ "[" __ index:ArgumentList __ "]" {
      return {
        type: "SequenceExpression",
        expressions: index
      };
    }

ArgumentList
  = head:AssignmentExpression tail:(__ "," __ AssignmentExpression)* {
      return buildList(head, tail, 3);
    }

PropertyName
  = IdentifierName
  / StringLiteral
  / NumericLiteral

PrimaryExpression
  = Identifier
  / Literal
  / ArrayLiteral
  / ObjectLiteral
  / "(" __ expr:Expression __ ")" {
      return expr;
    }

ReservedWord
  = Keyword
  / FutureReservedWord
  / NullLiteral
  / BooleanLiteral

Keyword
  = BreakToken
  / CaseToken
  / CatchToken
  / ContinueToken
  / DebuggerToken
  / DefaultToken
  / DeleteToken
  / DoToken
  / ElseToken
  / FinallyToken
  / ForToken
  / FunctionToken
  / IfToken
  / InstanceofToken
  / InToken
  / NewToken
  / ReturnToken
  / SwitchToken
  / ThisToken
  / ThrowToken
  / TryToken
  / TypeofToken
  / VarToken
  / VoidToken
  / WhileToken
  / WithToken

FutureReservedWord
  = ClassToken
  / ConstToken
  / EnumToken
  / ExportToken
  / ExtendsToken
  / ImportToken
  / SuperToken

Literal
  = BooleanLiteral
  / NullLiteral
  / StringLiteral
  / NumericLiteral

BooleanLiteral
  = TrueLiteral
  / FalseLiteral


ArrayLiteral
  = "[" __ elision:(Elision __)? "]" {
      return {
        type: "ArrayExpression",
        elements: optionalList(extractOptional(elision, 0))
      };
    }
  / "[" __ elements:ElementList __ "]" {
      return {
        type: "ArrayExpression",
        elements: elements
      };
    }
  / "[" __ elements:ElementList __ "," __ elision:(Elision __)? "]" {
      return {
        type: "ArrayExpression",
        elements: elements.concat(optionalList(extractOptional(elision, 0)))
      };
    }

ElementList
  = head:(
      elision:(Elision __)? element:AssignmentExpression {
        return optionalList(extractOptional(elision, 0)).concat(element);
      }
    )
    tail:(
      __ "," __ elision:(Elision __)? element:AssignmentExpression {
        return optionalList(extractOptional(elision, 0)).concat(element);
      }
    )*
    { return Array.prototype.concat.apply(head, tail); }

Elision
  = "," commas:(__ ",")* { return filledArray(commas.length + 1, null); }

ObjectLiteral
  = "{" __ "}" { return { type: "ObjectExpression", properties: [] }; }
  / "{" __ properties:PropertyNameAndValueList __ "}" {
       return { type: "ObjectExpression", properties: properties };
     }
  / "{" __ properties:PropertyNameAndValueList __ "," __ "}" {
       return { type: "ObjectExpression", properties: properties };
     }

PropertyNameAndValueList
  = head:PropertyAssignment tail:(__ "," __ PropertyAssignment)* {
      return buildList(head, tail, 3);
    }

PropertyAssignment
  = key:PropertyName __ ":" __ value:AssignmentExpression {
      return { type: "Property", key: key, value: value, kind: "init" };
    }

TrueLiteral
  = "true" {
       return {
         type: "Literal",
         value: true
       };
    }

FalseLiteral
  = "false" {
       return {
         type: "Literal",
         value: false
       };
    }

NullLiteral
  = "null" {
    return {
      type: "Literal",
      value: null
    };
  }

Identifier
  = !ReservedWord name:IdentifierName { return name; }

IdentifierName "identifier"
  = head:IdentifierStart tail:IdentifierPart* {
      return {
        type: "Identifier",
        name: head + tail.join("")
      };
    }

IdentifierPart
  = IdentifierStart
  / [0-9]

IdentifierStart
  = [a-zA-Z$_]

StringLiteral "string"
  = [\'] val: [^']* [\'] { return {type: 'Literal', value: val.join('')} }
  / [\"] val: [^"]* [\"] { return {type: 'Literal', value: val.join('')} }

NumericLiteral "number"
  = "0x"i [0-9a-f]i+ { return {type: 'Literal', value: parseInt(text(), 16)}; }
  / ([1-9][0-9]* / [0])"."[0-9]*("e"([+-])[0-9]+)?{
      return {type: 'Literal', value: parseFloat(text())};
    }
  / "."[0-9]+("e"([+-])[0-9]+)?{
      return {type: 'Literal', value: parseFloat(text())};
    }
  / [1-9][0-9]*("e"([+-])[0-9]+) { return {type: 'Literal', value: parseFloat(text(), 10)}; }
  / "0e"([+-])[0-9]+ { return {type: 'Literal', value: parseFloat(text(), 10)}; }
  / [0][0-9]* { return {type: 'Literal', value: parseInt(text(), 8)}; }
  / [1-9][0-9]* { return {type: 'Literal', value: parseInt(text(), 10)}; }

AssignmentOperator
  = "*="
  / "/="
  / "%="
  / "+="
  / "-="
  / "<<="
  / ">>="
  / ">>>="
  / "&="
  / "^="
  / "|="


BreakToken      = "break"      !IdentifierPart
CaseToken       = "case"       !IdentifierPart
CatchToken      = "catch"      !IdentifierPart
ClassToken      = "class"      !IdentifierPart
ConstToken      = "const"      !IdentifierPart
ContinueToken   = "continue"   !IdentifierPart
DebuggerToken   = "debugger"   !IdentifierPart
DefaultToken    = "default"    !IdentifierPart
DeleteToken     = "delete"     !IdentifierPart
DoToken         = "do"         !IdentifierPart
ElseToken       = "else"       !IdentifierPart
EnumToken       = "enum"       !IdentifierPart
ExportToken     = "export"     !IdentifierPart
ExtendsToken    = "extends"    !IdentifierPart
FalseToken      = "false"      !IdentifierPart
FinallyToken    = "finally"    !IdentifierPart
ForToken        = "for"        !IdentifierPart
FunctionToken   = "function"   !IdentifierPart
GetToken        = "get"        !IdentifierPart
IfToken         = "if"         !IdentifierPart
ImportToken     = "import"     !IdentifierPart
InstanceofToken = "instanceof" !IdentifierPart
InToken         = "in"         !IdentifierPart
NewToken        = "new"        !IdentifierPart
NullToken       = "null"       !IdentifierPart
ReturnToken     = "return"     !IdentifierPart
SetToken        = "set"        !IdentifierPart
SuperToken      = "super"      !IdentifierPart
SwitchToken     = "switch"     !IdentifierPart
ThisToken       = "this"       !IdentifierPart
ThrowToken      = "throw"      !IdentifierPart
TrueToken       = "true"       !IdentifierPart
TryToken        = "try"        !IdentifierPart
TypeofToken     = "typeof"     !IdentifierPart
VarToken        = "var"        !IdentifierPart
VoidToken       = "void"       !IdentifierPart
WhileToken      = "while"      !IdentifierPart
WithToken       = "with"       !IdentifierPart

__
  = (WhiteSpace / LineTerminatorSequence)*

_
  = (WhiteSpace)*

WhiteSpace "whitespace"
  = "\t"
  / "\v"
  / "\f"
  / " "

LineTerminatorSequence "end of line"
  = "\n"
  / "\r\n"
  / "\r"

EOS
  = _ ";"
  / _ LineTerminatorSequence
  / _ &"}"
  / _ EOF

EOF
  = !.
