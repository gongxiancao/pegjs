// Javascript Flow Grammar
// ==========================
//
// Accepts javascript flow and returns statement tree.
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
  = _ program:Program _ { return program; }

Program
  = body:SourceElements? {
      return {
        type: "Program",
        body: body !== null ? body: []
      };
    }

SourceElements
  = head:SourceElement tail:(_ SourceElement)* {
      return tail.reduce(function(result, element) {
        result.push(element[1]);
        return result;
      }, [head]);
    }

SourceElement
  = st: Statement _";"?_ {
      return st;
    }

Statement
  = Block
  / VariableStatement
  / ExpressionStatement
  / IfStatement
  / IterationStatement
  / ContinueStatement
  / BreakStatement
  / ReturnStatement

Block
  = "{" _ body:(StatementList _)? "}" {
      return {
        type: "BlockStatement",
        body: optionalList(extractOptional(body, 0))
      };
    }

EmptyStatement
  = ";" { return { type: "EmptyStatement" }; }

StatementList
  = head:Statement tail:(_ Statement)* { return buildList(head, tail, 1); }

VariableStatement
  = kind:("let" / "var") _ declarations:VariableDeclarationList EOS {
      return {
        type: "VariableDeclaration",
        declarations: declarations,
        kind: kind
      };
    }

VariableDeclarationList
  = head:VariableDeclaration tail:(_ "," _ VariableDeclaration)* {
      return buildList(head, tail, 3);
    }

VariableDeclaration
  = id:Identifier init:(_ Initialiser)? {
      return {
        type: "VariableDeclarator",
        id: id,
        init: extractOptional(init, 1)
      };
    }

Initialiser
  = "=" !"=" _ expression:AssignmentExpression { return expression; }

IfStatement
  = "if" _ "(" _ test:Expression _ ")" _
    consequent:Statement _
    "else" _
    alternate:Statement
    {
      return {
        type: "IfStatement",
        test: test,
        consequent: consequent,
        alternate: alternate
      };
    }
  / "if" _ "(" _ test:Expression _ ")" _
    consequent:Statement {
      return {
        type: "IfStatement",
        test: test,
        consequent: consequent,
        alternate: null
      };
    }

IterationStatement
  = "for" _
    "(" _
    init:(Expression _)? ";" _
    test:(Expression _)? ";" _
    update:(Expression _)?
    ")" _
    body:Statement
    {
      return {
        type: "ForStatement",
        init: extractOptional(init, 0),
        test: extractOptional(test, 0),
        update: extractOptional(update, 0),
        body: body
      };
    }
  / "for" _
    "(" _
    kind:("let" / "var") _ declarations:VariableDeclarationList _ ";" _
    test:(Expression _)? ";" _
    update:(Expression _)?
    ")" _
    body:Statement
    {
      return {
        type: "ForStatement",
        init: {
          type: "VariableDeclaration",
          declarations: declarations,
          kind: kind
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
  = _ ep:Expression EOS {
     return ep;
    }

Expression
  = head:AssignmentExpression tail:(_ "," _ AssignmentExpression)* {
      return tail.length > 0
        ? { type: "SequenceExpression", expressions: buildList(head, tail, 3) }
        : head;
    }

AssignmentExpression
  = left:LeftHandSideExpression _
    "=" !"=" _
    right:AssignmentExpression
    {
      return {
        type: "AssignmentExpression",
        operator: "=",
        left: left,
        right: right
      };
    }
  / left:LeftHandSideExpression _
    operator:AssignmentOperator _
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
  = head:ShiftExpression tail:(_ (">=" / "<=" / ">" / "<" / "===" / "!==") _ ShiftExpression)* {
      return tail.reduce(function(result, element) {
        return {type: 'BinaryExpression', operator: element[1], left: result, right: element[3]};
      }, head);
    }

ShiftExpression
  = head:AdditiveExpression tail:(_ ("<<" / ">>>" / ">>") _ AdditiveExpression)* {
      return tail.reduce(function(result, element) {
        return {type: 'BinaryExpression', operator: element[1], left: result, right: element[3]};
      }, head);
    }

AdditiveExpression
  = head:MultiplicativeExpression tail:(_ ("+" / "-") _ MultiplicativeExpression)* {
      return tail.reduce(function(result, element) {
        return {type: 'BinaryExpression', operator: element[1], left: result, right: element[3]};
      }, head);
    }

MultiplicativeExpression
  = head:UnaryExpression tail:(_ ("*" / "/" / "%") _ UnaryExpression)* {
      return tail.reduce(function(result, element) {
        return {type: 'BinaryExpression', operator: element[1], left: result, right: element[3]};
      }, head);
    }

UnaryExpression
  = PostfixExpression
  / _ op: ("++" / "--") _ arg:(UnaryExpression) {
     return {type: 'UpdateExpression', operator: op, argument: arg, prefix: true};
    }
  / _ op: ("-" / "+" / "!" / "~") _ arg:(UnaryExpression) {
      return {type: 'UnaryExpression', operator: op, argument: arg};
    }

PostfixExpression
  = arg:LeftHandSideExpression _ op:("++" / "--") {
     return {type: 'UpdateExpression', operator: op, argument: arg, prefix: false};
    }
  / LeftHandSideExpression

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
  = head:AssignmentExpression tail:(_ "," _ AssignmentExpression)* {
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
  = NullLiteral
  / BooleanLiteral
  / "break"
  / "case"
  / "catch"
  / "class"
  / "const"
  / "continue"
  / "debugger"
  / "default"
  / "delete"
  / "do"
  / "else"
  / "enum"
  / "export"
  / "extends"
  / "false"
  / "finally"
  / "for"
  / "function"
  / "get"
  / "if"
  / "import"
  / "instanceof"
  / "in"
  / "new"
  / "null"
  / "return"
  / "set"
  / "super"
  / "switch"
  / "this"
  / "throw"
  / "true"
  / "try"
  / "typeof"
  / "var"
  / "void"
  / "while"
  / "with"

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
      elision:(Elision _)? element:AssignmentExpression {
        return optionalList(extractOptional(elision, 0)).concat(element);
      }
    )
    tail:(
      _ "," _ elision:(Elision _)? element:AssignmentExpression {
        return optionalList(extractOptional(elision, 0)).concat(element);
      }
    )*
    { return Array.prototype.concat.apply(head, tail); }

Elision
  = "," commas:(_ ",")* { return filledArray(commas.length + 1, undefined); }

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

Identifier "identifier"
  = !ReservedWord ([a-zA-Z$_][0-9a-zA-Z$_]*) {
      return {type: "Identifier", name: text()};
    }

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

EOS
  = _ ";"
  / _ &"}"
  / _ EOF

EOF
  = !.
