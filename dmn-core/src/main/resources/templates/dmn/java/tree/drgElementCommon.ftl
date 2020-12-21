<#--
    Copyright 2016 Goldman Sachs.

    Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.

    You may obtain a copy of the License at
        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations under the License.
-->
<#--
    Apply method body
-->
<#macro applyMethodBody drgElement>
        try {
        <@startDRGElement drgElement/>

        <#if modelRepository.isDecisionTableExpression(drgElement)>
            <@expressionApplyBody drgElement />
        <#elseif modelRepository.isLiteralExpression(drgElement)>
            <@expressionApplyBody drgElement/>
        <#elseif modelRepository.isInvocationExpression(drgElement)>
            <@expressionApplyBody drgElement/>
        <#elseif modelRepository.isContextExpression(drgElement)>
            <@expressionApplyBody drgElement/>
        <#elseif modelRepository.isRelationExpression(drgElement)>
            <@expressionApplyBody drgElement/>
        <#else >
            logError("${modelRepository.expression(drgElement).class.simpleName} is not implemented yet");
            return null;
        </#if>
        } catch (Exception e) {
            logError("Exception caught in '${modelRepository.name(drgElement)}' evaluation", e);
            return null;
        }
</#macro>

<#---
    Evaluate method
-->
<#macro evaluateExpressionMethod drgElement>
    <#if modelRepository.isDecisionTableExpression(drgElement)>

        <@addEvaluateDecisionTableMethod drgElement/>
        <@addRuleMethods drgElement/>
        <@addConversionMethod drgElement/>
    <#elseif modelRepository.isLiteralExpression(drgElement)>

        <@addEvaluateExpressionMethod drgElement/>
    <#elseif modelRepository.isInvocationExpression(drgElement)>

        <@addEvaluateExpressionMethod drgElement/>
    <#elseif modelRepository.isContextExpression(drgElement)>

        <@addEvaluateExpressionMethod drgElement/>
    <#elseif modelRepository.isRelationExpression(drgElement)>

        <@addEvaluateExpressionMethod drgElement/>
    </#if>
</#macro>

<#--
    Sub decisions fields
-->
<#macro addSubDecisionFields drgElement>
    <#list modelRepository.directSubDecisions(drgElement)>

        <#items as subDecision>
    private final ${transformer.qualifiedName(subDecision)} ${transformer.drgElementReferenceVariableName(subDecision)};
        </#items>
    </#list>
</#macro>

<#macro setSubDecisionFields drgElement>
    <#list modelRepository.directSubDecisions(drgElement)>
        <#items as subDecision>
        this.${transformer.drgElementReferenceVariableName(subDecision)} = ${transformer.drgElementReferenceVariableName(subDecision)};
        </#items>
    </#list>
</#macro>

<#--
    Decision table
-->
<#macro addEvaluateDecisionTableMethod drgElement>
    protected ${transformer.drgElementOutputType(drgElement)} evaluate(${transformer.drgElementEvaluateSignature(drgElement)}) {
    <#assign expression = modelRepository.expression(drgElement)>
        <@collectRuleResults drgElement expression />

        // Return results based on hit policy
        ${transformer.drgElementOutputType(drgElement)} output_;
    <#if modelRepository.isSingleHit(expression.hitPolicy)>
        if (ruleOutputList_.noMatchedRules()) {
            // Default value
            output_ = ${transformer.defaultValue(drgElement)};
        } else {
            ${transformer.abstractRuleOutputClassName()} ruleOutput_ = ruleOutputList_.applySingle(${transformer.hitPolicyAnnotationClassName()}.${transformer.hitPolicy(drgElement)});
            <#if modelRepository.isCompoundDecisionTable(drgElement)>
            output_ = toDecisionOutput((${transformer.ruleOutputClassName(drgElement)})ruleOutput_);
            <#else>
            output_ = ruleOutput_ == null ? null : ((${transformer.ruleOutputClassName(drgElement)})ruleOutput_).${transformer.getter(drgElement, expression.output[0])};
            </#if>
        }

        return output_;
    <#elseif modelRepository.isMultipleHit(expression.hitPolicy)>
        if (ruleOutputList_.noMatchedRules()) {
            // Default value
            output_ = ${transformer.defaultValue(drgElement)};
        } else {
            List<? extends ${transformer.abstractRuleOutputClassName()}> ruleOutputs_ = ruleOutputList_.applyMultiple(${transformer.hitPolicyAnnotationClassName()}.${transformer.hitPolicy(drgElement)});
        <#if modelRepository.isCompoundDecisionTable(drgElement)>
            <#if modelRepository.hasAggregator(expression)>
            output_ = null;
            <#else>
            output_ = ruleOutputs_.stream().map(o -> toDecisionOutput(((${transformer.ruleOutputClassName(drgElement)})o))).collect(Collectors.toList());
            </#if>
        <#else >
            <#if modelRepository.hasAggregator(expression)>
            output_ = ${transformer.aggregator(drgElement, expression, expression.output[0], "ruleOutputs_")};
            <#else>
            output_ = ruleOutputs_.stream().map(o -> ((${transformer.ruleOutputClassName(drgElement)})o).${transformer.getter(drgElement, expression.output[0])}).collect(Collectors.toList());
            </#if>
        </#if>
        }

        return output_;
    <#else>
        logError("Unknown hit policy '" + ${expression.hitPolicy} + "'"));
        return output_;
    </#if>
    }

</#macro>

<#macro addRuleMethods drgElement>
    <#assign expression = modelRepository.expression(drgElement)>
    <#list expression.rule>
        <#items as rule>
    @${transformer.ruleAnnotationClassName()}(index = ${rule_index}, annotation = "${transformer.annotationEscapedText(rule)}")
    public ${transformer.abstractRuleOutputClassName()} rule${rule_index}(${transformer.drgElementSignatureExtra(transformer.ruleSignature(drgElement))}) {
        // Rule metadata
        ${transformer.drgRuleMetadataClassName()} ${transformer.drgRuleMetadataFieldName()} = new ${transformer.drgRuleMetadataClassName()}(${rule_index}, "${transformer.annotationEscapedText(rule)}");

        <@startRule drgElement rule_index />

        // Apply rule
        ${transformer.ruleOutputClassName(drgElement)} output_ = new ${transformer.ruleOutputClassName(drgElement)}(false);
        if (${transformer.condition(drgElement, rule)}) {
            <@matchRule drgElement rule_index />

            // Compute output
            output_.setMatched(true);
            <#list expression.output as output>
            output_.${transformer.setter(drgElement, output)}(${transformer.outputEntryToNative(drgElement, rule.outputEntry[output_index], output_index)});
                <#if modelRepository.isOutputOrderHit(expression.hitPolicy) && transformer.priority(drgElement, rule.outputEntry[output_index], output_index)?exists>
            output_.${transformer.prioritySetter(drgElement, output)}(${transformer.priority(drgElement, rule.outputEntry[output_index], output_index)});
                </#if>
            </#list>

            <@addAnnotation drgElement rule rule_index />
        }

        <@endRule drgElement rule_index "output_" />

        return output_;
    }

        </#items>
    </#list>
</#macro>

<#macro collectRuleResults drgElement expression>
        // Apply rules and collect results
        ${transformer.ruleOutputListClassName()} ruleOutputList_ = new ${transformer.ruleOutputListClassName()}();
    <#assign expression = modelRepository.expression(drgElement)>
    <#list expression.rule>
        <#items as rule>
        <#if modelRepository.isFirstSingleHit(expression.hitPolicy) && modelRepository.atLeastTwoRules(expression)>
        <#if rule?is_first>
        ${transformer.abstractRuleOutputClassName()} tempRuleOutput_ = rule${rule_index}(${transformer.drgElementArgumentListExtra(transformer.ruleArgumentList(drgElement))});
        ruleOutputList_.add(tempRuleOutput_);
        boolean matched_ = tempRuleOutput_.isMatched();
        <#else >
        if (!matched_) {
            tempRuleOutput_ = rule${rule_index}(${transformer.drgElementArgumentListExtra(transformer.ruleArgumentList(drgElement))});
            ruleOutputList_.add(tempRuleOutput_);
            matched_ = tempRuleOutput_.isMatched();
        }
        </#if>
        <#else >
        ruleOutputList_.add(rule${rule_index}(${transformer.drgElementArgumentListExtra(transformer.ruleArgumentList(drgElement))}));
        </#if>
        </#items>
    </#list>
</#macro>

<#macro addConversionMethod drgElement>
    <#if modelRepository.isCompoundDecisionTable(drgElement)>
    public ${transformer.drgElementOutputClassName(drgElement)} toDecisionOutput(${transformer.ruleOutputClassName(drgElement)} ruleOutput_) {
        <#assign simpleClassName = transformer.itemDefinitionNativeClassName(transformer.drgElementOutputClassName(drgElement))>
        ${simpleClassName} result_ = ${transformer.defaultConstructor(simpleClassName)};
        <#assign expression = modelRepository.expression(drgElement)>
        <#list expression.output as output>
        result_.${transformer.setter(drgElement, output)}(ruleOutput_ == null ? null : ruleOutput_.${transformer.getter(drgElement, output)});
        </#list>
        return result_;
    }
    </#if>
</#macro>

<#--
    Expression
-->
<#macro expressionApplyBody drgElement>
        <#if transformer.isCached(modelRepository.name(drgElement))>
            if (cache_.contains("${modelRepository.name(drgElement)}")) {
                // Retrieve value from cache
                ${transformer.drgElementOutputType(drgElement)} output_ = (${transformer.drgElementOutputType(drgElement)})cache_.lookup("${modelRepository.name(drgElement)}");

                <@endDRGElementAndReturnIndent "    " drgElement "output_" />
            } else {
                <@applySubDecisionsIndent "    " drgElement/>
                // ${transformer.evaluateElementCommentText(drgElement)}
                ${transformer.drgElementOutputType(drgElement)} output_ = evaluate(${transformer.drgElementEvaluateArgumentList(drgElement)});
                cache_.bind("${modelRepository.name(drgElement)}", output_);

                <@endDRGElementAndReturnIndent "    " drgElement "output_" />
            }
        <#else>
            <@applySubDecisions drgElement/>
            // ${transformer.evaluateElementCommentText(drgElement)}
            ${transformer.drgElementOutputType(drgElement)} output_ = evaluate(${transformer.drgElementEvaluateArgumentList(drgElement)});

            <@endDRGElementAndReturn drgElement "output_" />
        </#if>
</#macro>

<#macro addEvaluateExpressionMethod drgElement>
    protected ${transformer.drgElementOutputType(drgElement)} evaluate(${transformer.drgElementEvaluateSignature(drgElement)}) {
    <#assign stm = transformer.expressionToNative(drgElement)>
    <#if transformer.isCompoundStatement(stm)>
        <#list stm.statements as child>
        ${child.expression}
        </#list>
    <#else>
        return ${stm.expression};
    </#if>
    }
</#macro>

<#--
    Apply direct sub-decisions
-->
<#macro applySubDecisions drgElement>
    <@applySubDecisionsIndent "" drgElement/>
</#macro>

<#macro applySubDecisionsIndent extraIndent drgElement>
    <#list modelRepository.directSubDecisions(drgElement)>
            ${extraIndent}// Apply child decisions
        <#items as subDecision>
            <#if transformer.isLazyEvaluated(subDecision)>
            ${extraIndent}${transformer.lazyEvalClassName()}<${transformer.drgElementOutputType(subDecision)}> ${transformer.drgElementReferenceVariableName(subDecision)} = new ${transformer.lazyEvalClassName()}<>(() -> this.${transformer.drgElementReferenceVariableName(subDecision)}.apply(${transformer.drgElementArgumentListExtraCache(subDecision)}));
            <#else>
            ${extraIndent}${transformer.drgElementOutputType(subDecision)} ${transformer.drgElementReferenceVariableName(subDecision)} = this.${transformer.drgElementReferenceVariableName(subDecision)}.apply(${transformer.drgElementArgumentListExtraCache(subDecision)});
            </#if>
        </#items>

    </#list>
</#macro>

<#--
    Events
-->
<#macro startDRGElement drgElement>
            // ${transformer.startElementCommentText(drgElement)}
            long ${transformer.namedElementVariableName(drgElement)}StartTime_ = System.currentTimeMillis();
            ${transformer.argumentsClassName()} ${transformer.argumentsVariableName(drgElement)} = ${transformer.defaultConstructor(transformer.argumentsClassName())};
            <#assign elementNames = transformer.drgElementArgumentDisplayNameList(drgElement)/>
            <#list transformer.drgElementArgumentNameList(drgElement)>
            <#items as arg>
            ${transformer.argumentsVariableName(drgElement)}.put("${transformer.escapeInString(elementNames[arg?index])}", ${arg});
            </#items>
            </#list>
            ${transformer.eventListenerVariableName()}.startDRGElement(<@drgElementAnnotation drgElement/>, ${transformer.argumentsVariableName(drgElement)});
</#macro>

<#macro endDRGElement drgElement output>
    <@endDRGElementIndent "" drgElement output/>
</#macro>

<#macro endDRGElementIndent extraIndent drgElement output>
            ${extraIndent}// ${transformer.endElementCommentText(drgElement)}
            ${extraIndent}${transformer.eventListenerVariableName()}.endDRGElement(<@drgElementAnnotation drgElement/>, ${transformer.argumentsVariableName(drgElement)}, ${output}, (System.currentTimeMillis() - ${transformer.namedElementVariableName(drgElement)}StartTime_));
</#macro>

<#macro endDRGElementAndReturn drgElement output>
            <@endDRGElementAndReturnIndent "" drgElement output/>
</#macro>

<#macro endDRGElementAndReturnIndent extraIndent drgElement output>
            <@endDRGElementIndent extraIndent drgElement output/>

            ${extraIndent}return ${output};
</#macro>

<#macro startRule drgElement rule_index>
        // Rule start
        ${transformer.eventListenerVariableName()}.startRule(<@drgElementAnnotation drgElement/>, <@ruleAnnotation/>);
</#macro>

<#macro matchRule drgElement rule_index>
            // Rule match
            ${transformer.eventListenerVariableName()}.matchRule(<@drgElementAnnotation drgElement/>, <@ruleAnnotation/>);
</#macro>

<#macro endRule drgElement rule_index output>
        // Rule end
        ${transformer.eventListenerVariableName()}.endRule(<@drgElementAnnotation drgElement/>, <@ruleAnnotation/>, ${output});
</#macro>

<#macro drgElementAnnotation drgElement>${transformer.drgElementMetadataFieldName()}</#macro>

<#macro ruleAnnotation>${transformer.drgRuleMetadataFieldName()}</#macro>

<#--
    Annotations
-->
<#macro addAnnotation drgElement rule rule_index>
            // Add annotation
            ${transformer.annotationSetVariableName()}.addAnnotation("${drgElement.name}", ${rule_index}, ${transformer.annotation(drgElement, rule)});
</#macro>
