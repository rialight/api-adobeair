package com.rialight.intl.ftl.internals.bundle.resolver
{
    import com.rialight.intl.*;
    import com.rialight.intl.ftl.*;
    import com.rialight.intl.ftl.types.*;
    import com.rialight.intl.ftl.internals.bundle.*;
    import com.rialight.intl.ftl.internals.bundle.ast.*;
    import com.rialight.intl.ftl.internals.bundle.builtins.*;
    import com.rialight.util.*;

    /**
     * @private
     */
    internal function resolveVariableReference
    (
        scope:FTLScope,
        expr:VariableReferenceNode
    ):*
    {
        var name:String = expr.name;
        var arg:*;
        if (scope.params)
        {
            // we're inside a TermReference. it's OK to reference undefined parameters.
            if (scope.params.hasOwnProperty(name))
            {
                arg = scope.params[name];
            }
            else
            {
                return new FTLNone('$' + name);
            }
        }
        else if
        (
            !!scope.args &&
            scope.args.hasOwnProperty(name)
        )
        {
            // we're in the top-level Pattern or inside a MessageReference. missing
            // variables references produce ReferenceErrors.
            arg = scope.args[name];
        }
        else
        {
            scope.reportError(new ReferenceError('Unknown variable: $' + name));
            return new FTLNone('$' + name);
        }

        // return early if the argument already is an instance of FTLType.
        if (arg is FTLType)
        {
            return arg;
        }

        // convert the argument to a Fluent type.
        switch (typeof arg)
        {
            case 'string':
            {
                return arg;
            }
            case 'number':
            {
                return new FTLNumber(arg);
            }
            default:
            {
                if (arg is Date)
                {
                    return new FTLDateTime((arg as Date).getTime());
                }
                scope.reportError(
                    new TypeError(format('Variable type not supported: $$$1, $2', [name, typeof arg]))
                );
                return new FTLNone('$' + name);
            }
        }
    }
}