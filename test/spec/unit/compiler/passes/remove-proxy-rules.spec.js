"use strict";

const chai = require( "chai" );
const helpers = require( "./helpers" );
const pass = require( "pegjs-dev" ).compiler.passes.transform.removeProxyRules;

chai.use( helpers );

const expect = chai.expect;

describe( "compiler pass |removeProxyRules|", function () {

    describe( "when a proxy rule isn't listed in |allowedStartRules|", function () {

        it( "updates references and removes it", function () {

            expect( pass ).to.changeAST(
                [
                    "start = proxy",
                    "proxy = proxied",
                    "proxied = 'a'"
                ].join( "\n" ),
                {
                    rules: [
                        {
                            name: "start",
                            expression: { type: "rule_ref", name: "proxied" }
                        },
                        { name: "proxied" }
                    ]
                },
                { allowedStartRules: [ "start" ] }
            );

        } );

    } );

    describe( "when a proxy rule is listed in |allowedStartRules|", function () {

        it( "updates references but doesn't remove it", function () {

            expect( pass ).to.changeAST(
                [
                    "start = proxy",
                    "proxy = proxied",
                    "proxied = 'a'"
                ].join( "\n" ),
                {
                    rules: [
                        {
                            name: "start",
                            expression: { type: "rule_ref", name: "proxied" }
                        },
                        {
                            name: "proxy",
                            expression: { type: "rule_ref", name: "proxied" }
                        },
                        { name: "proxied" }
                    ]
                },
                { allowedStartRules: [ "start", "proxy" ] }
            );

        } );

    } );

} );
