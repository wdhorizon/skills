#!/usr/bin/env python3
"""
Aliyun Planner JSON Output Validator
验证输出的 JSON 格式是否符合规范
"""

from typing import Union, Dict, Any, List, Tuple


class AliyunPlannerValidator:
    """Aliyun Planner JSON 验证器"""

    # 有效的主意图
    VALID_PRIMARY_INTENTS = {
        'SIMPLE_QUERY',
        'ASSOCIATION_QUERY',
        'COMPOUND_QUERY',
        'DIAGNOSTIC_QUERY',
        'COMPARISON_QUERY',
        'OPERATIONAL_QUERY'
    }

    # 有效的执行策略
    VALID_EXECUTION_STRATEGIES = {
        'SEQUENTIAL',
        'PARALLEL',
        'CACHE_FIRST',
        'BATCH'
    }

    # 有效的复杂度等级
    VALID_COMPLEXITY = {'L1', 'L2', 'L3', 'L4', 'L5'}

    @staticmethod
    def validate_intent_core(intent_core: Dict[str, Any]) -> Tuple[bool, str]:
        """验证意图核心信息"""
        if not isinstance(intent_core, dict):
            return False, "intent_core must be a dictionary"

        required_fields = ['primary_intent', 'sub_intent', 'complexity', 'business_scenario', 'confidence']
        for field in required_fields:
            if field not in intent_core:
                return False, f"intent_core missing required field: {field}"

        if intent_core['primary_intent'] not in AliyunPlannerValidator.VALID_PRIMARY_INTENTS:
            return False, f"Invalid primary_intent: {intent_core['primary_intent']}"

        if intent_core['complexity'] not in AliyunPlannerValidator.VALID_COMPLEXITY:
            return False, f"Invalid complexity: {intent_core['complexity']}"

        if not isinstance(intent_core['confidence'], (int, float)) or not (0 <= intent_core['confidence'] <= 1):
            return False, f"confidence must be a number between 0 and 1, got: {intent_core['confidence']}"

        return True, ""

    @staticmethod
    def validate_entities(entities: Dict[str, Any]) -> Tuple[bool, str]:
        """验证实体信息"""
        if not isinstance(entities, dict):
            return False, "entities must be a dictionary"

        if 'primary_entity' not in entities:
            return False, "entities missing required field: primary_entity"

        primary_entity = entities['primary_entity']
        if not isinstance(primary_entity, dict):
            return False, "primary_entity must be a dictionary"

        required_fields = ['service', 'resource_type', 'identifier_type', 'identifier_value', 'original_expression']
        for field in required_fields:
            if field not in primary_entity:
                return False, f"primary_entity missing required field: {field}"

        return True, ""

    @staticmethod
    def validate_relationships(relationships: Dict[str, Any]) -> Tuple[bool, str]:
        """验证关系信息"""
        if not isinstance(relationships, dict):
            return False, "relationships must be a dictionary"

        # relationships 可以为空，但如果包含字段则需要验证
        optional_fields = ['relations', 'relationship_path', 'join_conditions', 'inferred_relations']
        for field in optional_fields:
            if field in relationships:
                value = relationships[field]
                if field in ['relations', 'relationship_path', 'inferred_relations'] and not isinstance(value, list):
                    return False, f"relationships.{field} must be a list"
                if field == 'join_conditions' and not isinstance(value, dict):
                    return False, f"relationships.{field} must be a dictionary"

        return True, ""

    @staticmethod
    def validate_cli_command(cmd: Dict[str, Any], index: int, total_commands: int) -> Tuple[bool, str]:
        """验证单个 CLI 命令"""
        if not isinstance(cmd, dict):
            return False, f"cli_commands[{index}] must be a dictionary"

        required_fields = ['command', 'parameters', 'tid']
        for field in required_fields:
            if field not in cmd:
                return False, f"cli_commands[{index}] missing required field: {field}"

        # 验证 command 字段
        command = cmd['command']
        if not isinstance(command, list):
            return False, f"cli_commands[{index}].command must be a list"

        if len(command) < 2:
            return False, f"cli_commands[{index}].command must contain at least service and operation"

        # 检查不应包含 "aliyun" 前缀
        if command[0] == 'aliyun':
            return False, f"cli_commands[{index}].command should not start with 'aliyun' prefix"

        # 验证 parameters 字段
        if not isinstance(cmd['parameters'], dict):
            return False, f"cli_commands[{index}].parameters must be a dictionary"

        # 验证 tid 字段
        tid = cmd['tid']
        if not isinstance(tid, int) or tid < 0:
            return False, f"cli_commands[{index}].tid must be a non-negative integer"

        if tid != index:
            return False, f"cli_commands[{index}].tid should be {index}, but got {tid}"

        # 验证 depends_on 字段（如果存在）
        if 'depends_on' in cmd:
            depends_on = cmd['depends_on']
            if not isinstance(depends_on, list):
                return False, f"cli_commands[{index}].depends_on must be a list"

            for dep_id in depends_on:
                if not isinstance(dep_id, int) or dep_id < 0 or dep_id >= total_commands:
                    return False, f"cli_commands[{index}].depends_on contains invalid reference: {dep_id}"

        return True, ""

    @staticmethod
    def validate_data_flow(data_flow: Dict[str, Any]) -> Tuple[bool, str]:
        """验证数据流转信息"""
        if not isinstance(data_flow, dict):
            return False, "data_flow must be a dictionary"

        # 验证 flow 字段
        if 'flow' in data_flow:
            flow = data_flow['flow']
            if not isinstance(flow, list):
                return False, "data_flow.flow must be a list"
            if len(flow) == 0:
                return False, "data_flow.flow must be a non-empty list"

        return True, ""

    @staticmethod
    def validate_prerequisites(prerequisites: Dict[str, Any]) -> Tuple[bool, str]:
        """验证前提条件信息"""
        if not isinstance(prerequisites, dict):
            return False, "prerequisites must be a dictionary"

        # 验证 required_permissions 字段
        if 'required_permissions' in prerequisites:
            required_permissions = prerequisites['required_permissions']
            if not isinstance(required_permissions, list):
                return False, "prerequisites.required_permissions must be a list"
            # if len(required_permissions) == 0:
            #     return False, "prerequisites.required_permissions must be a non-empty list"

        # 验证 required_parameters 字段
        if 'required_parameters' in prerequisites:
            required_parameters = prerequisites['required_parameters']
            if not isinstance(required_parameters, list):
                return False, "prerequisites.required_parameters must be a list"

        return True, ""

    @staticmethod
    def validate_execution(execution: Dict[str, Any]) -> Tuple[bool, str]:
        """验证执行计划"""
        if not isinstance(execution, dict):
            return False, "execution must be a dictionary"

        required_fields = ['execution_strategy', 'cli_commands']
        for field in required_fields:
            if field not in execution:
                return False, f"execution missing required field: {field}"

        if execution['execution_strategy'] not in AliyunPlannerValidator.VALID_EXECUTION_STRATEGIES:
            return False, f"Invalid execution_strategy: {execution['execution_strategy']}"

        cli_commands = execution['cli_commands']
        if not isinstance(cli_commands, list) or len(cli_commands) == 0:
            return False, "execution.cli_commands must be a non-empty list"

        # 验证每个命令
        for i, cmd in enumerate(cli_commands):
            is_valid, error = AliyunPlannerValidator.validate_cli_command(cmd, i, len(cli_commands))
            if not is_valid:
                return False, error

        # 验证可选字段 data_flow（如果存在）
        if 'data_flow' in execution:
            is_valid, error = AliyunPlannerValidator.validate_data_flow(execution['data_flow'])
            if not is_valid:
                return False, f"Error in data_flow: {error}"

        # 验证可选字段 prerequisites（如果存在）
        if 'prerequisites' in execution:
            is_valid, error = AliyunPlannerValidator.validate_prerequisites(execution['prerequisites'])
            if not is_valid:
                return False, f"Error in prerequisites: {error}"

        return True, ""

    @classmethod
    def validate(cls, data: Dict[str, Any]) -> Tuple[bool, str]:
        """验证完整的 Aliyun Planner 输出"""
        # 验证必需的顶级字段
        required_fields = ['intent_core', 'entities', 'relationships', 'execution']
        for field in required_fields:
            if field not in data:
                return False, f"Missing required field: {field}"

        # 验证每个部分
        validators = [
            ('intent_core', cls.validate_intent_core),
            ('entities', cls.validate_entities),
            ('relationships', cls.validate_relationships),
            ('execution', cls.validate_execution),
        ]

        for field_name, validator_func in validators:
            is_valid, error = validator_func(data[field_name])
            if not is_valid:
                return False, f"Error in {field_name}: {error}"

        return True, "Validation passed"


def validate_json_output(data: Union[Dict[str, Any], str]) -> Tuple[bool, str]:
    """
    验证 JSON 输出格式

    Args:
        data: 待验证的 JSON 数据，可以是字典或 JSON 字符串

    Returns:
        (is_valid, message): 验证结果和错误信息（如果验证失败）
    """
    import json

    # 如果是字符串，先解析为字典
    if isinstance(data, str):
        try:
            data = json.loads(data)
        except json.JSONDecodeError as e:
            return False, f"Invalid JSON: {str(e)}"

    if not isinstance(data, dict):
        return False, "Input must be a JSON object (dictionary)"

    # 使用 AliyunPlannerValidator 验证
    return AliyunPlannerValidator.validate(data)


if __name__ == "__main__":
    import sys
    import json

    # 从命令行读取 JSON 文件
    if len(sys.argv) < 2:
        print("Usage: python validate_json.py <json_file>")
        print("\nOr use as a library:")
        print("  from validate_json import validate_json_output")
        print("  is_valid, message = validate_json_output(your_json_dict)")
        sys.exit(1)

    json_file = sys.argv[1]
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        is_valid, message = validate_json_output(data)

        if is_valid:
            print("✅ JSON validation PASSED")
            sys.exit(0)
        else:
            print(f"❌ JSON validation FAILED: {message}")
            sys.exit(1)
    except Exception as e:
        print(f"❌ Error reading file: {str(e)}")
        sys.exit(1)
