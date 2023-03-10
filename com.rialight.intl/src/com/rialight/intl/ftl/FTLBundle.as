package com.rialight.intl.ftl
{
    import com.rialight.intl.*;
    import com.rialight.intl.ftl.*;
    import com.rialight.intl.ftl.types.*;
    import com.rialight.intl.ftl.internals.bundle.*;
    import com.rialight.intl.ftl.internals.bundle.ast.*;
    import com.rialight.intl.ftl.internals.bundle.builtins.*;
    import com.rialight.intl.ftl.internals.bundle.resolver.resolveComplexPattern;
    import com.rialight.util.*;

    /**
     * Provides manipulations for FTL of a single locale. You need not
     * construct <code>FTLBundle</code> explicitly.
     */
    public final class FTLBundle
    {
        /**
         * List of locales associated to the <code>FTLBundle</code> object.
         */
        public var locales:Array;

        /**
         * @private
         */
        public var _terms:Map = new Map;
        /**
         * @private
         */
        public var _messages:Map = new Map;
        /**
         * @private
         */
        public var _functions:*;
        /**
         * @private
         */
        public var _useIsolating:Boolean;
        /**
         * @private
         */
        public var _transform:Function;
        /**
         * @private
         */
        public var _intls:Map;

        /**
         * @private
         */
        public function FTLBundle(locales:*, options:* = undefined)
        {
            options ||= {};
            this.locales = locales is Array ? locales : [locales];
            var functions:* = options.functions;
            var useIsolating:Boolean = options.useIsolating === undefined ? true : options.useIsolating;
            var transform:Function = options.transform !== undefined ? options.transform : function(v:String):String { return v; };

            var k:String;
            this._functions =
            {
                NUMBER: NUMBER,
                DATETIME: DATETIME
            };
            for (k in functions)
            {
                this._functions[k] = functions[k];
            }
            this._useIsolating = useIsolating;
            this._transform = transform;
            this._intls = getMemoizerForLocale(locales);;
        }

        /**
         * Sets a customized Fluent function. <code>fn</code>
         * is of the signature <code>function(positional:Array, named:*):*</code>.
         */
        public function setFunction(name:String, fn:Function):void
        {
            this._functions[name] = fn;
        }

        /**
         * Indicates a Fluent transform function.
         * It is a function of the signature <code>function(text:String):String</code>.
         */
        public function get transform():Function
        {
            return this._transform;
        }

        /**
         * Indicates a Fluent transform function.
         */
        public function set transform(fn:Function):void
        {
            this._transform = fn;
        }

        /**
         * Determines if the bundle contains a message identified by <i>id</i>.
         */
        public function hasMessage(id:String):Boolean
        {
            return this._messages.has(id);
        }

        /**
         * Retrieves a message identified by <i>id</i> or
         * returns <code>undefined</code> if none.
         */
        public function getMessage(id:String):*
        {
            return this._messages.get(id);
        }

        /**
         * Adds a Fluent resource to the bundle.
         */
        public function addResource
        (
            res:FTLResource,
            options:* = undefined
        ):Vector.<Error>
        {
            options ||= {};
            var allowOverrides:Boolean = !!options.allowOverrides;

            const errors:Vector.<Error> = new Vector.<Error>;

            for (var i:Number = 0; i < res.body.length; ++i)
            {
                var entry:* = res.body[i];
                if (entry.id.startsWith('-'))
                {
                    // identifiers starting with a dash (-) define terms. terms are private
                    // and cannot be retrieved from FTLBundle.
                    if (allowOverrides === false && this._terms.has(entry.id))
                    {
                        errors.push
                        (
                            new Error(format('Attempt to override an existing term: "$1"', [entry.id]))
                        );
                        continue;
                    }
                    this._terms.set(entry.id, entry as TermNode);
                }
                else
                {
                    if (allowOverrides === false && this._messages.has(entry.id))
                    {
                        errors.push
                        (
                            new Error(format('Attempt to override an existing message: "$1"', [entry.id]))
                        );
                        continue;
                    }
                    this._messages.set(entry.id, entry);
                }
            }

            return errors;
        }

        /**
         * Formats a pattern.
         */
        public function formatPattern
        (
            pattern:*,
            args:* = null,
            errors:Array = null
        ):String
        {
            // resolve a simple pattern without creating a scope. no error handling is
            // required; by definition simple patterns don't have placeables.
            if (typeof pattern === 'string')
            {
                return this._transform(pattern);
            }

            // resolve a complex pattern.
            var scope:FTLScope = new FTLScope(this, errors, args);
            try
            {
                var value:FTLType = resolveComplexPattern(scope, pattern);
                return value.toString(scope);
            }
            catch (err:*)
            {
                if (!!scope.errors && (err is Error))
                {
                    scope.errors.push(err);
                    return (new FTLNone).toString(scope);
                }
                throw err;
            }
        }
    }
}