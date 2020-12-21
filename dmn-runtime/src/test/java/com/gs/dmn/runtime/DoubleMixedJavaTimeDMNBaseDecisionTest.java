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
package com.gs.dmn.runtime;

import com.gs.dmn.runtime.annotation.DRGElement;
import com.gs.dmn.runtime.annotation.Rule;
import org.junit.Test;

import static org.junit.Assert.assertNull;

public class DoubleMixedJavaTimeDMNBaseDecisionTest {
    private final DoubleMixedJavaTimeDMNBaseDecision baseDecision = new DoubleMixedJavaTimeDMNBaseDecision();

    @Test
    public void testGetDRGElementAnnotation() {
        DRGElement drgElementAnnotation = this.baseDecision.getDRGElementAnnotation();
        assertNull(drgElementAnnotation);
    }

    @Test
    public void testGetRuleAnnotation() {
        Rule ruleAnnotation = this.baseDecision.getRuleAnnotation(0);
        assertNull(ruleAnnotation);
    }

}