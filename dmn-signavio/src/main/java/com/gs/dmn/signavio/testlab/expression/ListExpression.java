/*
 * Copyright 2016 Goldman Sachs.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
 *
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 */
package com.gs.dmn.signavio.testlab.expression;

import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import com.gs.dmn.signavio.testlab.TestLabVisitor;

import java.util.List;
import java.util.stream.Collectors;

@JsonPropertyOrder({ "type", "value" })
public class ListExpression extends Expression {
    private List<Expression> value;

    public List<Expression> getElements() {
        return value;
    }

    @Override
    public String toFEELExpression() {
        if (value == null) {
            return "null";
        } else {
            String elements = value.stream().map(Expression::toFEELExpression).collect(Collectors.joining(", "));
            return String.format("[%s]", elements);
        }
    }

    @Override
    public String toString() {
        return String.format("%s(%s)", this.getClass().getSimpleName(), value);
    }

    @Override
    public Object accept(TestLabVisitor visitor, Object... params) {
        return visitor.visit(this, params);
    }
}