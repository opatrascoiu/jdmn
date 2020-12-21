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
package com.gs.dmn.maven;

import org.junit.Test;

import static org.junit.Assert.assertTrue;

public abstract class AbstractDMNMojoTest<NUMBER, DATE, TIME, DATE_TIME, DURATION, TEST> extends AbstractMojoTest {
    protected abstract AbstractDMNMojo<NUMBER, DATE, TIME, DATE_TIME, DURATION, TEST> getMojo();

    @Test(expected = IllegalArgumentException.class)
    public void testExecuteWhenMissingInput() throws Exception {
        getMojo().inputParameters = makeParams();
        getMojo().execute();
        assertTrue(true);
    }
}