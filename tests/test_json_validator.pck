create or replace package test_json_validator is

  --%suite

  --%test(additionalItems as schema)
  procedure test_additionalitems;

  --%test(additionalProperties being false does not allow other properties)
  procedure test_additional_properties;

  --%tets(allOf)
  procedure test_all_of;

  --%test(anyOf)
  procedure test_any_of;

  --%test(default)
  procedure test_default;

  --%test(a schema given for items)
  procedure test_items;

  --%test
  procedure test_ref;

  --%test
  procedure test_required;

  --%test(test type)
  procedure test_type;

  --%test
  procedure test_unique_items;

end test_json_validator;
/
create or replace package body test_json_validator is

  procedure validate_test_set(p_data json_array_t) is
    l_test_case json_object_t;
    l_schema    json_object_t;
    l_tests     json_array_t;
    l_test      json_object_t;
    l_errs      json_validator.tt_errs;
  begin
    for i in 0 .. p_data.get_size - 1 loop
      l_test_case := treat(p_data.get(i) as json_object_t);
    
      l_schema := l_test_case.get_object('schema');
      l_tests  := l_test_case.get_array('tests');
    
      for j in 0 .. l_tests.get_size - 1 loop
      
        l_test := treat(l_tests.get(j) as json_object_t);
      
        begin
          json_validator.validate(l_schema, l_test.get('data'), l_errs);
          if l_test.get_boolean('valid') then
            ut.expect(l_errs.count, l_test.get_string('description') || ' - ' || i || '.' || j).to_equal(0);
          else
            ut.expect(l_errs.count, l_test.get_string('description') || ' - ' || i || '.' || j).to_(be_greater_than(0));
          end if;
        exception
          when others then
            ut.fail(l_test.get_string('description') || ' - ' || i || '.' || j || chr(10) ||
                    dbms_utility.format_error_stack);
        end;
      end loop;
    end loop;
  end;

  procedure test_additionalitems is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "additionalItems as schema",
    "schema": {
      "items": [
        {}
      ],
      "additionalItems": {
        "type": "integer"
      }
    },
    "tests": [
      {
        "description": "additional items match schema",
        "data": [
          null,
          2,
          3,
          4
        ],
        "valid": true
      },
      {
        "description": "additional items do not match schema",
        "data": [
          null,
          2,
          3,
          "foo"
        ],
        "valid": false
      }
    ]
  },
  {
    "description": "items is schema, no additionalItems",
    "schema": {
      "items": {},
      "additionalItems": false
    },
    "tests": [
      {
        "description": "all items match schema",
        "data": [
          1,
          2,
          3,
          4,
          5
        ],
        "valid": true
      }
    ]
  },
  {
    "description": "array of items with no additionalItems",
    "schema": {
      "items": [
        {},
        {},
        {}
      ],
      "additionalItems": false
    },
    "tests": [
      {
        "description": "no additional items present",
        "data": [
          1,
          2,
          3
        ],
        "valid": true
      },
      {
        "description": "additional items are not permitted",
        "data": [
          1,
          2,
          3,
          4
        ],
        "valid": false
      }
    ]
  },
  {
    "description": "additionalItems as false without items",
    "schema": {
      "additionalItems": false
    },
    "tests": [
      {
        "description": "items defaults to empty schema so everything is valid",
        "data": [
          1,
          2,
          3,
          4,
          5
        ],
        "valid": true
      },
      {
        "description": "ignores non-arrays",
        "data": {
          "foo": "bar"
        },
        "valid": true
      }
    ]
  },
  {
    "description": "additionalItems are allowed by default",
    "schema": {
      "items": [
        {
          "type": "integer"
        }
      ]
    },
    "tests": [
      {
        "description": "only the first item is validated",
        "data": [
          1,
          "foo",
          false
        ],
        "valid": true
      }
    ]
  }
]}'));
  end;

  procedure test_additional_properties is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "additionalItems as schema",
    "schema": {
      "items": [
        {}
      ],
      "additionalItems": {
        "type": "integer"
      }
    },
    "tests": [
      {
        "description": "additional items match schema",
        "data": [
          null,
          2,
          3,
          4
        ],
        "valid": true
      },
      {
        "description": "additional items do not match schema",
        "data": [
          null,
          2,
          3,
          "foo"
        ],
        "valid": false
      }
    ]
  },
  {
    "description": "items is schema, no additionalItems",
    "schema": {
      "items": {},
      "additionalItems": false
    },
    "tests": [
      {
        "description": "all items match schema",
        "data": [
          1,
          2,
          3,
          4,
          5
        ],
        "valid": true
      }
    ]
  },
  {
    "description": "array of items with no additionalItems",
    "schema": {
      "items": [
        {},
        {},
        {}
      ],
      "additionalItems": false
    },
    "tests": [
      {
        "description": "no additional items present",
        "data": [
          1,
          2,
          3
        ],
        "valid": true
      },
      {
        "description": "additional items are not permitted",
        "data": [
          1,
          2,
          3,
          4
        ],
        "valid": false
      }
    ]
  },
  {
    "description": "additionalItems as false without items",
    "schema": {
      "additionalItems": false
    },
    "tests": [
      {
        "description": "items defaults to empty schema so everything is valid",
        "data": [
          1,
          2,
          3,
          4,
          5
        ],
        "valid": true
      },
      {
        "description": "ignores non-arrays",
        "data": {
          "foo": "bar"
        },
        "valid": true
      }
    ]
  },
  {
    "description": "additionalItems are allowed by default",
    "schema": {
      "items": [
        {
          "type": "integer"
        }
      ]
    },
    "tests": [
      {
        "description": "only the first item is validated",
        "data": [
          1,
          "foo",
          false
        ],
        "valid": true
      }
    ]
  }
]}'));
  end;

  procedure test_all_of is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "allOf",
    "schema": {
      "allOf": [
        {
          "properties": {
            "bar": {
              "type": "integer"
            }
          },
          "required": [
            "bar"
          ]
        },
        {
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "required": [
            "foo"
          ]
        }
      ]
    },
    "tests": [
      {
        "description": "allOf",
        "data": {
          "foo": "baz",
          "bar": 2
        },
        "valid": true
      },
      {
        "description": "mismatch second",
        "data": {
          "foo": "baz"
        },
        "valid": false
      },
      {
        "description": "mismatch first",
        "data": {
          "bar": 2
        },
        "valid": false
      },
      {
        "description": "wrong type",
        "data": {
          "foo": "baz",
          "bar": "quux"
        },
        "valid": false
      }
    ]
  },
  {
    "description": "allOf with base schema",
    "schema": {
      "properties": {
        "bar": {
          "type": "integer"
        }
      },
      "required": [
        "bar"
      ],
      "allOf": [
        {
          "properties": {
            "foo": {
              "type": "string"
            }
          },
          "required": [
            "foo"
          ]
        },
        {
          "properties": {
            "baz": {
              "type": "null"
            }
          },
          "required": [
            "baz"
          ]
        }
      ]
    },
    "tests": [
      {
        "description": "valid",
        "data": {
          "foo": "quux",
          "bar": 2,
          "baz": null
        },
        "valid": true
      },
      {
        "description": "mismatch base schema",
        "data": {
          "foo": "quux",
          "baz": null
        },
        "valid": false
      },
      {
        "description": "mismatch first allOf",
        "data": {
          "bar": 2,
          "baz": null
        },
        "valid": false
      },
      {
        "description": "mismatch second allOf",
        "data": {
          "foo": "quux",
          "bar": 2
        },
        "valid": false
      },
      {
        "description": "mismatch both",
        "data": {
          "bar": 2
        },
        "valid": false
      }
    ]
  },
  {
    "description": "allOf simple types",
    "schema": {
      "allOf": [
        {
          "maximum": 30
        },
        {
          "minimum": 20
        }
      ]
    },
    "tests": [
      {
        "description": "valid",
        "data": 25,
        "valid": true
      },
      {
        "description": "mismatch one",
        "data": 35,
        "valid": false
      }
    ]
  }
]}'));
  end;

  procedure test_any_of is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "anyOf",
    "schema": {
      "anyOf": [
        {
          "type": "integer"
        },
        {
          "minimum": 2
        }
      ]
    },
    "tests": [
      {
        "description": "first anyOf valid",
        "data": 1,
        "valid": true
      },
      {
        "description": "second anyOf valid",
        "data": 2.5,
        "valid": true
      },
      {
        "description": "both anyOf valid",
        "data": 3,
        "valid": true
      },
      {
        "description": "neither anyOf valid",
        "data": 1.5,
        "valid": false
      }
    ]
  },
  {
    "description": "anyOf with base schema",
    "schema": {
      "type": "string",
      "anyOf": [
        {
          "maxLength": 2
        },
        {
          "minLength": 4
        }
      ]
    },
    "tests": [
      {
        "description": "mismatch base schema",
        "data": 3,
        "valid": false
      },
      {
        "description": "one anyOf valid",
        "data": "foobar",
        "valid": true
      },
      {
        "description": "both anyOf invalid",
        "data": "foo",
        "valid": false
      }
    ]
  }
]}'));
  end;

  procedure test_default is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "invalid type for default",
    "schema": {
      "properties": {
        "foo": {
          "type": "integer",
          "default": []
        }
      }
    },
    "tests": [
      {
        "description": "valid when property is specified",
        "data": {
          "foo": 13
        },
        "valid": true
      },
      {
        "description": "still valid when the invalid default is used",
        "data": {},
        "valid": true
      }
    ]
  },
  {
    "description": "invalid string value for default",
    "schema": {
      "properties": {
        "bar": {
          "type": "string",
          "minLength": 4,
          "default": "bad"
        }
      }
    },
    "tests": [
      {
        "description": "valid when property is specified",
        "data": {
          "bar": "good"
        },
        "valid": true
      },
      {
        "description": "still valid when the invalid default is used",
        "data": {},
        "valid": true
      }
    ]
  }
]}'));
  end;

  procedure test_items is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "a schema given for items",
    "schema": {
      "items": {
        "type": "integer"
      }
    },
    "tests": [
      {
        "description": "valid items",
        "data": [
          1,
          2,
          3
        ],
        "valid": true
      },
      {
        "description": "wrong type of items",
        "data": [
          1,
          "x"
        ],
        "valid": false
      },
      {
        "description": "ignores non-arrays",
        "data": {
          "foo": "bar"
        },
        "valid": true
      }
    ]
  },
  {
    "description": "an array of schemas for items",
    "schema": {
      "items": [
        {
          "type": "integer"
        },
        {
          "type": "string"
        }
      ]
    },
    "tests": [
      {
        "description": "correct types",
        "data": [
          1,
          "foo"
        ],
        "valid": true
      },
      {
        "description": "wrong types",
        "data": [
          "foo",
          1
        ],
        "valid": false
      }
    ]
  }
]}'));
  end;

  procedure test_ref is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "root pointer ref",
    "schema": {
      "properties": {
        "foo": {
          "$ref": "#"
        }
      },
      "additionalProperties": false
    },
    "tests": [
      {
        "description": "match",
        "data": {
          "foo": false
        },
        "valid": true
      },
      {
        "description": "recursive match",
        "data": {
          "foo": {
            "foo": false
          }
        },
        "valid": true
      },
      {
        "description": "mismatch",
        "data": {
          "bar": false
        },
        "valid": false
      },
      {
        "description": "recursive mismatch",
        "data": {
          "foo": {
            "bar": false
          }
        },
        "valid": false
      }
    ]
  },
  {
    "description": "relative pointer ref to object",
    "schema": {
      "properties": {
        "foo": {
          "type": "integer"
        },
        "bar": {
          "$ref": "#/properties/foo"
        }
      }
    },
    "tests": [
      {
        "description": "match",
        "data": {
          "bar": 3
        },
        "valid": true
      },
      {
        "description": "mismatch",
        "data": {
          "bar": true
        },
        "valid": false
      }
    ]
  },
  {
    "description": "relative pointer ref to array",
    "schema": {
      "items": [
        {
          "type": "integer"
        },
        {
          "$ref": "#/items/0"
        }
      ]
    },
    "tests": [
      {
        "description": "match array",
        "data": [
          1,
          2
        ],
        "valid": true
      },
      {
        "description": "mismatch array",
        "data": [
          1,
          "foo"
        ],
        "valid": false
      }
    ]
  },
  {
    "description": "escaped pointer ref",
    "schema": {
      "tilda~field": {
        "type": "integer"
      },
      "slash/field": {
        "type": "integer"
      },
      "percent%field": {
        "type": "integer"
      },
      "properties": {
        "tilda": {
          "$ref": "#/tilda~0field"
        },
        "slash": {
          "$ref": "#/slash~1field"
        },
        "percent": {
          "$ref": "#/percent%25field"
        }
      }
    },
    "tests": [
      {
        "description": "slash invalid",
        "data": {
          "slash": "aoeu"
        },
        "valid": false
      },
      {
        "description": "tilda invalid",
        "data": {
          "tilda": "aoeu"
        },
        "valid": false
      },
      {
        "description": "percent invalid",
        "data": {
          "percent": "aoeu"
        },
        "valid": false
      },
      {
        "description": "slash valid",
        "data": {
          "slash": 123
        },
        "valid": true
      },
      {
        "description": "tilda valid",
        "data": {
          "tilda": 123
        },
        "valid": true
      },
      {
        "description": "percent valid",
        "data": {
          "percent": 123
        },
        "valid": true
      }
    ]
  },
  {
    "description": "nested refs",
    "schema": {
      "definitions": {
        "a": {
          "type": "integer"
        },
        "b": {
          "$ref": "#/definitions/a"
        },
        "c": {
          "$ref": "#/definitions/b"
        }
      },
      "$ref": "#/definitions/c"
    },
    "tests": [
      {
        "description": "nested ref valid",
        "data": 5,
        "valid": true
      },
      {
        "description": "nested ref invalid",
        "data": "a",
        "valid": false
      }
    ]
  }
]'));
/*,
  {
    "description": "remote ref, containing refs itself",
    "schema": {
      "$ref": "http://json-schema.org/draft-04/schema#"
    },
    "tests": [
      {
        "description": "remote ref valid",
        "data": {
          "minLength": 1
        },
        "valid": true
      },
      {
        "description": "remote ref invalid",
        "data": {
          "minLength": -1
        },
        "valid": false
      }
    ]
  }*/
  end;

  procedure test_required is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "required validation",
    "schema": {
      "properties": {
        "foo": {},
        "bar": {}
      },
      "required": [
        "foo"
      ]
    },
    "tests": [
      {
        "description": "present required property is valid",
        "data": {
          "foo": 1
        },
        "valid": true
      },
      {
        "description": "non-present required property is invalid",
        "data": {
          "bar": 1
        },
        "valid": false
      }
    ]
  },
  {
    "description": "required default validation",
    "schema": {
      "properties": {
        "foo": {}
      }
    },
    "tests": [
      {
        "description": "not required by default",
        "data": {},
        "valid": true
      }
    ]
  }
]}'));
  end;

  procedure test_type is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "integer type matches integers",
    "schema": {
      "type": "integer"
    },
    "tests": [
      {
        "description": "an integer is an integer",
        "data": 1,
        "valid": true
      },
      {
        "description": "a float is not an integer",
        "data": 1.1,
        "valid": false
      },
      {
        "description": "a string is not an integer",
        "data": "foo",
        "valid": false
      },
      {
        "description": "a string is still not an integer, even if it looks like one",
        "data": "1",
        "valid": false
      },
      {
        "description": "an object is not an integer",
        "data": {},
        "valid": false
      },
      {
        "description": "an array is not an integer",
        "data": [],
        "valid": false
      },
      {
        "description": "a boolean is not an integer",
        "data": true,
        "valid": false
      },
      {
        "description": "null is not an integer",
        "data": null,
        "valid": false
      }
    ]
  },
  {
    "description": "number type matches numbers",
    "schema": {
      "type": "number"
    },
    "tests": [
      {
        "description": "an integer is a number",
        "data": 1,
        "valid": true
      },
      {
        "description": "a float is a number",
        "data": 1.1,
        "valid": true
      },
      {
        "description": "a string is not a number",
        "data": "foo",
        "valid": false
      },
      {
        "description": "a string is still not a number, even if it looks like one",
        "data": "1",
        "valid": false
      },
      {
        "description": "an object is not a number",
        "data": {},
        "valid": false
      },
      {
        "description": "an array is not a number",
        "data": [],
        "valid": false
      },
      {
        "description": "a boolean is not a number",
        "data": true,
        "valid": false
      },
      {
        "description": "null is not a number",
        "data": null,
        "valid": false
      }
    ]
  },
  {
    "description": "string type matches strings",
    "schema": {
      "type": "string"
    },
    "tests": [
      {
        "description": "1 is not a string",
        "data": 1,
        "valid": false
      },
      {
        "description": "a float is not a string",
        "data": 1.1,
        "valid": false
      },
      {
        "description": "a string is a string",
        "data": "foo",
        "valid": true
      },
      {
        "description": "a string is still a string, even if it looks like a number",
        "data": "1",
        "valid": true
      },
      {
        "description": "an object is not a string",
        "data": {},
        "valid": false
      },
      {
        "description": "an array is not a string",
        "data": [],
        "valid": false
      },
      {
        "description": "a boolean is not a string",
        "data": true,
        "valid": false
      },
      {
        "description": "null is not a string",
        "data": null,
        "valid": false
      }
    ]
  },
  {
    "description": "object type matches objects",
    "schema": {
      "type": "object"
    },
    "tests": [
      {
        "description": "an integer is not an object",
        "data": 1,
        "valid": false
      },
      {
        "description": "a float is not an object",
        "data": 1.1,
        "valid": false
      },
      {
        "description": "a string is not an object",
        "data": "foo",
        "valid": false
      },
      {
        "description": "an object is an object",
        "data": {},
        "valid": true
      },
      {
        "description": "an array is not an object",
        "data": [],
        "valid": false
      },
      {
        "description": "a boolean is not an object",
        "data": true,
        "valid": false
      },
      {
        "description": "null is not an object",
        "data": null,
        "valid": false
      }
    ]
  },
  {
    "description": "array type matches arrays",
    "schema": {
      "type": "array"
    },
    "tests": [
      {
        "description": "an integer is not an array",
        "data": 1,
        "valid": false
      },
      {
        "description": "a float is not an array",
        "data": 1.1,
        "valid": false
      },
      {
        "description": "a string is not an array",
        "data": "foo",
        "valid": false
      },
      {
        "description": "an object is not an array",
        "data": {},
        "valid": false
      },
      {
        "description": "an array is an array",
        "data": [],
        "valid": true
      },
      {
        "description": "a boolean is not an array",
        "data": true,
        "valid": false
      },
      {
        "description": "null is not an array",
        "data": null,
        "valid": false
      }
    ]
  },
  {
    "description": "boolean type matches booleans",
    "schema": {
      "type": "boolean"
    },
    "tests": [
      {
        "description": "an integer is not a boolean",
        "data": 1,
        "valid": false
      },
      {
        "description": "a float is not a boolean",
        "data": 1.1,
        "valid": false
      },
      {
        "description": "a string is not a boolean",
        "data": "foo",
        "valid": false
      },
      {
        "description": "an object is not a boolean",
        "data": {},
        "valid": false
      },
      {
        "description": "an array is not a boolean",
        "data": [],
        "valid": false
      },
      {
        "description": "a boolean is a boolean",
        "data": true,
        "valid": true
      },
      {
        "description": "null is not a boolean",
        "data": null,
        "valid": false
      }
    ]
  },
  {
    "description": "null type matches only the null object",
    "schema": {
      "type": "null"
    },
    "tests": [
      {
        "description": "an integer is not null",
        "data": 1,
        "valid": false
      },
      {
        "description": "a float is not null",
        "data": 1.1,
        "valid": false
      },
      {
        "description": "a string is not null",
        "data": "foo",
        "valid": false
      },
      {
        "description": "an object is not null",
        "data": {},
        "valid": false
      },
      {
        "description": "an array is not null",
        "data": [],
        "valid": false
      },
      {
        "description": "a boolean is not null",
        "data": true,
        "valid": false
      },
      {
        "description": "null is null",
        "data": null,
        "valid": true
      }
    ]
  },
  {
    "description": "multiple types can be specified in an array",
    "schema": {
      "type": [
        "integer",
        "string"
      ]
    },
    "tests": [
      {
        "description": "an integer is valid",
        "data": 1,
        "valid": true
      },
      {
        "description": "a string is valid",
        "data": "foo",
        "valid": true
      },
      {
        "description": "a float is invalid",
        "data": 1.1,
        "valid": false
      },
      {
        "description": "an object is invalid",
        "data": {},
        "valid": false
      },
      {
        "description": "an array is invalid",
        "data": [],
        "valid": false
      },
      {
        "description": "a boolean is invalid",
        "data": true,
        "valid": false
      },
      {
        "description": "null is invalid",
        "data": null,
        "valid": false
      }
    ]
  }
]}'));
  end;

  procedure test_unique_items is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "uniqueItems validation",
    "schema": {
      "uniqueItems": true
    },
    "tests": [
      {
        "description": "unique array of integers is valid",
        "data": [
          1,
          2
        ],
        "valid": true
      },
      {
        "description": "non-unique array of integers is invalid",
        "data": [
          1,
          1
        ],
        "valid": false
      },
      {
        "description": "numbers are unique if mathematically unequal",
        "data": [
          1.0,
          1.00,
          1
        ],
        "valid": false
      },
      {
        "description": "unique array of objects is valid",
        "data": [
          {
            "foo": "bar"
          },
          {
            "foo": "baz"
          }
        ],
        "valid": true
      },
      {
        "description": "non-unique array of objects is invalid",
        "data": [
          {
            "foo": "bar"
          },
          {
            "foo": "bar"
          }
        ],
        "valid": false
      },
      {
        "description": "unique array of nested objects is valid",
        "data": [
          {
            "foo": {
              "bar": {
                "baz": true
              }
            }
          },
          {
            "foo": {
              "bar": {
                "baz": false
              }
            }
          }
        ],
        "valid": true
      },
      {
        "description": "non-unique array of nested objects is invalid",
        "data": [
          {
            "foo": {
              "bar": {
                "baz": true
              }
            }
          },
          {
            "foo": {
              "bar": {
                "baz": true
              }
            }
          }
        ],
        "valid": false
      },
      {
        "description": "unique array of arrays is valid",
        "data": [
          [
            "foo"
          ],
          [
            "bar"
          ]
        ],
        "valid": true
      },
      {
        "description": "non-unique array of arrays is invalid",
        "data": [
          [
            "foo"
          ],
          [
            "foo"
          ]
        ],
        "valid": false
      },
      {
        "description": "1 and true are unique",
        "data": [
          1,
          true
        ],
        "valid": true
      },
      {
        "description": "0 and false are unique",
        "data": [
          0,
          false
        ],
        "valid": true
      },
      {
        "description": "unique heterogeneous types are valid",
        "data": [
          {},
          [
            1
          ],
          true,
          null,
          1
        ],
        "valid": true
      },
      {
        "description": "non-unique heterogeneous types are invalid",
        "data": [
          {},
          [
            1
          ],
          true,
          null,
          {},
          1
        ],
        "valid": false
      }
    ]
  }
]}'));
  end;

end test_json_validator;
/
