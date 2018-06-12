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
}

Start
 = _ ep:Expression _ {
     return ep;
   }


Expression
  = ConditionalExpression

ConditionalExpression
  = test:LogicalExpression _
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
  / LogicalExpression

LogicalExpression
  = head:BitwiseExpression tail:(_ ("&&" / "||") _ BitwiseExpression)* {
      return tail.reduce(function(result, element) {
        return {type: 'LogicalExpression', operator: element[1], left: result, right: element[3]};
      }, head);
    }

BitwiseExpression
  = head:RelationalExpression tail:(_ ("&" / "|" / "^") _ RelationalExpression)* {
      return tail.reduce(function(result, element) {
        return {type: 'BinaryExpression', operator: element[1], left: result, right: element[3]};
      }, head);
    }

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
  = CallExpression
  / NewExpression
  / _ op: ("-" / "+" / "!" / "~") _ arg:(UnaryExpression) {
      return {type: 'UnaryExpression', operator: op, argument: arg};
    }

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
  = _ "(" _ args:(ArgumentList) _ ")" {
      return args;
    }
  / _ "(" _ ")" {
      return [];
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
  = _ head: Expression tail:(_ "," _ Expression)* {
      return tail.reduce(function(result, element) {
        result.push(element[3]);
        return result;
      }, [head]);
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
  / "new"

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
  = "[" _ args:ArgumentList _ "]" {
      return {
        type: "ArrayExpression",
        elements: args
      };
    }
  / "[" _ "]" {
      return {
        type: "ArrayExpression",
        elements: []
      };
    }


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


_ "whitespace"
  = [ \t\n\r]*
