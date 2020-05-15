<#include "drgElementCommon.ftl">
<#if javaPackageName?has_content>
package ${javaPackageName}
</#if>

import java.util.*
import java.util.stream.Collectors

@javax.annotation.Generated(value = ["bkm.ftl", "${modelRepository.name(drgElement)}"])
@${transformer.drgElementAnnotationClassName()}(
    namespace = "${javaPackageName}",
    name = "${modelRepository.name(drgElement)}",
    label = "${modelRepository.label(drgElement)}",
    elementKind = ${transformer.elementKindAnnotationClassName()}.${transformer.elementKind(drgElement)},
    expressionKind = ${transformer.expressionKindAnnotationClassName()}.${transformer.expressionKind(drgElement)},
    hitPolicy = ${transformer.hitPolicyAnnotationClassName()}.${transformer.hitPolicy(drgElement)},
    rulesCount = ${modelRepository.rulesCount(drgElement)}
)
class ${javaClassName} : ${decisionBaseClass} {
    private constructor() {}

    private fun apply(${transformer.drgElementSignatureExtra(drgElement)}): ${transformer.drgElementOutputType(drgElement)} {
        <@applyMethodBody drgElement />
    }
    <@evaluateExpressionMethod drgElement />

    companion object {
        val ${transformer.drgElementMetadataFieldName()} = ${transformer.drgElementMetadataClassName()}(
            "${javaPackageName}",
            "${modelRepository.name(drgElement)}",
            "${modelRepository.label(drgElement)}",
            ${transformer.elementKindAnnotationClassName()}.${transformer.elementKind(drgElement)},
            ${transformer.expressionKindAnnotationClassName()}.${transformer.expressionKind(drgElement)},
            ${transformer.hitPolicyAnnotationClassName()}.${transformer.hitPolicy(drgElement)},
            ${modelRepository.rulesCount(drgElement)}
        )

        val INSTANCE = ${javaClassName}()

        fun ${transformer.bkmFunctionName(drgElement)}(${transformer.drgElementSignatureExtra(drgElement)}): ${transformer.drgElementOutputType(drgElement)} {
            return INSTANCE.apply(${transformer.drgElementArgumentsExtra(drgElement)})
        }
    }
}
