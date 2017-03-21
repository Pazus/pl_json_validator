create or replace package json_validator is
  pragma serially_reusable;
  
  subtype t_errmsg is varchar2(32767);
  type tt_errs is table of t_errmsg;

  procedure validate(schema json_object_t, data json_element_t, p_errs out tt_errs);

  procedure validate_schema(schema json_object_t, p_errs out tt_errs);

end json_validator;
/
create or replace package body json_validator is
  pragma serially_reusable;
  /*
  factoring common checks are not allowed like this
  {
    "type": "number",
    "oneOf": [
      { "multipleOf": 5 },
      { "multipleOf": 3 }
    ]
  }
  */

  subtype t_type is varchar2(50);
  subtype t_key is varchar2(2000);

  type t_placeholders is table of varchar2(32767);

  gc_schema_of_schema constant json_object_t := json_object_t.parse('{
    "id": "http://json-schema.org/draft-04/schema#",
    "$schema": "http://json-schema.org/draft-04/schema#",
    "description": "Core schema meta-schema",
    "definitions": {
        "schemaArray": {
            "type": "array",
            "minItems": 1,
            "items": { "$ref": "#" }
        },
        "positiveInteger": {
            "type": "integer",
            "minimum": 0
        },
        "positiveIntegerDefault0": {
            "allOf": [ { "$ref": "#/definitions/positiveInteger" }, { "default": 0 } ]
        },
        "simpleTypes": {
            "enum": [ "array", "boolean", "integer", "null", "number", "object", "string" ]
        },
        "stringArray": {
            "type": "array",
            "items": { "type": "string" },
            "minItems": 1,
            "uniqueItems": true
        }
    },
    "type": "object",
    "properties": {
        "id": {
            "type": "string",
            "format": "uri"
        },
        "$schema": {
            "type": "string",
            "format": "uri"
        },
        "title": {
            "type": "string"
        },
        "description": {
            "type": "string"
        },
        "default": {},
        "multipleOf": {
            "type": "number",
            "minimum": 0,
            "exclusiveMinimum": true
        },
        "maximum": {
            "type": "number"
        },
        "exclusiveMaximum": {
            "type": "boolean",
            "default": false
        },
        "minimum": {
            "type": "number"
        },
        "exclusiveMinimum": {
            "type": "boolean",
            "default": false
        },
        "maxLength": { "$ref": "#/definitions/positiveInteger" },
        "minLength": { "$ref": "#/definitions/positiveIntegerDefault0" },
        "pattern": {
            "type": "string",
            "format": "regex"
        },
        "additionalItems": {
            "anyOf": [
                { "type": "boolean" },
                { "$ref": "#" }
            ],
            "default": {}
        },
        "items": {
            "anyOf": [
                { "$ref": "#" },
                { "$ref": "#/definitions/schemaArray" }
            ],
            "default": {}
        },
        "maxItems": { "$ref": "#/definitions/positiveInteger" },
        "minItems": { "$ref": "#/definitions/positiveIntegerDefault0" },
        "uniqueItems": {
            "type": "boolean",
            "default": false
        },
        "maxProperties": { "$ref": "#/definitions/positiveInteger" },
        "minProperties": { "$ref": "#/definitions/positiveIntegerDefault0" },
        "required": { "$ref": "#/definitions/stringArray" },
        "additionalProperties": {
            "anyOf": [
                { "type": "boolean" },
                { "$ref": "#" }
            ],
            "default": {}
        },
        "definitions": {
            "type": "object",
            "additionalProperties": { "$ref": "#" },
            "default": {}
        },
        "properties": {
            "type": "object",
            "additionalProperties": { "$ref": "#" },
            "default": {}
        },
        "patternProperties": {
            "type": "object",
            "additionalProperties": { "$ref": "#" },
            "default": {}
        },
        "dependencies": {
            "type": "object",
            "additionalProperties": {
                "anyOf": [
                    { "$ref": "#" },
                    { "$ref": "#/definitions/stringArray" }
                ]
            }
        },
        "enum": {
            "type": "array",
            "minItems": 1,
            "uniqueItems": true
        },
        "type": {
            "anyOf": [
                { "$ref": "#/definitions/simpleTypes" },
                {
                    "type": "array",
                    "items": { "$ref": "#/definitions/simpleTypes" },
                    "minItems": 1,
                    "uniqueItems": true
                }
            ]
        },
        "allOf": { "$ref": "#/definitions/schemaArray" },
        "anyOf": { "$ref": "#/definitions/schemaArray" },
        "oneOf": { "$ref": "#/definitions/schemaArray" },
        "not": { "$ref": "#" }
    },
    "dependencies": {
        "exclusiveMaximum": [ "maximum" ],
        "exclusiveMinimum": [ "minimum" ]
    },
    "default": {}
}');
  gc_base_schema json_object_t;

  gv_curr_path json_array_t;
  
  gv_errors    tt_errs;

  --JSON Schema written against the current version of the specification.
  gc_schema_current_version constant varchar2(500) := 'http://json-schema.org/schema#';

  --JSON Schema hyperschema written against the current version of the specification.
  gc_hyperschema_current_version constant varchar2(500) := 'http://json-schema.org/hyper-schema#';

  --JSON Schema written against this version.
  gc_schema_version_04 constant varchar2(500) := 'http://json-schema.org/draft-04/schema#';

  --JSON Schema hyperschema written against this version.
  gc_hyper_schema_version_04 constant varchar2(500) := 'http://json-schema.org/draft-04/hyper-schema#';

  --JSON Schema written against JSON Schema, draft v3
  gc_schema_version_03 constant varchar2(500) := 'http://json-schema.org/draft-03/schema#';

  --JSON Schema hyperschema written against JSON Schema, draft v3
  gc_hyper_schema_version_03 constant varchar2(500) := 'http://json-schema.org/draft-03/hyper-schema#';

  g_curr_schema varchar2(500);

  gc_err_additems_notallowed     constant t_errmsg := 'schema only allows %d elements in array but instance has %d elements';
  gc_err_minitems_arraytooshort  constant t_errmsg := 'array is too short: must have at least %d elements but instance has %d elements';
  gc_err_maxitems_arraytoolarge  constant t_errmsg := 'array is too long: must have at most %d elements but instance has %d elements';
  gc_err_uniqueitems_dupelements constant t_errmsg := 'array must not contain duplicate elements';
  gc_err_minimum_toosmall        constant t_errmsg := 'numeric instance is lower than the required minimum (minimum: %s, found: %s)';
  gc_err_minimum_notexclusive    constant t_errmsg := 'numeric instance is not strictly greater than the required minimum %s';
  gc_err_maximum_toolarge        constant t_errmsg := 'numeric instance is greater than the required maximum (maximum: %s, found: %s)';
  gc_err_maximum_notexclusive    constant t_errmsg := 'numeric instance is not strictly lower than the required maximum %s';
  gc_err_addprops_notallowed     constant t_errmsg := 'object instance has properties which are not allowed by the schema: %s';
  gc_err_minlength_tooshort      constant t_errmsg := 'string "%s" is too short (length: %d, required minimum: %d)';
  gc_err_maxlength_toolong       constant t_errmsg := 'string "%s" is too long (length: %d, maximum allowed: %d)';
  gc_err_pattern_nomatch         constant t_errmsg := 'ECMA 262 regex "%s" does not match input string "%s"';
  gc_err_enum_notinenum          constant t_errmsg := 'instance value (%s) not found in enum (possible values: %s)';
  gc_err_nonzeroremainder        constant t_errmsg := 'remainder of division is not zero (%s / %s)';
  gc_err_minprops_notenough      constant t_errmsg := 'object has too few properties (found %d but schema requires at least %d)';
  gc_err_maxprops_toomany        constant t_errmsg := 'object has too many properties (found %d but schema requires at most %d)';
  gc_err_object_missingmembers   constant t_errmsg := 'object has missing required properties (%s)';
  gc_err_deps_missingpropdeps    constant t_errmsg := 'property "%s" of object has missing property dependencies (schema requires %s; missing: %s)';
  gc_err_typenomatch             constant t_errmsg := 'instance type (%s) does not match any allowed primitive type (allowed: %s)';
  gc_err_schema_nomatch          constant t_errmsg := 'instance failed to match at least one required schema among %d';
  gc_err_dr4_allof_fail          constant t_errmsg := 'instance failed to match all required schemas (matched only %d out of %d)';
  gc_err_dr4_oneof_fail          constant t_errmsg := 'instance failed to match exactly one schema (matched %d out of %d)';
  gc_err_dr4_not_fail            constant t_errmsg := 'instance matched a schema which it should not have';
  gc_err_dr3_disallow_type       constant t_errmsg := 'instance is of type %s, which is explicitly forbidden (disallowed: %s)';
  gc_err_dr3_disallow_schema     constant t_errmsg := 'instance matched %d out of %d explicitly forbidden schema(s)';

  --
  -- Format messages
  --
  gc_warn_format_notsupported    constant t_errmsg := 'format attribute "%s" not supported';
  gc_err_format_invaliddate      constant t_errmsg := 'string "%s" is invalid against requested date format(s) %s';
  gc_err_format_invalidemail     constant t_errmsg := 'string "%s" is not a valid email address';
  gc_err_format_invalidhostname  constant t_errmsg := 'string "%s" is not a valid hostname';
  gc_err_format_invalidipv4      constant t_errmsg := 'string "%s" is not a valid IPv4 address';
  gc_err_format_invalidipv6      constant t_errmsg := 'string "%s" is not a valid IPv6 address';
  gc_err_format_invalidregex     constant t_errmsg := 'string "%s" is not a valid ECMA 262 regular expression';
  gc_err_format_invalidphone     constant t_errmsg := 'string "%s" is not recognized as a phone number';
  gc_warn_format_epoch_negative  constant t_errmsg := 'value for epoch is negative (%s), probably not what you want';
  gc_warn_format_epoch_overflow  constant t_errmsg := 'value for epoch may lead to overflow (found %s, which is greater than 2^31 - 1)';
  gc_err_format_invaliduri       constant t_errmsg := 'string "%s" is not a valid URI';
  gc_err_format_hex_badlength    constant t_errmsg := 'input string has incorrect length (%d, expected %d)';
  gc_err_format_hex_illegalchar  constant t_errmsg := 'illegal character "%s" in input at index %d';
  gc_err_format_base64_badlength constant t_errmsg := 'input has illegal length (must be a multiple of 4, found %d)';
  gc_err_format_base64_illchars  constant t_errmsg := 'illegal character "%s" at index %d (not in Base64 alphabet)';
  gc_err_format_jsonpointer_inv  constant t_errmsg := 'input string "%s" is not a valid JSON Pointer';
  gc_err_format_macaddr_invalid  constant t_errmsg := 'input string "%s" is not a valid MAC address';
  gc_err_format_uritemplate_inv  constant t_errmsg := 'input string "%s" is not a valid URI template';
  gc_err_format_uuid_invalid     constant t_errmsg := 'input string "%s" is not a valid UUID';

  --
  -- Other messages
  --
  gc_err_common_validationloop constant t_errmsg := 'validation loop: schema "%s" visited twice for pointer "%s" of validated instance';
  gc_err_only_selfrefs_allowed constant t_errmsg := 'Only refs to the same schema allowed';
  gc_err_invalid_schema        constant t_errmsg := 'Invalid schema';
  gc_err_wrong_json_pointer    constant t_errmsg := 'Wrong type in JSON Pointer';

  function get_current_path return varchar2 is
    v_path varchar2(32767);
  begin
    for i in 0 .. gv_curr_path.get_size() - 1 loop
      v_path := v_path || '/' || gv_curr_path.get_string(i);
    end loop;
    return v_path;
  end get_current_path;

  procedure error(msg varchar2) is
  begin
    gv_errors.extend;
    gv_errors(gv_errors.last) := msg;
    --raise_application_error(-20001, get_current_path || chr(10) || msg);
  end error;

  procedure error(error_msg varchar2, placeholders t_placeholders) is
    v_err_msg varchar2(32767);
  begin
    v_err_msg := error_msg;
    for i in 1 .. placeholders.count loop
      v_err_msg := regexp_replace(srcstr     => v_err_msg
                                 ,pattern    => '(%s)|(%d)'
                                 ,replacestr => placeholders(i)
                                 ,position   => 1
                                 ,occurrence => 1);
    end loop;
  
    error(v_err_msg);
  end;

  function concat_json_array_t(jl json_array_t, sep varchar2 default ', ') return varchar2 is
    v_result  varchar2(32767);
    v_element json_element_t;
  begin
    for i in 0 .. jl.get_size - 1 loop
      v_element := jl.get(i);
      if i > 0 then
        v_result := v_result || sep;
      end if;
      if v_element.is_string then
        v_result := v_result || v_element.to_string;
      elsif v_element.is_number then
        v_result := v_result || v_element.to_number;
      elsif v_element.is_boolean then
        if v_element.to_boolean then
          v_result := v_result || 'TRUE';
        else
          v_result := v_result || 'FALSE';
        end if;
      elsif v_element.is_null then
        v_result := v_result || 'NULL';
      end if;
    end loop;
    return v_result;
  end concat_json_array_t;

  procedure validate_type(schema json_object_t, data json_element_t);

  function get_ref(ref_path varchar2) return json_element_t is
    jv         json_element_t;
    v_node     t_key;
    v_index    pls_integer := 1;
    v_doc_path varchar2(2000);
    l_ref_path varchar2(32767);
  begin
    if substr(ref_path, 1, 1) != '#' then
      error(gc_err_only_selfrefs_allowed);
    end if;
    
    --l_ref_path := replace(replace(replace(ref_path,'~0','~'),'~1','/'),'%25','%');
    l_ref_path := ref_path;
  
    v_doc_path := substr(regexp_substr(l_ref_path, '#/[^#]+'), 2);
  
    jv     := gc_base_schema; --.to_json_element_t;
    --    v_node := substr(regexp_substr(l_ref_path, '/[^/]+', 1, v_index), 2);   
    v_node := replace(replace(replace(substr(regexp_substr(l_ref_path, '/[^/]+', 1, v_index), 2),'~0','~'),'~1','/'),'%25','%');
  
    while v_node is not null loop
      if jv.is_object then
        jv := treat(jv as json_object_t).get(v_node);
      elsif jv.is_array then
        jv := treat(jv as json_array_t).get(v_node);
      else
        error(gc_err_wrong_json_pointer);
      end if;
      v_index := v_index + 1;
      --v_node  := substr(regexp_substr(l_ref_path, '/[^/]+', 1, v_index), 2);
      v_node  := replace(replace(replace(substr(regexp_substr(l_ref_path, '/[^/]+', 1, v_index), 2),'~0','~'),'~1','/'),'%25','%');
    end loop;
  
    return jv;
  
  end get_ref;

  function resolve_ref(j json_object_t) return json_object_t is
  begin
    if j.has('$ref') then
      return treat(get_ref(j.get_string('$ref')) as json_object_t);
    else
      return j;
    end if;
  end resolve_ref;

  function resolve_ref(jv json_element_t) return json_element_t is
    j           json_object_t;
    resolved_jv json_element_t;
  begin
    if jv.is_object then
      j := treat(jv as json_object_t);
      if j.has('$ref') then
        return get_ref(j.get_string('$ref'));
      else
        return jv;
      end if;
    else
      return jv;
    end if;
  end resolve_ref;

  function get_type(j_val json_element_t) return varchar2 is
    l_type varchar2(10);
  begin
    l_type := case
                when j_val.is_object then
                 'object'
                when j_val.is_string or j_val.is_date or j_val.is_timestamp then
                 'string'
                when j_val.is_array then
                 'array'
                when j_val.is_number then
                 'number'
                when j_val.is_boolean then
                 'boolean'
                when j_val.is_null then
                 'null'
              end;
    return l_type;
  end;

  function equals(p1 json_element_t, p2 json_element_t) return boolean;

  function equals(p1 json_object_t, p2 json_object_t) return boolean is
    l_keys1 json_key_list;
    l_keys2 json_key_list;
    l_diff  number(1);
  begin
  
    l_keys1 := coalesce(p1.get_keys, json_key_list());
    l_keys2 := coalesce(p2.get_keys, json_key_list());
  
    select count(*)
      into l_diff
      from dual
     where exists((select * from table(l_keys1) minus select * from table(l_keys2)) union all
                  (select * from table(l_keys2) minus select * from table(l_keys1)));
    if l_diff > 0 then
      return false;
    end if;
  
    for i in 1 .. l_keys1.count loop
      if not equals(p1.get(l_keys1(i)), p2.get(l_keys1(i))) then
        return false;
      end if;
    end loop;
  
    return true;
  end;

  function equals(p1 json_array_t, p2 json_array_t) return boolean is
  begin
    if p1.get_size != p2.get_size then
      return false;
    end if;
  
    for i in 0 .. p1.get_size - 1 loop
      if not equals(p1.get(i), p2.get(i)) then
        return false;
      end if;
    end loop;
    return true;
  end;

  function equals(p1 json_element_t, p2 json_element_t) return boolean is
  begin
    if get_type(p1) = get_type(p2) then
      if p1.is_object then
        return equals(treat(p1 as json_object_t), treat(p2 as json_object_t));
      elsif p1.is_array then
        return equals(treat(p1 as json_array_t), treat(p2 as json_array_t));
      elsif p1.is_boolean then
        return p1.to_boolean = p2.to_boolean;
      elsif p1.is_string or p1.is_date or p1.is_timestamp then
        return p1.to_string = p2.to_string;
      elsif p1.is_number then
        return p1.to_number = p2.to_number;
      elsif p1.is_null then
        return p2.is_null;
        return false; -- should never happen
      end if;
    end if;
    return false;
  end;

  function contains(p1 json_array_t, val json_element_t) return boolean is
  begin
    for i in 0 .. p1.get_size - 1 loop
      if equals(p1.get(i), val) then
        return true;
      end if;
    end loop;
    return false;
  end;

  function contains(p1 json_array_t, val varchar2) return boolean is
    l_val varchar2(32767);
  begin
    for i in 0 .. p1.get_size - 1 loop
      l_val := p1.get_string(i);
      if l_val = val then
        return true;
      end if;
    end loop;
    return false;
  end;

  procedure check_type_object(schema json_object_t, data json_element_t) is
    v_is_valid boolean := false;
  
    v_data_keys json_key_list;
    v_key       t_key;
  
    jdata json_object_t := treat(data as json_object_t);
  
    procedure check_required is
      v_required      json_array_t;
      v_req_prop_name varchar2(4000); --t_key;
      type ttt is varray(32767) of varchar2(4000);
      v_keys ttt;
    begin
      if schema.has('required') then
        v_required := schema.get_array('required');
      
        <<required_properties_loop>>
        for i in 0 .. v_required.get_size - 1 loop
          v_req_prop_name := v_required.get_string(i);
        
          for j in 1 .. v_data_keys.count loop
            continue required_properties_loop when v_req_prop_name = v_data_keys(j);
          end loop;
          error(gc_err_object_missingmembers, t_placeholders(v_req_prop_name));
        
        end loop;
      end if;
    end check_required;
  
    procedure check_min_properties is
      v_min_properties integer;
    begin
      if schema.has('minProperties') then
        v_min_properties := schema.get_number('minProperties');
        if v_data_keys.count < v_min_properties then
          error(gc_err_minprops_notenough, t_placeholders(v_data_keys.count, v_min_properties));
        end if;
      end if;
    end check_min_properties;
  
    procedure check_max_properties is
      v_max_properties integer;
    begin
      if schema.has('maxProperties') then
        v_max_properties := schema.get_number('maxProperties');
        if v_data_keys.count > v_max_properties then
          error(gc_err_maxprops_toomany, t_placeholders(v_data_keys.count, v_max_properties));
        end if;
      end if;
    end check_max_properties;
  
    procedure check_dependencies is
      v_dependencies json_object_t;
      v_key          t_key;
      v_dep_keys     json_key_list;
      v_child_jl     json_array_t;
      v_child_jv     json_element_t;
    begin
      if schema.has('dependencies') then
        v_dependencies := schema.get_object('dependencies');
        v_dep_keys     := coalesce(v_dependencies.get_keys, json_key_list());
      
        for i in 1 .. v_dep_keys.count loop
          v_key := v_dep_keys(i);
          if jdata.has(v_key) then
            v_child_jv := v_dependencies.get(v_key);
          
            if v_child_jv.is_array then
              v_child_jl := treat(v_child_jv as json_array_t);
            
              for j in 0 .. v_child_jl.get_size - 1 loop
                if not jdata.has(v_child_jl.get_string(j)) then
                  error(gc_err_deps_missingpropdeps
                       ,t_placeholders(v_key, v_child_jl.get_string(j), v_child_jl.get_string(j)));
                  --error('Dependent property dosn''t exist');
                end if;
              end loop;
            else
              validate_type(treat(v_child_jv as json_object_t), jdata);
            end if;
          end if;
        end loop;
      end if;
    end check_dependencies;
  
    procedure check_properties is
      v_key                   t_key;
      v_props                 json_object_t;
      v_patternprops          json_object_t;
      v_patternprops_patterns json_key_list;
      v_schema_keys           json_array_t;
      v_additionalproperties  boolean := true;
      v_default_schema        json_object_t;
      v_pattern               varchar2(4000);
    
      function match_pattern_prop(key varchar2, pattern out varchar2) return boolean is
        v_found boolean := false;
      begin
        if v_patternprops_patterns is not null and v_patternprops_patterns.count > 0 then
          for i in 1 .. v_patternprops_patterns.count loop
            if regexp_like(key, v_patternprops_patterns(i)) then
              pattern := v_patternprops_patterns(i);
              v_found := true;
            end if;
          end loop;
        end if;
        return v_found;
      end match_pattern_prop;
    
    begin
      if schema.has('additionalProperties') then
        if schema.get('additionalProperties').is_boolean then
          v_additionalproperties := schema.get_boolean('additionalProperties');
        else
          v_default_schema       := schema.get_object('additionalProperties');
          v_additionalproperties := true;
        end if;
      
      end if;
    
      if schema.has('properties') then
        v_props := schema.get_object('properties');
      end if;
    
      if schema.has('patternProperties') then
        v_patternprops          := schema.get_object('patternProperties');
        v_patternprops_patterns := coalesce(v_patternprops.get_keys, json_key_list());
      end if;
    
      --v_schema_keys := v_props.get_keys;
      for i in 1 .. v_data_keys.count loop
      
        v_key := v_data_keys(i);
      
        /* TO-DO petternProperties */
      
        if v_props is not null and v_props.has(v_key) then
          -- Check property schema
          gv_curr_path.append(v_key);
          validate_type(v_props.get_object(v_key), jdata.get(v_key));
          gv_curr_path.remove(gv_curr_path.get_size - 1);
        elsif match_pattern_prop(v_key, v_pattern) then
          -- Check petternProperty schema
          gv_curr_path.append(v_key);
          validate_type(v_patternprops.get_object(v_pattern), jdata.get(v_key));
          gv_curr_path.remove(gv_curr_path.get_size - 1);
        elsif v_additionalproperties and v_default_schema is not null then
          -- check default schema
          gv_curr_path.append(v_key);
          validate_type(v_default_schema, jdata.get(v_key));
          gv_curr_path.remove(gv_curr_path.get_size - 1);
        elsif not v_additionalproperties then
          error(gc_err_addprops_notallowed, t_placeholders(v_key));
        end if;
      
      end loop;
    
    end check_properties;
  
  begin
    v_data_keys := coalesce(jdata.get_keys, json_key_list());
  
    -- Check required properties
    check_required;
  
    -- Check minimum number of properties
    check_min_properties;
  
    -- Check maximum number of properties
    check_max_properties;
  
    -- Check Dependencies
    check_dependencies;
  
    -- Check properties
    check_properties;
  end check_type_object;

  procedure check_type_array(schema json_object_t, data json_element_t) is
    v_data_jl         json_array_t := treat(data as json_array_t);
    v_items_jv        json_element_t;
    v_items_jl        json_array_t;
    v_additionalitems boolean := true;
  
    procedure check_length is
      v_min integer;
      v_max integer;
    begin
      if schema.has('minItems') and v_data_jl.get_size < schema.get_number('minItems') then
        error(gc_err_minitems_arraytooshort, t_placeholders(schema.get_number('minItems'), v_data_jl.get_size));
      end if;
    
      if schema.has('maxItems') and v_data_jl.get_size > schema.get_number('maxItems') then
        error(gc_err_maxitems_arraytoolarge, t_placeholders(schema.get_number('minItems'), v_data_jl.get_size));
      end if;
    
    end check_length;
  
    procedure check_uniqueness is
      v_duplicate_found boolean := false;
      v_val             json_element_t;
    begin
      if schema.has('uniqueItems') and schema.get_boolean('uniqueItems') then
        for i in 0 .. v_data_jl.get_size - 1 loop
          v_val := v_data_jl.get(i);
          for j in i + 1 .. v_data_jl.get_size - 1 loop
            if equals(v_val, v_data_jl.get(j)) then
              error(gc_err_uniqueitems_dupelements);
            end if;
          end loop;
        end loop;
      end if;
    end check_uniqueness;
  
  begin
  
    check_length;
  
    check_uniqueness;
  
    if schema.has('items') then
      v_items_jv := schema.get('items');
    
      if schema.has('additionalItems') then
        v_additionalitems := schema.get_boolean('additionalItems');
      end if;
    
      if v_items_jv.is_object then
        for i in 0 .. v_data_jl.get_size - 1 loop
          gv_curr_path.append(i);
        
          validate_type(treat(v_items_jv as json_object_t), v_data_jl.get(i));
        
          gv_curr_path.remove(gv_curr_path.get_size - 1);
        end loop;
      else
        v_items_jl := treat(v_items_jv as json_array_t);
      
        if not v_additionalitems and v_data_jl.get_size > v_items_jl.get_size then
          error(gc_err_additems_notallowed, t_placeholders(v_items_jl.get_size, v_data_jl.get_size));
        end if;
      
        for i in 0 .. least(v_items_jl.get_size, v_data_jl.get_size) - 1 loop
          gv_curr_path.append(i);
        
          validate_type(treat(v_items_jl.get(i) as json_object_t), v_data_jl.get(i));
        
          gv_curr_path.remove(gv_curr_path.get_size - 1);
        end loop;
      end if;
    end if;
  
  end check_type_array;

  procedure check_type_string(schema json_object_t, data json_element_t) is
    v_string varchar2(32767);
  
    procedure check_length is
    begin
      if schema.has('minLength') and length(v_string) < schema.get_number('minLength') then
        error(gc_err_minlength_tooshort, t_placeholders(v_string, schema.get_number('minLength'), length(v_string)));
      end if;
    
      if schema.has('maxLength') and length(v_string) > schema.get_number('maxLength') then
        error(gc_err_maxlength_toolong, t_placeholders(v_string, schema.get_number('maxLength'), length(v_string)));
      end if;
    end check_length;
  
    procedure check_pattern is
      v_pattern varchar2(32767);
    begin
      if schema.has('pattern') then
        v_pattern := schema.get_string('pattern');
      
        if regexp_like(v_string, v_pattern) then
          null;
        else
          error(gc_err_pattern_nomatch, t_placeholders(v_pattern, v_string));
        end if;
      end if;
    end check_pattern;
  begin
    v_string := data.to_string;
  
    check_length;
  
    check_pattern;
  end check_type_string;

  procedure check_type_number(schema json_object_t, data json_element_t) is
    v_number number;
  
    procedure check_multiple_of is
      v_mod number;
    begin
      if schema.has('multipleOf') then
        v_mod := schema.get_number('multipleOf');
      
        if mod(v_number, v_mod) != 0 then
          error(gc_err_nonzeroremainder, t_placeholders(v_number, v_mod));
        end if;
      end if;
    end check_multiple_of;
  
    procedure check_range is
      v_min      number;
      v_excl_min boolean := false;
      v_max      number;
      v_excl_max boolean := false;
    begin
      if schema.has('minimum') then
        v_min := schema.get_number('minimum');
      
        if schema.has('exclusiveMinimum') then
          v_excl_min := schema.get_boolean('exclusiveMinimum');
        end if;
      
        if not v_excl_min and v_number < v_min then
          error(gc_err_minimum_toosmall, t_placeholders(v_min, v_number));
        elsif v_excl_min and v_number <= v_min then
          error(gc_err_minimum_notexclusive, t_placeholders(v_min, v_number));
        end if;
      end if;
    
      if schema.has('maximum') then
        v_max := schema.get_number('maximum');
      
        if schema.has('exclusiveMaximum') then
          v_excl_max := schema.get_boolean('exclusiveMaximum');
        end if;
      
        if v_excl_max and v_number >= v_max then
          error(gc_err_maximum_toolarge, t_placeholders(v_max, v_number));
        elsif not v_excl_max and v_number > v_max then
          error(gc_err_maximum_notexclusive, t_placeholders(v_max, v_number));
        end if;
      end if;
    
    end check_range;
  begin
    v_number := data.to_number;
  
    check_multiple_of;
  
    check_range;
  
  end check_type_number;

  procedure check_type_boolean(schema json_object_t, data json_element_t) is
  begin
    null;
  end check_type_boolean;

  procedure check_type_null(schema json_object_t, data json_element_t) is
  begin
    null;
  end check_type_null;

  procedure validate_type(schema json_object_t, data json_element_t) is
    jv               json_element_t;
    v_types          json_array_t;
    v_is_valid       boolean := false;
    v_allanyoneof_j  json_object_t;
    v_allanyoneof_jl json_array_t;
  
    v_matched        pls_integer := 0;
    v_to_match_count pls_integer;
  
    v_was_failure         boolean := false;
    v_was_success         boolean := false;
    v_was_another_success boolean := false;
  
    resolved_schema json_object_t;
  
    procedure check_enum is
      v_found   boolean := false;
      v_enum    json_array_t;
      v_str_val varchar2(32767);
    begin
      if resolved_schema.has('enum') then
        v_enum := resolved_schema.get_array('enum');
      
        if not contains(v_enum, data) then
          -- Need to be generalized not only to strings
          error(gc_err_enum_notinenum, t_placeholders(data.to_string, concat_json_array_t(v_enum)));
        end if;
      
      end if;
    end check_enum;
  
    procedure simple_type_check is
      v_cur_type t_type;
      l_str      varchar2(32767);
    begin
      v_cur_type := get_type(data);
      l_str      := v_types.stringify;
      if contains(v_types, v_cur_type) or
         (v_cur_type = 'number' and contains(v_types, 'integer') and trunc(data.to_number) = data.to_number) or
         contains(v_types, 'any') then
        null;
      else
        error(gc_err_typenomatch, t_placeholders(get_type(data), concat_json_array_t(v_types)));
      end if;
    
    end simple_type_check;
  begin
  
    resolved_schema := resolve_ref(schema);
  
    if resolved_schema.has('allOf') then
      if resolved_schema.get('allOf').is_array then
        v_allanyoneof_jl := resolved_schema.get_array('allOf');
        v_to_match_count := v_allanyoneof_jl.get_size;
      
        for i in 0 .. v_allanyoneof_jl.get_size - 1 loop
          begin
            validate_type(treat(v_allanyoneof_jl.get(i) as json_object_t), data);
            v_matched := v_matched + 1;
          exception
            when others then
              null;
          end;
        end loop;
      elsif resolved_schema.get('allOf').is_object then
        v_allanyoneof_j  := resolved_schema.get_object('allOf');
        v_to_match_count := 1;
        begin
          validate_type(v_allanyoneof_j, data);
          v_matched := v_matched + 1;
        exception
          when others then
            null;
        end;
      else
        error(gc_err_invalid_schema);
      end if;
    
      if v_matched < v_to_match_count then
        error(gc_err_dr4_allof_fail, t_placeholders(v_matched, v_to_match_count));
      end if;
    elsif resolved_schema.has('anyOf') then
      if resolved_schema.get('anyOf').is_array then
        v_allanyoneof_jl := resolved_schema.get_array('anyOf');
        v_to_match_count := v_allanyoneof_jl.get_size;
      
        for i in 0 .. v_allanyoneof_jl.get_size - 1 loop
          begin
            validate_type(treat(v_allanyoneof_jl.get(i) as json_object_t), data);
            v_matched := v_matched + 1;
            exit;
          exception
            when others then
              null;
          end;
        end loop;
      elsif resolved_schema.get('anyOf').is_object then
        v_allanyoneof_j  := resolved_schema.get_object('anyOf');
        v_to_match_count := 1;
      
        begin
          validate_type(v_allanyoneof_j, data);
          v_matched := v_matched + 1;
        exception
          when others then
            null;
        end;
      else
        error(gc_err_invalid_schema);
      end if;
    
      if v_matched = 0 then
        error(gc_err_schema_nomatch, t_placeholders(v_to_match_count));
      end if;
    elsif resolved_schema.has('oneOf') then
      if resolved_schema.get('oneOf').is_array then
        v_allanyoneof_jl := resolved_schema.get_array('oneOf');
        v_to_match_count := v_allanyoneof_jl.get_size;
      
        for i in 0 .. v_allanyoneof_jl.get_size - 1 loop
          begin
            validate_type(treat(v_allanyoneof_jl.get(i) as json_object_t), data);
            v_matched := v_matched + 1;
          exception
            when others then
              null;
          end;
        end loop;
      elsif resolved_schema.get('oneOf').is_object then
        v_allanyoneof_j  := resolved_schema.get_object('oneOf');
        v_to_match_count := 1;
      
        begin
          validate_type(v_allanyoneof_j, data);
          v_matched := v_matched + 1;
        
        exception
          when others then
            null;
        end;
      else
        error(gc_err_invalid_schema);
      end if;
    
      if v_matched != 1 then
        error(gc_err_dr4_oneof_fail, t_placeholders(v_matched, v_to_match_count));
      end if;
    
    elsif resolved_schema.has('not') then
      if resolved_schema.get('not').is_array then
        v_allanyoneof_jl := resolved_schema.get_array('not');
      
        for i in 0 .. v_allanyoneof_jl.get_size - 1 loop
          begin
            validate_type(treat(v_allanyoneof_jl.get(i) as json_object_t), data);
            v_matched := v_matched + 1;
            exit;
          exception
            when others then
              null;
          end;
        end loop;
      elsif resolved_schema.get('not').is_object then
        v_allanyoneof_j := resolved_schema.get_object('not');
      
        begin
          validate_type(v_allanyoneof_j, data);
          v_matched := v_matched + 1;
        exception
          when others then
            null;
        end;
      else
        error(gc_err_invalid_schema);
      end if;
    
      if v_matched > 0 then
        error(gc_err_dr4_not_fail, null);
      end if;
    else
    
      if resolved_schema.has('type') then
        jv := resolved_schema.get('type');
        if jv.is_array then
          v_types := treat(jv as json_array_t);
        else
          v_types := json_array_t();
          v_types.append(jv);
        end if;
      else
        v_types := json_array_t();
        v_types.append('any');
      end if;
    
      -- check type matches any of listed
      simple_type_check;
    
      -- check element in enum
      check_enum;
    
      -- schema-based type check
      case get_type(data)
        when 'object' then
          check_type_object(resolved_schema, data);
        when 'array' then
          check_type_array(resolved_schema, data);
        when 'string' then
          check_type_string(resolved_schema, data);
        when 'number' then
          check_type_number(resolved_schema, data);
        when 'boolean' then
          check_type_boolean(resolved_schema, data);
        when 'null' then
          check_type_null(resolved_schema, data);
      end case;
    
    end if;
  
  end validate_type;

  procedure validate(schema json_object_t, data json_element_t, p_errs out tt_errs) is
  begin
  
    gc_base_schema := schema;
    
    gv_errors := tt_errs();
  
    if schema.has('$schema') then
      g_curr_schema := schema.get_string('$schema');
    end if;
  
    gv_curr_path := json_array_t();
  
    validate_type(schema, data);
    
    p_errs := gv_errors;
  
    gv_curr_path := null;
  
  end validate;

  procedure validate_schema(schema json_object_t, p_errs out tt_errs) is
  begin
    validate(gc_schema_of_schema, schema, p_errs);
  end validate_schema;

end json_validator;
/
