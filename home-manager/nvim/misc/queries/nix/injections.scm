;; extends

(binding
  attrpath: (attrpath attr: (identifier) @_keymaps (#eq? @_keymaps "keymaps"))
  expression: (list_expression
    element: (attrset_expression
      (binding_set
        binding: (binding
          attrpath: (attrpath
            attr: (identifier) @_action (#eq? @_action "action"))
          expression: (string_expression
            (string_fragment) @injection.content))
        binding: (binding
          attrpath: (attrpath
            attr: (identifier) @_lua (#eq? @_lua "lua"))
          expression: (variable_expression
            name: (identifier) @_true (#eq? @_true "true"))))))
  (#set! injection.language "lua")
)
