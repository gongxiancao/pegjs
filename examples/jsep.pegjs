// Javascript Expression Grammar
// ==========================
//
// Accepts javascript expressions and returns expression tree.
// go to https://pegjs.org/online to update and generate parser
// don't support: "in" operator, unicode, string literal escape. 
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

  function optionalList(value) {
    return value !== null ? value : [];
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
}

Start
  = _ ep:Expression _ {
      return ep;
    }


Expression
  = ConditionalExpression

ConditionalExpression
  = test:LogicalORExpression _
    "?" _ consequent:Expression _
    ":" _ alternate:Expression
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
    tail:(_ LogicalOROperator _ LogicalANDExpression)*
    { return buildLogicalExpression(head, tail); }

LogicalOROperator
  = "||"

LogicalANDExpression
  = head:BitwiseORExpression
    tail:(_ LogicalANDOperator _ BitwiseORExpression)*
    { return buildLogicalExpression(head, tail); }

LogicalANDOperator
  = "&&"

BitwiseORExpression
  = head:BitwiseXORExpression
    tail:(_ BitwiseOROperator _ BitwiseXORExpression)*
    { return buildBinaryExpression(head, tail); }

BitwiseOROperator
  = $("|" ![|=])

BitwiseXORExpression
  = head:BitwiseANDExpression
    tail:(_ BitwiseXOROperator _ BitwiseANDExpression)*
    { return buildBinaryExpression(head, tail); }

BitwiseXOROperator
  = $("^" !"=")

BitwiseANDExpression
  = head:EqualityExpression
    tail:(_ BitwiseANDOperator _ EqualityExpression)*
    { return buildBinaryExpression(head, tail); }

BitwiseANDOperator
  = $("&" ![&=])

EqualityExpression
  = head:RelationalExpression
    tail:(_ EqualityOperator _ RelationalExpression)*
    { return buildBinaryExpression(head, tail); }

EqualityOperator
  = "==="
  / "!=="
  / "=="
  / "!="

RelationalExpression
  = head:ShiftExpression tail:(_ RelationalOperator _ ShiftExpression)*
    { return buildBinaryExpression(head, tail); }

RelationalOperator
  = "<="
  / ">="
  / $("<" !"<")
  / $(">" !">")

ShiftExpression
  = head:AdditiveExpression tail:(_ ShiftOperator _ AdditiveExpression)*
    { return buildBinaryExpression(head, tail); }

ShiftOperator
  = $("<<"  !"=")
  / $(">>>" !"=")
  / $(">>"  !"=")

AdditiveExpression
  = head:MultiplicativeExpression tail:(_ AdditiveOperator _ MultiplicativeExpression)*
    { return buildBinaryExpression(head, tail); }

AdditiveOperator
  = $("+" ![+=])
  / $("-" ![-=])

MultiplicativeExpression
  = head:UnaryExpression tail:(_ MultiplicativeOperator _ UnaryExpression)*
    { return buildBinaryExpression(head, tail); }

MultiplicativeOperator
  = $("*" !"=")
  / $("/" !"=")
  / $("%" !"=")

UnaryExpression
  = CallExpression
  / NewExpression
  / operator:UnaryOperator _ argument:UnaryExpression {
      return {
        type: 'UnaryExpression',
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

CallExpression
  = head:(_ calee:MemberExpression _ args:Arguments {
      return {
          type: "CallExpression",
          callee: calee,
          arguments: args
        };
    })
    tail:(_ args:Arguments {
        return {
          type: "CallExpression",
          arguments: args
        };
      }
    / _ property:Property {
        return {
          type: "MemberExpression",
          property: property,
          computed: false
        };
      }
    / _ index:Index {
        return {
          type: "MemberExpression",
          property: index,
          computed: true
        };
      })* {

      return tail.reduce(function(result, element) {
        element[TYPES_TO_PROPERTY_NAMES[element.type]] = result;
        return element;
      }, head);
    }

NewExpression
  = MemberExpression
  / "new" _ callee:NewExpression {
      return { type: "NewExpression", callee: callee, arguments: [] };
    }

MemberExpression
  = head: (
        PrimaryExpression
      / "new" _ callee:MemberExpression _ args:Arguments {
          return { type: "NewExpression", callee: callee, arguments: args };
        }
    ) tail:(
      _ "." _ property:Identifier {
        return { property: property, computed: false };
      }
    / _  property:Index _  {
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
  = _ "(" _ args:(ArgumentList _)? ")" {
      return optionalList(extractOptional(args, 0));
    }

Index
  = _ "[" _ index:Expression _ "]" {
      return index;
    }
  / _ "[" _ index:ArgumentList _ "]" {
      return {
        type: "SequenceExpression",
        expressions: index
      };
    }

ArgumentList
  = head:Expression tail:(_ "," _ Expression)* {
      return buildList(head, tail, 3);
    }

PropertyAssignment
  =  _ key:(Identifier / StringLiteral) _ ":" _ value:Expression {
       return {
         type: "Property",
         key: key,
         value: value,
         kind: "init"
       };
    }

PropertyAssignmentList
  = _ head: PropertyAssignment tail:(_ "," _ PropertyAssignment)* {
      return tail.reduce(function(result, element) {
        result.push(element[3]);
        return result;
      }, [head]);
    }

PrimaryExpression
  = Identifier
  / Literal
  / ObjectLiteral
  / ArrayLiteral
  / "(" _ expr:Expression _ ")" {
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


Property "property"
  = [.] _ property:Identifier {
      return property;
    }

ArrayLiteral
  = "[" _ elision:(Elision _)? "]" {
      return {
        type: "ArrayExpression",
        elements: optionalList(extractOptional(elision, 0))
      };
    }
  / "[" _ elements:ElementList _ "]" {
      return {
        type: "ArrayExpression",
        elements: elements
      };
    }
  / "[" _ elements:ElementList _ "," _ elision:(Elision _)? "]" {
      return {
        type: "ArrayExpression",
        elements: elements.concat(optionalList(extractOptional(elision, 0)))
      };
    }

ElementList
  = head:(
      elision:(Elision _)? element:Expression {
        return optionalList(extractOptional(elision, 0)).concat(element);
      }
    )
    tail:(
      _ "," _ elision:(Elision _)? element:Expression {
        return optionalList(extractOptional(elision, 0)).concat(element);
      }
    )*
    { return Array.prototype.concat.apply(head, tail); }

Elision
  = "," commas:(_ ",")* { return filledArray(commas.length + 1, null); }

ObjectLiteral
  = "{" _ properties:PropertyAssignmentList _ "}" {
      return {
        type: "ObjectExpression",
        properties: properties
      };
    }
  / "{" _ "}" {
      return {
        type: "ObjectExpression",
        properties: []
      };
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

_
  = (WhiteSpace / LineTerminatorSequence)*

WhiteSpace "whitespace"
  = "\t"
  / "\v"
  / "\f"
  / " "

LineTerminatorSequence "end of line"
  = "\n"
  / "\r\n"
  / "\r"

