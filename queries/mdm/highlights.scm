; MDM deployment scenario DSL (.mdm)

(comment) @comment @spell

(string) @string

(case_id) @label
(category_name) @type

(email) @string.special
(token_ref) @constant.builtin
(integer) @number
(bool) @boolean
(duration) @number
(script_name) @string.special
(header_name) @property
(domain) @string.special
(ident) @variable

(env_call) @function.builtin
(env_call "env" @function)

(config_block) @markup.heading
(case_block) @markup.heading

(config_block "config" @keyword)
(case_block "case" @keyword)
(category_line "category" @keyword)
(run_line "run" @keyword)
(expect_block "expect" @keyword)
(cleanup_block "cleanup" @keyword)

(config_backend "backend" @tag)
(config_device "device" @tag)
(config_mdm "mdm" @tag)
(backend_layer "backend" @tag)
(mdm_layer "mdm" @tag)
(device_layer "device" @tag)

(mdm_kind) @type.builtin

; backend steps
(backend_step "team" @keyword)
(backend_step "ensure" @keyword)
(backend_step "token" @keyword)
(backend_step "hmac" @keyword)
(backend_step "domains" @keyword)

; mdm steps
(mdm_step "set" @keyword)
(mdm_step "deploy" @keyword)
(mdm_step "wait" @keyword)
(mdm_step "with" @keyword)
(mdm_step "from" @keyword)
(mdm_step "within" @keyword)

; device steps
(device_step "ensure" @keyword)
(device_step "wait" @keyword)

; expect phrases
(expect_line "exit" @keyword)
(expect_line "stdout" @keyword)
(expect_line "stderr" @keyword)
(expect_line "contains" @keyword)
(expect_line "config" @keyword)
(expect_line "http" @keyword)
(expect_line "jit" @keyword)
(expect_line "user" @keyword)
(expect_line "created" @keyword)
(expect_line "enrollment" @keyword)
(expect_line "header" @keyword)

; cleanup
(cleanup_strategy) @keyword
(cleanup_line "backend" @tag)
(cleanup_line "device" @tag)
(cleanup_line "mdm" @tag)

"=" @operator
"[" @punctuation.bracket
"]" @punctuation.bracket
"{" @punctuation.bracket
"}" @punctuation.bracket
"(" @punctuation.bracket
")" @punctuation.bracket
"," @punctuation.delimiter
