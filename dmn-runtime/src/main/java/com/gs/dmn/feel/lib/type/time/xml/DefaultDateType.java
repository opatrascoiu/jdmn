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
package com.gs.dmn.feel.lib.type.time.xml;

import com.gs.dmn.feel.lib.type.BooleanType;
import com.gs.dmn.feel.lib.type.DateType;
import com.gs.dmn.feel.lib.type.logic.DefaultBooleanType;
import com.gs.dmn.runtime.DMNRuntimeException;

import javax.xml.datatype.DatatypeFactory;
import javax.xml.datatype.Duration;
import javax.xml.datatype.XMLGregorianCalendar;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.math.RoundingMode;
import java.util.GregorianCalendar;

import static com.gs.dmn.feel.lib.type.time.xml.BaseDefaultDurationType.*;
import static com.gs.dmn.feel.lib.type.time.xml.DefaultDateTimeType.dateTimeValue;
import static com.gs.dmn.feel.lib.type.time.xml.DefaultDateTimeType.dateToDateTime;
import static com.gs.dmn.feel.lib.type.time.xml.DefaultTimeType.hasTimezone;

public class DefaultDateType extends XMLTimeType implements DateType<XMLGregorianCalendar, Duration> {
    private final DatatypeFactory datatypeFactory;
    private final DefaultXMLCalendarComparator comparator;
    private final BooleanType booleanType;

    public DefaultDateType(DatatypeFactory datatypeFactory) {
        this(datatypeFactory, new DefaultXMLCalendarComparator());
    }

    public DefaultDateType(DatatypeFactory datatypeFactory, DefaultXMLCalendarComparator comparator) {
        this.datatypeFactory = datatypeFactory;
        this.comparator = comparator;
        this.booleanType = new DefaultBooleanType();
    }

    //
    // Date operators
    //

    @Override
    public Boolean dateIs(XMLGregorianCalendar first, XMLGregorianCalendar second) {
        if (first == null || second == null) {
            return first == second;
        }

        return ((FEELXMLGregorianCalendar) first).same(second);
    }

    @Override
    public Boolean dateEqual(XMLGregorianCalendar first, XMLGregorianCalendar second) {
        return this.comparator.equalTo(first, second);
    }

    @Override
    public Boolean dateNotEqual(XMLGregorianCalendar first, XMLGregorianCalendar second) {
        return this.booleanType.booleanNot(dateEqual(first, second));
    }

    @Override
    public Boolean dateLessThan(XMLGregorianCalendar first, XMLGregorianCalendar second) {
        return this.comparator.lessThan(first, second);
    }

    @Override
    public Boolean dateGreaterThan(XMLGregorianCalendar first, XMLGregorianCalendar second) {
        return this.comparator.greaterThan(first, second);
    }

    @Override
    public Boolean dateLessEqualThan(XMLGregorianCalendar first, XMLGregorianCalendar second) {
        return this.comparator.lessEqualThan(first, second);
    }

    @Override
    public Boolean dateGreaterEqualThan(XMLGregorianCalendar first, XMLGregorianCalendar second) {
        return this.comparator.greaterEqualThan(first, second);
    }

    @Override
    public Duration dateSubtract(XMLGregorianCalendar first, XMLGregorianCalendar second) {
        if (first == null || second == null) {
            return null;
        }
        if (isDate(first)) {
            first = dateToDateTime(first);
        }
        if (isDate(second)) {
            second = dateToDateTime(second);
        }
        if (
                hasTimezone(first) && !hasTimezone(second)
                        || !hasTimezone(first) && hasTimezone(second)) {
            return null;
        }

        return this.datatypeFactory.newDuration(this.comparator.getDurationInMilliSeconds(first, second));
    }

    @Override
    public XMLGregorianCalendar dateAddDuration(XMLGregorianCalendar date, Duration duration) {
        if (date == null || duration == null) {
            return null;
        }

        if (isYearMonthDuration(duration)) {
            int signum = duration.getSign();

            // Calculate months and carry
            BigInteger startMonth = BigInteger.valueOf(date.getMonth());
            BigInteger dMonths = (signum < 0) ? BigInteger.valueOf(duration.getMonths()).negate() : BigInteger.valueOf(duration.getMonths());
            BigInteger temp = startMonth.add(dMonths);
            int month = temp.subtract(BigInteger.ONE).mod(TWELVE.toBigInteger()).intValue() + 1;
            BigInteger carry = new BigDecimal(temp.subtract(BigInteger.ONE)).divide(TWELVE, RoundingMode.FLOOR).toBigInteger();

            // Years (may be modified additionally below)
            BigInteger startYear = date.getEonAndYear();
            BigInteger dYears = (signum < 0) ? BigInteger.valueOf(duration.getYears()).negate() : BigInteger.valueOf(duration.getYears());
            BigInteger endYear = startYear.add(dYears).add(carry);
            return FEELXMLGregorianCalendar.makeDate(endYear, month, date.getDay());
        } else if (isDayTimeDuration(duration)) {
            Long value1 = dateTimeValue(date);
            Long value2 = secondsValue(duration);
            GregorianCalendar gc = new GregorianCalendar();
            long millis = (value1 + value2) * 1000;
            gc.setTimeInMillis(millis);
            XMLGregorianCalendar xgc = datatypeFactory.newXMLGregorianCalendar(gc);
            return FEELXMLGregorianCalendar.makeDate(xgc.getEonAndYear(), xgc.getMonth(), xgc.getDay());
        } else {
            throw new DMNRuntimeException(String.format("Cannot add '%s' with '%s'", date, duration));
        }
    }

    @Override
    public XMLGregorianCalendar dateSubtractDuration(XMLGregorianCalendar date, Duration duration) {
        if (date == null || duration == null) {
            return null;
        }

        return dateAddDuration(date, duration.negate());
    }
}
