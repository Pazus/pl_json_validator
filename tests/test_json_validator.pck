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
  
  --%test
  procedure test_difinitions;
  
  --%test
  procedure test_dependencies;
  
  --%test
  procedure test_enums;

  --%test(a schema given for items)
  procedure test_items;
  
  --%test
  procedure test_max_items;
  
  --%test
  procedure test_max_length;
  
  --%test
  procedure test_max_properties;
  
  --%test
  procedure test_maximum;
  
  --%test
  procedure test_min_items;
  
  --%test
  procedure test_min_length;
  
  --%test
  procedure test_min_properties;
  
  --%test
  procedure test_minimum;
  
  --%test
  procedure test_multiple_of;
  
  --%test
  procedure test_not;
  
  --%test
  procedure test_one_of;
  
  --%test
  procedure test_pattern;
  
  --%test
  procedure test_pattern_properties;
  
  --%test
  procedure test_properties;

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
  
  procedure test_difinitions is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "valid definition",
    "schema": {
      "$ref": "http://json-schema.org/draft-04/schema#"
    },
    "tests": [
      {
        "description": "valid definition schema",
        "data": {
          "definitions": {
            "foo": {
              "type": "integer"
            }
          }
        },
        "valid": true
      }
    ]
  },
  {
    "description": "invalid definition",
    "schema": {
      "$ref": "http://json-schema.org/draft-04/schema#"
    },
    "tests": [
      {
        "description": "invalid definition schema",
        "data": {
          "definitions": {
            "foo": {
              "type": 1
            }
          }
        },
        "valid": false
      }
    ]
  }
]}'));
  end;
  
  procedure test_dependencies is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "dependencies",
    "schema": {
      "dependencies": {
        "bar": [
          "foo"
        ]
      }
    },
    "tests": [
      {
        "description": "neither",
        "data": {},
        "valid": true
      },
      {
        "description": "nondependant",
        "data": {
          "foo": 1
        },
        "valid": true
      },
      {
        "description": "with dependency",
        "data": {
          "foo": 1,
          "bar": 2
        },
        "valid": true
      },
      {
        "description": "missing dependency",
        "data": {
          "bar": 2
        },
        "valid": false
      },
      {
        "description": "ignores non-objects",
        "data": "foo",
        "valid": true
      }
    ]
  },
  {
    "description": "multiple dependencies",
    "schema": {
      "dependencies": {
        "quux": [
          "foo",
          "bar"
        ]
      }
    },
    "tests": [
      {
        "description": "neither",
        "data": {},
        "valid": true
      },
      {
        "description": "nondependants",
        "data": {
          "foo": 1,
          "bar": 2
        },
        "valid": true
      },
      {
        "description": "with dependencies",
        "data": {
          "foo": 1,
          "bar": 2,
          "quux": 3
        },
        "valid": true
      },
      {
        "description": "missing dependency",
        "data": {
          "foo": 1,
          "quux": 2
        },
        "valid": false
      },
      {
        "description": "missing other dependency",
        "data": {
          "bar": 1,
          "quux": 2
        },
        "valid": false
      },
      {
        "description": "missing both dependencies",
        "data": {
          "quux": 1
        },
        "valid": false
      }
    ]
  },
  {
    "description": "multiple dependencies subschema",
    "schema": {
      "dependencies": {
        "bar": {
          "properties": {
            "foo": {
              "type": "integer"
            },
            "bar": {
              "type": "integer"
            }
          }
        }
      }
    },
    "tests": [
      {
        "description": "valid",
        "data": {
          "foo": 1,
          "bar": 2
        },
        "valid": true
      },
      {
        "description": "no dependency",
        "data": {
          "foo": "quux"
        },
        "valid": true
      },
      {
        "description": "wrong type",
        "data": {
          "foo": "quux",
          "bar": 2
        },
        "valid": false
      },
      {
        "description": "wrong type other",
        "data": {
          "foo": 2,
          "bar": "quux"
        },
        "valid": false
      },
      {
        "description": "wrong type both",
        "data": {
          "foo": "quux",
          "bar": "quux"
        },
        "valid": false
      }
    ]
  }
]}'));
  end;
  
  procedure test_enums is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "simple enum validation",
    "schema": {
      "enum": [
        1,
        2,
        3
      ]
    },
    "tests": [
      {
        "description": "one of the enum is valid",
        "data": 1,
        "valid": true
      },
      {
        "description": "something else is invalid",
        "data": 4,
        "valid": false
      }
    ]
  },
  {
    "description": "heterogeneous enum validation",
    "schema": {
      "enum": [
        6,
        "foo",
        [],
        true,
        {
          "foo": 12
        }
      ]
    },
    "tests": [
      {
        "description": "one of the enum is valid",
        "data": [],
        "valid": true
      },
      {
        "description": "something else is invalid",
        "data": null,
        "valid": false
      },
      {
        "description": "objects are deep compared",
        "data": {
          "foo": false
        },
        "valid": false
      }
    ]
  },
  {
    "description": "enums in properties",
    "schema": {
      "type": "object",
      "properties": {
        "foo": {
          "enum": [
            "foo"
          ]
        },
        "bar": {
          "enum": [
            "bar"
          ]
        }
      },
      "required": [
        "bar"
      ]
    },
    "tests": [
      {
        "description": "both properties are valid",
        "data": {
          "foo": "foo",
          "bar": "bar"
        },
        "valid": true
      },
      {
        "description": "missing optional property is valid",
        "data": {
          "bar": "bar"
        },
        "valid": true
      },
      {
        "description": "missing required property is invalid",
        "data": {
          "foo": "foo"
        },
        "valid": false
      },
      {
        "description": "missing all properties is invalid",
        "data": {},
        "valid": false
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
  
  procedure test_max_items is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "maxItems validation",
    "schema": {
      "maxItems": 2
    },
    "tests": [
      {
        "description": "shorter is valid",
        "data": [
          1
        ],
        "valid": true
      },
      {
        "description": "exact length is valid",
        "data": [
          1,
          2
        ],
        "valid": true
      },
      {
        "description": "too long is invalid",
        "data": [
          1,
          2,
          3
        ],
        "valid": false
      },
      {
        "description": "ignores non-arrays",
        "data": "foobar",
        "valid": true
      }
    ]
  }
]'));
  end;
  
  procedure test_max_length is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "maxLength validation",
    "schema": {
      "maxLength": 2
    },
    "tests": [
      {
        "description": "shorter is valid",
        "data": "f",
        "valid": true
      },
      {
        "description": "exact length is valid",
        "data": "fo",
        "valid": true
      },
      {
        "description": "too long is invalid",
        "data": "foo",
        "valid": false
      },
      {
        "description": "ignores non-strings",
        "data": 100,
        "valid": true
      },
      {
        "description": "two supplementary Unicode code points is long enough",
        "data": "\uD83D\uDCA9\uD83D\uDCA9",
        "valid": true
      }
    ]
  }
]'));
  end;

  procedure test_max_properties is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "maxProperties validation",
    "schema": {
      "maxProperties": 2
    },
    "tests": [
      {
        "description": "shorter is valid",
        "data": {
          "foo": 1
        },
        "valid": true
      },
      {
        "description": "exact length is valid",
        "data": {
          "foo": 1,
          "bar": 2
        },
        "valid": true
      },
      {
        "description": "too long is invalid",
        "data": {
          "foo": 1,
          "bar": 2,
          "baz": 3
        },
        "valid": false
      },
      {
        "description": "ignores non-objects",
        "data": "foobar",
        "valid": true
      }
    ]
  }
]'));
  end;
  
  procedure test_maximum is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "maximum validation",
    "schema": {
      "maximum": 3.0
    },
    "tests": [
      {
        "description": "below the maximum is valid",
        "data": 2.6,
        "valid": true
      },
      {
        "description": "above the maximum is invalid",
        "data": 3.5,
        "valid": false
      },
      {
        "description": "ignores non-numbers",
        "data": "x",
        "valid": true
      }
    ]
  },
  {
    "description": "exclusiveMaximum validation",
    "schema": {
      "maximum": 3.0,
      "exclusiveMaximum": true
    },
    "tests": [
      {
        "description": "below the maximum is still valid",
        "data": 2.2,
        "valid": true
      },
      {
        "description": "boundary point is invalid",
        "data": 3.0,
        "valid": false
      }
    ]
  }
]'));
  end;
  
  procedure test_min_items is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "minItems validation",
    "schema": {
      "minItems": 1
    },
    "tests": [
      {
        "description": "longer is valid",
        "data": [
          1,
          2
        ],
        "valid": true
      },
      {
        "description": "exact length is valid",
        "data": [
          1
        ],
        "valid": true
      },
      {
        "description": "too short is invalid",
        "data": [],
        "valid": false
      },
      {
        "description": "ignores non-arrays",
        "data": "",
        "valid": true
      }
    ]
  }
]'));
  end;
  
  procedure test_min_length is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "minLength validation",
    "schema": {
      "minLength": 2
    },
    "tests": [
      {
        "description": "longer is valid",
        "data": "foo",
        "valid": true
      },
      {
        "description": "exact length is valid",
        "data": "fo",
        "valid": true
      },
      {
        "description": "too short is invalid",
        "data": "f",
        "valid": false
      },
      {
        "description": "ignores non-strings",
        "data": 1,
        "valid": true
      },
      {
        "description": "one supplementary Unicode code point is not long enough",
        "data": "\uD83D\uDCA9",
        "valid": false
      }
    ]
  }
]'));
  end;
  
  procedure test_min_properties is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "minProperties validation",
    "schema": {
      "minProperties": 1
    },
    "tests": [
      {
        "description": "longer is valid",
        "data": {
          "foo": 1,
          "bar": 2
        },
        "valid": true
      },
      {
        "description": "exact length is valid",
        "data": {
          "foo": 1
        },
        "valid": true
      },
      {
        "description": "too short is invalid",
        "data": {},
        "valid": false
      },
      {
        "description": "ignores non-objects",
        "data": "",
        "valid": true
      }
    ]
  }
]'));
  end;
  


  procedure test_minimum is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "minimum validation",
    "schema": {
      "minimum": 1.1
    },
    "tests": [
      {
        "description": "above the minimum is valid",
        "data": 2.6,
        "valid": true
      },
      {
        "description": "below the minimum is invalid",
        "data": 0.6,
        "valid": false
      },
      {
        "description": "ignores non-numbers",
        "data": "x",
        "valid": true
      }
    ]
  },
  {
    "description": "exclusiveMinimum validation",
    "schema": {
      "minimum": 1.1,
      "exclusiveMinimum": true
    },
    "tests": [
      {
        "description": "above the minimum is still valid",
        "data": 1.2,
        "valid": true
      },
      {
        "description": "boundary point is invalid",
        "data": 1.1,
        "valid": false
      }
    ]
  }
]'));
  end;
  
  procedure test_multiple_of is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "by int",
    "schema": {
      "multipleOf": 2
    },
    "tests": [
      {
        "description": "int by int",
        "data": 10,
        "valid": true
      },
      {
        "description": "int by int fail",
        "data": 7,
        "valid": false
      },
      {
        "description": "ignores non-numbers",
        "data": "foo",
        "valid": true
      }
    ]
  },
  {
    "description": "by number",
    "schema": {
      "multipleOf": 1.5
    },
    "tests": [
      {
        "description": "zero is multiple of anything",
        "data": 0,
        "valid": true
      },
      {
        "description": "4.5 is multiple of 1.5",
        "data": 4.5,
        "valid": true
      },
      {
        "description": "35 is not multiple of 1.5",
        "data": 35,
        "valid": false
      }
    ]
  },
  {
    "description": "by small number",
    "schema": {
      "multipleOf": 0.0001
    },
    "tests": [
      {
        "description": "0.0075 is multiple of 0.0001",
        "data": 0.0075,
        "valid": true
      },
      {
        "description": "0.00751 is not multiple of 0.0001",
        "data": 0.00751,
        "valid": false
      }
    ]
  }
]'));
  end;
  
  procedure test_not is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "not",
    "schema": {
      "not": {
        "type": "integer"
      }
    },
    "tests": [
      {
        "description": "allowed",
        "data": "foo",
        "valid": true
      },
      {
        "description": "disallowed",
        "data": 1,
        "valid": false
      }
    ]
  },
  {
    "description": "not multiple types",
    "schema": {
      "not": {
        "type": [
          "integer",
          "boolean"
        ]
      }
    },
    "tests": [
      {
        "description": "valid",
        "data": "foo",
        "valid": true
      },
      {
        "description": "mismatch",
        "data": 1,
        "valid": false
      },
      {
        "description": "other mismatch",
        "data": true,
        "valid": false
      }
    ]
  },
  {
    "description": "not more complex schema",
    "schema": {
      "not": {
        "type": "object",
        "properties": {
          "foo": {
            "type": "string"
          }
        }
      }
    },
    "tests": [
      {
        "description": "match",
        "data": 1,
        "valid": true
      },
      {
        "description": "other match",
        "data": {
          "foo": 1
        },
        "valid": true
      },
      {
        "description": "mismatch",
        "data": {
          "foo": "bar"
        },
        "valid": false
      }
    ]
  },
  {
    "description": "forbidden property",
    "schema": {
      "properties": {
        "foo": {
          "not": {}
        }
      }
    },
    "tests": [
      {
        "description": "property present",
        "data": {
          "foo": 1,
          "bar": 2
        },
        "valid": false
      },
      {
        "description": "property absent",
        "data": {
          "bar": 1,
          "baz": 2
        },
        "valid": true
      }
    ]
  }
]'));
  end;
  
  procedure test_one_of is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "oneOf",
    "schema": {
      "oneOf": [
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
        "description": "first oneOf valid",
        "data": 1,
        "valid": true
      },
      {
        "description": "second oneOf valid",
        "data": 2.5,
        "valid": true
      },
      {
        "description": "both oneOf valid",
        "data": 3,
        "valid": false
      },
      {
        "description": "neither oneOf valid",
        "data": 1.5,
        "valid": false
      }
    ]
  },
  {
    "description": "oneOf with base schema",
    "schema": {
      "type": "string",
      "oneOf": [
        {
          "minLength": 2
        },
        {
          "maxLength": 4
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
        "description": "one oneOf valid",
        "data": "foobar",
        "valid": true
      },
      {
        "description": "both oneOf valid",
        "data": "foo",
        "valid": false
      }
    ]
  }
]'));
  end;
  
  procedure test_pattern is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "pattern validation",
    "schema": {
      "pattern": "^a*$"
    },
    "tests": [
      {
        "description": "a matching pattern is valid",
        "data": "aaa",
        "valid": true
      },
      {
        "description": "a non-matching pattern is invalid",
        "data": "abc",
        "valid": false
      },
      {
        "description": "ignores non-strings",
        "data": true,
        "valid": true
      }
    ]
  },
  {
    "description": "pattern is not anchored",
    "schema": {
      "pattern": "a+"
    },
    "tests": [
      {
        "description": "matches a substring",
        "data": "xxaayy",
        "valid": true
      }
    ]
  }
]'));
  end;
  
  procedure test_pattern_properties is
  begin
    validate_test_set(json_array_t.parse('[
  {
    "description": "patternProperties validates properties matching a regex",
    "schema": {
      "patternProperties": {
        "f.*o": {
          "type": "integer"
        }
      }
    },
    "tests": [
      {
        "description": "a single valid match is valid",
        "data": {
          "foo": 1
        },
        "valid": true
      },
      {
        "description": "multiple valid matches is valid",
        "data": {
          "foo": 1,
          "foooooo": 2
        },
        "valid": true
      },
      {
        "description": "a single invalid match is invalid",
        "data": {
          "foo": "bar",
          "fooooo": 2
        },
        "valid": false
      },
      {
        "description": "multiple invalid matches is invalid",
        "data": {
          "foo": "bar",
          "foooooo": "baz"
        },
        "valid": false
      },
      {
        "description": "ignores non-objects",
        "data": 12,
        "valid": true
      }
    ]
  },
  {
    "description": "multiple simultaneous patternProperties are validated",
    "schema": {
      "patternProperties": {
        "a*": {
          "type": "integer"
        },
        "aaa*": {
          "maximum": 20
        }
      }
    },
    "tests": [
      {
        "description": "a single valid match is valid",
        "data": {
          "a": 21
        },
        "valid": true
      },
      {
        "description": "a simultaneous match is valid",
        "data": {
          "aaaa": 18
        },
        "valid": true
      },
      {
        "description": "multiple matches is valid",
        "data": {
          "a": 21,
          "aaaa": 18
        },
        "valid": true
      },
      {
        "description": "an invalid due to one is invalid",
        "data": {
          "a": "bar"
        },
        "valid": false
      },
      {
        "description": "an invalid due to the other is invalid",
        "data": {
          "aaaa": 31
        },
        "valid": false
      },
      {
        "description": "an invalid due to both is invalid",
        "data": {
          "aaa": "foo",
          "aaaa": 31
        },
        "valid": false
      }
    ]
  },
  {
    "description": "regexes are not anchored by default and are case sensitive",
    "schema": {
      "patternProperties": {
        "[0-9]{2,}": {
          "type": "boolean"
        },
        "X_": {
          "type": "string"
        }
      }
    },
    "tests": [
      {
        "description": "non recognized members are ignored",
        "data": {
          "answer 1": "42"
        },
        "valid": true
      },
      {
        "description": "recognized members are accounted for",
        "data": {
          "a31b": null
        },
        "valid": false
      },
      {
        "description": "regexes are case sensitive",
        "data": {
          "a_x_3": 3
        },
        "valid": true
      },
      {
        "description": "regexes are case sensitive, 2",
        "data": {
          "a_X_3": 3
        },
        "valid": false
      }
    ]
  }
]'));
  end;
  
  procedure test_properties is
  begin
    validate_test_set(json_array_t.parse(q'{[
  {
    "description": "object properties validation",
    "schema": {
      "properties": {
        "foo": {
          "type": "integer"
        },
        "bar": {
          "type": "string"
        }
      }
    },
    "tests": [
      {
        "description": "both properties present and valid is valid",
        "data": {
          "foo": 1,
          "bar": "baz"
        },
        "valid": true
      },
      {
        "description": "one property invalid is invalid",
        "data": {
          "foo": 1,
          "bar": {}
        },
        "valid": false
      },
      {
        "description": "both properties invalid is invalid",
        "data": {
          "foo": [],
          "bar": {}
        },
        "valid": false
      },
      {
        "description": "doesn't invalidate other properties",
        "data": {
          "quux": []
        },
        "valid": true
      },
      {
        "description": "ignores non-objects",
        "data": [],
        "valid": true
      }
    ]
  },
  {
    "description": "properties, patternProperties, additionalProperties interaction",
    "schema": {
      "properties": {
        "foo": {
          "type": "array",
          "maxItems": 3
        },
        "bar": {
          "type": "array"
        }
      },
      "patternProperties": {
        "f.o": {
          "minItems": 2
        }
      },
      "additionalProperties": {
        "type": "integer"
      }
    },
    "tests": [
      {
        "description": "property validates property",
        "data": {
          "foo": [
            1,
            2
          ]
        },
        "valid": true
      },
      {
        "description": "property invalidates property",
        "data": {
          "foo": [
            1,
            2,
            3,
            4
          ]
        },
        "valid": false
      },
      {
        "description": "patternProperty invalidates property",
        "data": {
          "foo": []
        },
        "valid": false
      },
      {
        "description": "patternProperty validates nonproperty",
        "data": {
          "fxo": [
            1,
            2
          ]
        },
        "valid": true
      },
      {
        "description": "patternProperty invalidates nonproperty",
        "data": {
          "fxo": []
        },
        "valid": false
      },
      {
        "description": "additionalProperty ignores property",
        "data": {
          "bar": []
        },
        "valid": true
      },
      {
        "description": "additionalProperty validates others",
        "data": {
          "quux": 3
        },
        "valid": true
      },
      {
        "description": "additionalProperty invalidates others",
        "data": {
          "quux": "foo"
        },
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
